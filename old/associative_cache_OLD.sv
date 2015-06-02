`protect // associativity 
module associative_cache #(parameter SIZE=128, ADDR_LENGTH=10, CACHE_DELAY=10, BLOCK_SIZE=32, RETURN_SIZE=8, ASSOCIATIVITY=4, WRITE_MODE=2'b10)
					  (data_out, fetchComplete, miss, addr_in, data_in, fetchReceive,
						enable, write, wb_enable_out, wb_addr_out, wb_enable_in, wb_addr_in, wb_data_out, reset, clk);
	parameter [1:0] WRITE_AROUND = 2'b00, WRITE_THROUGH = 2'b01, WRITE_BACK = 2'b10;
	
	parameter COUNTER_SIZE = $clog2(CACHE_DELAY);
	
	parameter BYTE_SELECT_SIZE = $clog2(BLOCK_SIZE/8);
	parameter INDEX_SIZE = $clog2(SIZE/BLOCK_SIZE);
	parameter TAG_SIZE = ADDR_LENGTH - BYTE_SELECT_SIZE - INDEX_SIZE;
	
	output reg [(RETURN_SIZE-1):0] data_out;
	output reg fetchComplete, miss = 0;
	
	input [(ADDR_LENGTH-1):0] addr_in;
	input [(BLOCK_SIZE-1):0] data_in;
	input fetchReceive, enable, write, reset, clk;
	
	// WRITE BACK I/O
	input [(ADDR_LENGTH-1):0] wb_addr_in;
	input wb_enable_in;
	output reg [(ADDR_LENGTH-1):0] wb_addr_out;
	output reg wb_enable_out;
	output reg [(BLOCK_SIZE)wb_data_out;
	
	wire [BYTE_SELECT_SIZE-1:0] 	byteSelect 	= addr_in[(BYTE_SELECT_SIZE-1):0];
	wire [INDEX_SIZE-1:0]			cacheIndex 	= addr_in[(BYTE_SELECT_SIZE+INDEX_SIZE-1):(BYTE_SELECT_SIZE)];
	wire [TAG_SIZE-1:0]				tag 			= addr_in[(ADDR_LENGTH-1):(BYTE_SELECT_SIZE+INDEX_SIZE)];
	
	wire [BYTE_SELECT_SIZE-1:0] 	wb_byteSelect 		= wb_addr_in[(BYTE_SELECT_SIZE-1):0];
	wire [INDEX_SIZE-1:0]			wb_cacheIndex 		= wb_addr_in[(BYTE_SELECT_SIZE+INDEX_SIZE-1):(BYTE_SELECT_SIZE)];
	wire [TAG_SIZE-1:0]				wb_tag 				= wb_addr_in[(ADDR_LENGTH-1):(BYTE_SELECT_SIZE+INDEX_SIZE)];

	// CACHE CONTENTS
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(BLOCK_SIZE-1):0]  data;
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(TAG_SIZE-1):0] 	 tags;
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0]							 valid_bits;
	
	//
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] 							 dirty_bits;
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(ADDR_LENGTH-1):0] dirty_addr;
	
	// various counters and flags
	reg [COUNTER_SIZE-1:0] counter;
	reg start_counter = 0;
	reg LRUread = 0;
	reg write_trigger = 0;
	reg writeComplete = 0;
	reg waitingForLower = 0;
	parameter NUM_ASSO_BITS = $clog2(ASSOCIATIVITY);
	reg [(NUM_ASSO_BITS-1):0] asso_index = 0;
	wire [(NUM_ASSO_BITS-1):0] LRUoutput;
	
	// instantiate LRU module
	lru #(.INDEX_SIZE(SIZE/BLOCK_SIZE), .ASSOCIATIVITY(ASSOCIATIVITY)) LRU
		  (cacheIndex, asso_index, LRUoutput, write_trigger, LRUread, reset, clk);
	
	
	always @(*) begin
		if (wb_enable_in) begin
			for (int j=0; j<ASSOCIATIVITY; j++) begin
				if(tags[wb_cacheIndex][j] == tag && valid_bits[wb_cacheIndex][j] == 1) begin
					data[wb_cacheIndex][j] = data_in;
					break;	end
			end
		end
	
		if (~enable) begin
			data_out = 'x;
			fetchComplete = 0;
			LRUread = 0;
			write_trigger = 0;
			writeComplete = 0;
			waitingForLower = 0;
			wb_enable_out = 0;
			counter = 0;
			miss = 0;
		end
		else if (waitingForLower) begin	// retrieved data from lower cache, write data to cache now
			if (fetchReceive) begin
				write_trigger = 1;
				data_out = data_in;
				valid_bits[cacheIndex][LRUoutput] = 1;
				tags[cacheIndex][LRUoutput] = tag;
				data[cacheIndex][LRUoutput] = data_in;
				// check dirty bits for write-back functionality
				if (dirty_bits[cacheIndex][LRUoutput] == 1) begin
					wb_addr_out = dirty_addr[cacheIndex][LRUoutput];
					wb_enable_out = 1;
				end
				fetchComplete = 1;
			end
		end
		// check if data here after timer elapses
		else if (~write) begin
			start_counter = 1;
			if (counter >= CACHE_DELAY) begin
				start_counter = 0;
				for (int j=0; j<ASSOCIATIVITY; j++) begin
					// data here
					if(tags[cacheIndex][j] == tag && valid_bits[cacheIndex][j] == 1) begin
						asso_index = j;
						LRUread = 1;
						data_out = data[cacheIndex][j][((byteSelect+1)*RETURN_SIZE-1) -: RETURN_SIZE];
						fetchComplete = 1;
						break;	
					end
					// data not here
					else if (j == (ASSOCIATIVITY - 1)) begin
						miss = 1;
						waitingForLower = 1;
					end
				end
			end
		end
		// write
		else begin
			if (WRITE_MODE == WRITE_AROUND) begin
				miss = 1;
				for (int j=0; j<ASSOCIATIVITY; j++) begin
					if(tags[cacheIndex][j] == tag && valid_bits[cacheIndex][j] == 1) begin
						valid_bits[cacheIndex][j] = 0;
						writeComplete = 1;
						break;	end
				end
			end
			else if (WRITE_MODE == WRITE_THROUGH) begin
				miss = 1;
				for (int j=0; j<ASSOCIATIVITY; j++) begin
					if(tags[cacheIndex][j] == tag && valid_bits[cacheIndex][j] == 1) begin
						// update copy NEEDS WORK
						data[cacheIndex][j] = data_in;
						writeComplete = 1;
						break;	end
				end
			end
			else begin	// WRITE_BACK
				for (int j=0; j<ASSOCIATIVITY; j++) begin
					if(tags[cacheIndex][j] == tag && valid_bits[cacheIndex][j] == 1) begin
						// update copy NEEDS WORK
						dirty_bits[cacheIndex][j] = 1'b1;
						dirty_addr[cacheIndex][j] = addr_in;
						data[cacheIndex][j] = data_in;
						writeComplete = 1;
						break;	end
					else begin	// Try writing to lower cache if data not present here
						miss = 1;
					end
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if (start_counter) begin
			counter <= counter + 1;
		end
	end
endmodule
`endprotect

module associative_cache_testbench();
	wire [7:0] data_out, dontCare; // always 1 byte
	wire fetchCompleteL1, fetchCompleteL2, missL1, missL2;
	
	reg [9:0] addr_in;
	reg [31:0] data_inL1, data_inL2, data_inMem, data_outL2, data_outMem;
	reg fetchReceiveL1, fetchReceiveL2, enable, write, reset, clk;
	
	wire wb_enable_outL1, wb_enable_outL2;
	wire wb_enable_inL1, wb_enable_inL2;
	wire [9:0] wb_addr_outL1, wb_addr_outL2, wb_addr_inL1, wb_addr_inL2;
	
	assign wb_enable_outL1 = wb_enable_inL2;
	assign wb_addr_outL1 = wb_addr_inL2;
	assign wb_enable_inL1 = 1'b0;
	assign wb_addr_inL1 = 10'b0;
	
	parameter t = 10;
	parameter d = 20;
	
	reg [31:0] userData = 32'hFFFFFFFF;
	
	always @(*) begin
		if (wb_enable_outL1) begin
			data_inL2 = 
		end
		if (write) begin
			data_inL1 = userData;
			data_inL2 = userData;
			data_inMem = userData;
		end
		else begin
			data_inL1 = data_outL2;
			data_inL2 = data_outMem;
			data_inMem = 0;
		end
	end

	// (data_out, fetchComplete, miss, addr_in, data_in, fetchReceive, enable, write, reset, clk)
	associative_cache	L1 (data_out, fetchCompleteL1, missL1, addr_in, data_inL1, fetchReceiveL1, enable, write,
								 wb_enable_outL1, wb_addr_outL1, wb_enable_inL1, wb_addr_inL1, reset, clk);
	associative_cache	#(.SIZE(256), .RETURN_SIZE(32))
				L2 (data_outL2, fetchReceiveL1, missL2, addr_in, data_inL2, fetchReceiveL2, missL1, write,
					 wb_enable_outL2, wb_addr_outL2, wb_enable_inL2, wb_addr_inL2, reset, clk);
	
	mainMem	#(.BLOCK_SIZE(32))
				memory (.data_out(data_outMem), .fetchComplete(fetchReceiveL2), .data_in(data_inMem), .addr(addr_in), .write(write), .enable(missL2), .clk);
	
	
	always #(t/2) clk = ~clk;
		
	integer i = 0;
	initial begin
		clk <= 0;
		enable <= 0;
		reset <= 1'b1;			@(posedge clk);
		reset <= 1'b0;			@(posedge clk);
		write <= 0;				@(posedge clk);
		
		
		// WRITE AROUND TEST
		addr_in = 0;			@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
		
		write <= 1;				@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
		
		write <= 0;				@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
		
		addr_in = 4;			@(posedge clk);
		write <= 0;				@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
		
		write <= 1;				@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
		
		write <= 0;				@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;

		/* WRITE THROUGH TESTS
		addr_in = 0;			@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
		
		write <= 1;				@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
		
		write <= 0;				@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
		
		*/
		//	READ TESTS
		// fill up both caches
		for (i=0; i<128; i++) begin
			addr_in <= i;		@(posedge clk);
			enable <= 1;		@(posedge clk);
			#(100*t);
			enable <= 0;		@(posedge clk);
			#t;
		end
		
		addr_in <= 32;			@(posedge clk);
		enable <= 1;			@(posedge clk);
		#(100*t);
		enable <= 0;			@(posedge clk);
		#t;
			
		// access an element that is in L2 but had capacity overflow in L1
		addr_in = 4;		@(posedge clk);
		enable <= 1;		@(posedge clk);
		enable <= 0;		@(posedge clk);
		#(100*t);
		
		// repeat same access to see if value is now stored in L1
		addr_in = 4;		@(posedge clk);
		enable <= 1;		@(posedge clk);
		enable <= 0;		@(posedge clk);

		#(100*t);
		$stop;
		
	end
endmodule 