`protect
/* This is the least recently used module. This keeps track of the order in
   which a cache was accessed, and returns which location was the least 
   recently used. This module is contained in each cache module.
   
   The index, should simply be parsed from the input address to the cache and
   passed into this module. The asso_index is only used for reads and should be
   equal to the associative index that matches the appropriate parsed tag from
   the input address. The write trigger should be activated when data has been
   fetched and is being updated (written) to the cache. The read trigger should
   be activated when data is being read from the cache. Both triggers should be
   off in between reads and writes (when the cache is no-longer enabled) to
   prepare lru for another trigger.
   
    PARAMETERS:
        INDEX_SIZE: the number of cache indices
		ASSOCIATIVITY: cache associativity
		RANDOM: will the cache have random replacement
			(1 = random replacement, 0 = least recently used replacement)
	
	I/O:
		index: cache index being written to or read from
		asso_index: associative index being written to or read from
		select: output of which associativity index was least recently used for
		    the given cache index
			NOTE: In the lru, the usage is tracked in registers called mem
				where for each cache index the registers representing each
				associativity spot are each given a number from 0 to the
				associativity - 1. The least recently used spot would have the
				value of 0 and the most recently spot would have the value of
				associativity - 1.
		write_trigger: trigger to let the lru know that the cache has preformed
			a write (occurs when fetching data), updates the lru
		read_trigger: trigger to let the lru know that the cache has preformed
			a read, updates the lru
		reset: resets the lru (when the cache is reset)
 */

module lru #(parameter INDEX_SIZE = 4, ASSOCIATIVITY = 1, RANDOM = 0)
	(index, asso_index, select, write_trigger, read_trigger, reset);
	
	/* number of bits needed to track all associativity spots */
	parameter COUNT_SIZE = $clog2(ASSOCIATIVITY);
	
	/* number of bits needed to track all index spots */
	parameter NUM_INDICES = $clog2(INDEX_SIZE);
	
	/* I/O */
	output reg [(COUNT_SIZE-1):0] select;
	
	input [(NUM_INDICES-1):0] index;
	input [(COUNT_SIZE-1):0] asso_index;
	
	input write_trigger, read_trigger, reset;
	
	
	/* registers that hold information about each location and when it was used
	   NOTE: The value of the register is 0 if that spot is the most recently
	   used. */
	reg [(INDEX_SIZE-1):0][(ASSOCIATIVITY-1):0][(COUNT_SIZE-1):0] mem;
	
	/* registers that hold the value of a specific cache index and associative
	   index spot for comparison to preform the update for a read trigger */
	reg [(COUNT_SIZE-1):0] v;
	
	/* flags used to make sure the update is only preformed once per trigger */
	reg reading, writing;
	
	/* This is to track if a cache index is "full", meaning that all the
	   associativity locations for that cache index have been used. If a cache
	   index is, then if random replacement is selected, the replacement
	   associativity location returned will be random. */
	reg [(INDEX_SIZE-1):0] full;
	
	/* Cache associativity locations are initially numbered, so that the order
	   of the locations usage can be tracked. */
	integer i, j;
	initial begin
		for(i = 0; i < INDEX_SIZE; i++) begin
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				mem[i][j] = j;
			end
		end
	end
	
	/* integer that will be randomly generated every trigger */
	int r = 0;
	
	always @(*) begin
		
		/* Reset LRU mem back to initialized values */
		if(reset) begin
			for(i = 0; i < INDEX_SIZE; i++) begin
				for(j = 0; j < ASSOCIATIVITY; j++)begin
					mem[i][j] = j;
				end
			end
		end
		
		/* something something latches */
		select = select;
		mem = mem;
		v = v;
		reading = reading;
		writing = writing;
		full = full;
		
		/* If random selection is selected and each cache index will have a
		   random associativity index returned as select when that cache index
		   has been filled. */
		if(full[index] && RANDOM)
			select = r;
		else
		/* If the cache index is not full or random selection is not selected,
		   look through mem and return which associativity index has the value
		   of 0 and is therefore least recently used. */
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				if(mem[index][j] == 0) begin
					select = j;
				end
			end
		
		/* reset cache contents and flags on reset */
		if (reset) begin
			for(i = 0; i < INDEX_SIZE; i++) begin
				for(j = 0; j < ASSOCIATIVITY; j++)begin
					mem[i][j] = j;
				end
				full[i] = 0;
			end
			reading = 0;
			writing = 0;
		end
		
		/* When receiving the write trigger, drop the least recently used count
		   in each associativity index for the selected cache index. This works
		   (when not in random select mode) because the write is preformed at
		   the location that was least recently used and thus had a value of 0.
		   The value of 0 in the least recently used location will wrap around
		   and become large, so it will be further reduced as needed. The value
		   of 1 becomes 0, 2 becomes 1, and so on. */
		if (write_trigger & ~writing & ~reset) begin
			writing = 1;
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				mem[index][j] -= 1'b1;
				if(mem[index][j] >= ASSOCIATIVITY) begin
					mem[index][j] <= ASSOCIATIVITY-1;
				end
			end
		end
		
		/* When receiving the read trigger, find the location that matches the
           asso. index being read from and decrement every associativity index
		   (for the selected cache index) that has a value larger then the
		   asso. index being read from. Now set the asso. index being read from
		   to the maximum value so that it is in mem as the most recently read
		   location. */
		if (read_trigger & ~reading & ~reset) begin
			reading = 1;
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				if(j == asso_index) begin
					v = mem[index][j];
				end
			end
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				if(mem[index][j] > v ) begin
					mem[index][j] = mem[index][j] - 1'b1;
				end
				else if(mem[index][j] == v) begin
					mem[index][j] = ASSOCIATIVITY - 1;
				end
			end
		end
		
		/* The reading and writing flags are to protect against multiple
		   updates for a single trigger. The triggers have to both be off to
		   reset these flags. */
		if (~read_trigger & ~write_trigger) begin
			reading = 0;
			writing = 0;
		end
		
		/* If the module is outputting (as select) the value which is the
		   cache's associativity - 1, the last associativity value for a select
		   cache index, then every other associativity value must have been
		   returned prior and that asso. index. If the last location is
		   returned then that cache index's associativity locations are full
		   and the cache get the go-ahead to start random replacement for that
		   cache index. */
		if(select >= ASSOCIATIVITY - 1 && !full[index])
			full[index] = 1;
	end
	
	/* Every time the lru receives a trigger, generate a new random value which
       will be used for random replacement. */
	always @(posedge read_trigger || write_trigger) begin
		r = $random;
	end
endmodule
`endprotect

module lru_testbench();
	parameter INDEX_SIZE = 3;
	parameter ASSOCIATIVITY = 4;
	parameter RANDOM = 1;
	
	parameter COUNT_SIZE = $clog2(ASSOCIATIVITY);
	parameter NUM_INDICES = $clog2(INDEX_SIZE);
	
	wire [(COUNT_SIZE-1):0] select;
	
	reg [(NUM_INDICES-1):0] index;
	reg [(COUNT_SIZE-1):0] asso_index;
	
	reg write_trigger, read_trigger, reset;

	lru #(.INDEX_SIZE(INDEX_SIZE), .ASSOCIATIVITY(ASSOCIATIVITY), .RANDOM(RANDOM)) test
	(.index, .asso_index, .select, .write_trigger, .read_trigger, .reset);
	
	integer i;
	initial begin
		write_trigger <= 1'b0; read_trigger <= 1'b0; index = 1'b0; reset = 1'b0; #10;
		write_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; #10;
		write_trigger <= 1'b1; #10;
		asso_index = 3'b101;   read_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; read_trigger <= 1'b0; #10;
		write_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; #10;
		write_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; #10;
		write_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; #10;
		write_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; #10;
		write_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; #10;
		write_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; #10;
		reset = 1'b1; #10;
		reset = 1'b0; #10;
		 #10; #10; #10; #10; #10;
	end
endmodule
