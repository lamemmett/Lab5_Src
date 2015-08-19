/* This is the cache module. It models a variable size and associativity cache
   with variable delay. This module will be used to simulate each cache level.
   
	User                        L1                            Main
	          +-----------------------------------+   +------------------
	-->	   -->| addrIn                    addrOut |-->| addrIn           
	<--	   <--| dataUpOut              dataDownIn |<--| dataUpOut        
    -->	   -->| dataUpIn              dataDownOut |-->| dataUpIn         
	<--	   <--| fetchComplete        fetchReceive |<--| fetchComplete    
	-->	   -->| enableIn                enableOut |-->| enableIn         
	<--	   <--| writeCompleteOut  writeCompleteIn |<--| writeCompleteOut 
	-->	   -->| writeIn                  writeOut |-->| writeIn          
			  +-----------------------------------+   +------------------
    
    PARAMETERS: 
        INDEX_SIZE: determines the number of cache indices
        ADDR_LENGTH: number of bits required to address memory
			*REQUIREMENTS:
				ADDR_LENGTH must be great enough to address all of the bits in
				main memory, main memory should be larger then every cache
				above it
        CACHE_DELAY: delay experienced when accessing cache
        BLOCK_SIZE: number of bits in an individual block in the cache
			*REQUIREMENTS:
			    BLOCK_SIZE can not be the same as the RETURN_SIZE, it must be
				larger by a factor of 2
	    RETURN_SIZE: number of bits returned to the higher cache, or user
		    *REQUIREMENTS:
				RETURN_SIZE can not be the same as the BLOCK_SIZE, it must be
				smaller by a factor of 2
        ASSOCIATIVITY: cache associativity
		    *NOTE:
				to generate a direct mapped cache, have an ASSOCIATIVITY of 10
				to generate a fully associative cache, have an ASSOCIATIVITY
				such that the INDEX_SIZE is just 1
	    WRITE_MODE:
            WRITE_AROUND: when preforming a write, simply invalidate the spot
				and pass data down
		    WRITE_THROUGH: when preforming a write, write data to cache and
				pass data down
		    WRITE_BACK: when preforming a write, write data to cache and mark
				the spot using a "dirty bit"; when attempting to read data,
				pass the data down
		      
	Upward I/O:
        addrIn: address selected for cache operation
		dataUpOut: data output to the cache above
		dataUpIn: data input from the cache above
		fetchComplete: signal that outputs when a fetch operation finishes
            (1 = fetch finished)
		enableIn: signal that starts the cache
			(1 = enabled, else disabled)
		writeCompleteOut: signal that outputs when a write operation finishes
		    (1 = write finished)
		writeIn: signal that determines whether the cache is writing or reading
		    (1 = write, else read)
		
	Downward I/O:
		addrOut: address output down to the lower cache
		dataDownIn: data received from lower cache
		dataDownOut: data passed down to the lower cache
		fetchReceive: signal received indicating that lower cache has fetched
			(1 = fetch received)
		enableOut: signal that starts the lower cache
			(1 = enabled, else disabled)
		writeCompleteIn: signal received indicating that lower cache has 
			finished writing
		    (1 = lower write finished)
	    writeOut: signal that determines whether the lower cache is writing or
		    reading
		    (1 = write, else read)
			
	General I/O:
	    clock: system clock
		reset: resets cache system (1 = reset)
 */
`protect
module cache #(parameter INDEX_SIZE=1, ADDR_LENGTH=10, CACHE_DELAY=10, 
	BLOCK_SIZE=128, RETURN_SIZE=32, ASSOCIATIVITY=2, WRITE_MODE=2'b10)
	(addrIn, 	dataUpOut, 	dataUpIn, 		fetchComplete, enableIn, 	writeCompleteOut,   writeIn,
	 addrOut,	dataDownIn,	dataDownOut,	fetchReceive,	enableOut,	writeCompleteIn,	writeOut,
	 clock,     reset);
	
	/* types of write systems */
	parameter [1:0] WRITE_AROUND = 2'b00, 
					WRITE_THROUGH = 2'b01, 
					WRITE_BACK = 2'b10;
	
	/* size of the counter used to count to delay */
	parameter COUNTER_SIZE = $clog2(CACHE_DELAY);
	
	/* number of bits needed to address each "word" in cache; not actually
	   selecting words because the cache's blocks are instead divided into
	   returnable chunks. For example if block size is 256 and return size is
	   64, the cache will be divided into 4 blocks and have a WORD_SELECT_SIZE
	   of 2. */
	parameter WORD_SELECT_SIZE = $clog2(BLOCK_SIZE/RETURN_SIZE);
	
	/* number of bits needed to address the cache's entire index */
	parameter INDEX_SELECT_SIZE = $clog2(INDEX_SIZE);
	
	/* leftover bits in the address become the tag */
	parameter TAG_SIZE = ADDR_LENGTH - $clog2(BLOCK_SIZE/32) - INDEX_SELECT_SIZE;
	
	/* number of bits needed to index all associativities */
	parameter NUM_ASSO_BITS = $clog2(ASSOCIATIVITY);
	
	/* General I/O */
	input clock, reset;
	
	/* Upward I/O */
	input 		[(ADDR_LENGTH-1):0] 	addrIn;
	output reg 	[(RETURN_SIZE-1):0] 	dataUpOut;
	input 		[(RETURN_SIZE-1):0] 	dataUpIn;
	output reg							fetchComplete;
	input 								enableIn;
	output reg							writeCompleteOut;
	input								writeIn;
	
	/* Downward I/O */
	output reg 	[(ADDR_LENGTH-1):0] 	addrOut;
	input			[(BLOCK_SIZE-1):0]	dataDownIn;
	output reg	[(BLOCK_SIZE-1):0]	dataDownOut;
	input									fetchReceive;
	output reg								enableOut;
	input 									writeCompleteIn;
	output reg								writeOut;
	
	/* address is broken down into its pieces (tag, cacheIndex, wordSelect)
		NOTE: The preCacheIndex is a "work around" to allow for an index size
		of 1 (a fully associative cache). This is required because when
		creating the wire if the parameter INDEX_SIZE is 1, INDEX_SELECT_SIZE
		is calculated to be 0. This creates a strange wire of size 2 where the
		dimensions are from -1 to 0 and everything is flipped. A 1 is turned
		into a 2 (01 --> 10), not sure why. So when the INDEX_SELECT_SIZE is 0,
		the default cache index of 0 is used.
	 */
	wire [WORD_SELECT_SIZE-1:0]	wordSelect 	= addrIn[(ADDR_LENGTH - 1 - TAG_SIZE - INDEX_SELECT_SIZE) -: WORD_SELECT_SIZE];
	wire [INDEX_SELECT_SIZE-1:0]			preCacheIndex 	= addrIn[(ADDR_LENGTH - 1 - TAG_SIZE) -: INDEX_SELECT_SIZE];
	wire [TAG_SIZE-1:0]				tag 			= addrIn[(ADDR_LENGTH-1) -: TAG_SIZE];
	reg  [INDEX_SELECT_SIZE-1:0]		cacheIndex;
	
	/* CACHE CONTENTS 
	    
		data: registers where data is stored
		tags: registers where tag is stored, used to identify data
		validBits: registers used to ensure the validity of data
			(1 = valid)
		dirtyBits: registers used in WRITE_BACK to keep track of which spots in
			data are waiting to be passed down and written in other caches
			(1 = waiting)
	 */
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(BLOCK_SIZE-1):0] data;
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(TAG_SIZE-1):0] 	tags;
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0]					validBits;
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] 					dirtyBits;
	
	/* Counters and Flags 
		
		counter: counter which counts the cache delay
		startCounter: flag that indicates whether to startCounter
			(1 = start)
	
	 */
	reg [COUNTER_SIZE:0] counter;
	reg startCounter;	
	
	/* LRU ports
		
		LRUread: used to indicate to the LRU that a read has occurred
	    LRUwrite: used to indicate to the LRU that a write has occurred
		assoIndex: associativity index where the read or write had occurred
	    LRUoutput: last accessed (or random) location selected for replacement
			for the fetch operation
	 */
	reg LRUread;
	reg LRUwrite;
	reg [(NUM_ASSO_BITS-1):0] assoIndex;
	wire [(NUM_ASSO_BITS-1):0] LRUoutput;
	
	/* instantiation of this cache's LRU module */
	lru #(.INDEX_SIZE(INDEX_SIZE), .ASSOCIATIVITY(ASSOCIATIVITY), .RANDOM(0))
		LRU (.index(cacheIndex), .asso_index(assoIndex), .select(LRUoutput),
			 .write_trigger(LRUwrite), .read_trigger(LRUread), .reset);
	
	always @(*) begin
		if(reset) begin
			data = 'x;
			tags = 'x;
			validBits = 'x;
			dirtyBits = 'x;
		end
		
		/* Something about making sure each reg is assigned a value every time
		   the thing runs though the always block. */
		dataUpOut = dataUpOut;
		fetchComplete = fetchComplete;
		writeCompleteOut = writeCompleteOut;
		addrOut = addrOut;
		dataDownOut = dataDownOut;
		enableOut = enableOut;
		writeOut = writeOut;
		data = data;
		tags = tags;
		validBits = validBits;
		dirtyBits = dirtyBits;
		startCounter = startCounter;
		LRUread = LRUread;
		LRUwrite = LRUwrite;
		assoIndex = assoIndex;
		
		/* INDEX_SIZE of 1 fix, described above */
		if (INDEX_SELECT_SIZE != 0)
			cacheIndex = preCacheIndex;
		else
			cacheIndex = 0;
		
		/* If the write mode isn't WRITE_BACK, then writeCompleteOut will
		   simply be passed up from the lower cache. In the case of 
		   WRITE_THROUGH, every cache would have been written to and in the
		   case of WRITE_AROUND main memory would have been written to. Main
		   memory will pass up a 1 indicating that the write has finished */
		if (WRITE_MODE != WRITE_BACK)
			writeCompleteOut = writeCompleteIn;
		else
			/* If the write mode is WRITE_BACK, then writeCompleteOut will be
			   assigned father down in the code. */
			writeCompleteOut = 0;
		
		/* If this cache is not enabled, reset I/O, counters, and flags. */
		if (~enableIn) begin
		
			/* Reset Upward I/O */
			dataUpOut = 'x;
			fetchComplete = 0;
			
			/* Reset Downward I/O */
			addrOut = 'x;
			dataDownOut = 'x;
			enableOut = 0;
			writeOut = 0;
			
			/* Reset various flags */
			LRUread = 0;
			LRUwrite = 0;
		end
		
		/* If this cache is enabled and the lower cache is enabled, it means
		   that this cache has missed, and is now waiting for data retrieval
		   from the lower level. */
		else if (enableOut) begin
		
			/* Data has been retrieved so the lower cache can be turned off */
			if (fetchReceive) begin
				enableOut = 0;
				
				/* dirty bits are checked for write-back functionality; if the
				   current data is "dirty" then it it passed down to be written
				   in lower cache */
				if (dirtyBits[cacheIndex][LRUoutput] == 1) begin
					addrOut = {tags[cacheIndex], cacheIndex, wordSelect};
					dataDownOut = data[cacheIndex][LRUoutput];
					writeOut = 1;
					enableOut = 1;
					dirtyBits[cacheIndex][LRUoutput] = 0;
				end
				
				/* store and output the found data and set validBits, tag, and
				   data accordingly */
				validBits[cacheIndex][LRUoutput] = 1;
				tags[cacheIndex][LRUoutput] = tag;
				data[cacheIndex][LRUoutput] = dataDownIn;
				dataUpOut = dataDownIn[wordSelect*RETURN_SIZE +: RETURN_SIZE];
				
				/* A write has just occurred, so we need trigger the lru */
				LRUwrite = 1;
				
				/* finished fetching data */
				fetchComplete = 1;
			end
		end
		
		/* I this cache is enabled and the lower cache is not enabled, it means
		   we are about to preform a read or write operation, start that
		   counter. */
		else if (enableIn) begin
			startCounter = 1;
			
			/* cache delay has occurred, stop that counter */
			if (counter >= CACHE_DELAY) begin
				startCounter = 0;
				
				/* preforming a read operation */
				if (~writeIn) begin
					
					/* search through the cache for data */
					for (int j=0; j<ASSOCIATIVITY; j++) begin
						
						/* If the tags match and valid bit is 1 then data has
						   been found */
						if(tags[cacheIndex][j] == tag && validBits[cacheIndex][j] == 1) begin
							/* set LRU ports to indicate that a read has occurred */
							assoIndex = j;
							LRUread = 1;
							
							/* output found data */
							dataUpOut = data[cacheIndex][j][(wordSelect*RETURN_SIZE) +: RETURN_SIZE];
							
							/* finished "fetching"" data */
							fetchComplete = 1;
							
							/* don't need to continue through for loop */
							break;	
						end
						
						/* searched though entire cache and didn't find the data */
						else if (j == (ASSOCIATIVITY - 1)) begin
							
							/* pass down the address */
							addrOut = addrIn;
							
							/* enable the lower cache */
							enableOut = 1;
						end
					end
				end
				
				/* preforming a write operation */
				else begin
					
					/* address, data, and write signal will be passed down */
					addrOut = addrIn;
					dataDownOut = dataUpIn;
					writeOut = 1;
					
					/* Now check the write mode for this cache */
					
					/* If the write mode is WRITE_AROUND, simply invalidate
					   the valid bit and enable the lower cache. */
					if (WRITE_MODE == WRITE_AROUND) begin
						for (int j=0; j<ASSOCIATIVITY; j++) begin
							if(tags[cacheIndex][j] == tag && validBits[cacheIndex][j] == 1) begin
								validBits[cacheIndex][j] = 0;
								break;	end
						end
						
						/* enable the lower cache */
						enableOut = 1;
					end
					
					/* If the write mode is WRITE_THROUGH, write the data to
					   the appropriate location, and enable the lower cache. */
					else if (WRITE_MODE == WRITE_THROUGH) begin
						for (int j=0; j<ASSOCIATIVITY; j++) begin
							if(tags[cacheIndex][j] == tag && validBits[cacheIndex][j] == 1) begin
								data[cacheIndex][j][wordSelect*BLOCK_SIZE +: 32] = dataUpIn;
								break;	end
						end
						
						/* enable the lower cache */
						enableOut = 1;
					end
					
					/* If the write mode is WRITE_BACK and data was found set
					   the dirtyBit, write the data, and don't enable the lower
					   cache. If data wasn't found enable the lower cache.
					 */
					else begin
						for (int j=0; j<ASSOCIATIVITY; j++) begin
							if(tags[cacheIndex][j] == tag && validBits[cacheIndex][j] == 1) begin
								dirtyBits[cacheIndex][j] = 1'b1;
								data[cacheIndex][j][wordSelect*BLOCK_SIZE +: 32] = dataUpIn;
								enableOut = 0;
								writeCompleteOut = 1;
								break;	end
							/* Try writing to the lower cache if data is not
							   here. */
							else if (j == (ASSOCIATIVITY - 1)) begin
								enableOut = 1;
							end
						end
					end

				end
			end
		end
	end
	
	/* At every posedge if startCounter is true, increment the counter to track
	   the cache delay. If the cache isn't enabled, reset the counter to 0. */
	always @(posedge clock) begin
		if (~enableIn)
			counter <= 0;
		else if (startCounter) begin
			counter <= counter + 1;
		end
	end
endmodule
`endprotect

module cache_testbench();
	parameter [1:0] WRITE_AROUND = 2'b00, WRITE_THROUGH = 2'b01, WRITE_BACK = 2'b10;
	
	// cache parameters
	parameter WRITE_MODE = WRITE_THROUGH;
	
	parameter INDEX_SIZEL1 = 1;
	parameter INDEX_SIZEL2 = 4;
	parameter SIZEMEM = 2048;
	
	parameter BLOCK_SIZEL1 = 64;
	parameter BLOCK_SIZEL2 = 128;
	
	parameter ADDR_LENGTH = $clog2(SIZEMEM);
	
	wire [31:0] dataOut;
	wire requestComplete;
	reg [31:0] dataIn = 32'hFFFFFFFF;
	reg [(ADDR_LENGTH-1):0] addrIn;
	reg enableIn;
	reg writeIn;
	
	wire [(ADDR_LENGTH-1):0] addrInL1;
	wire [31:0] dataUpOutL1;
	wire [31:0] dataUpInL1;
	wire fetchCompleteL1, enableInL1, writeCompleteOutL1, writeInL1;
	wire [(ADDR_LENGTH-1):0] addrOutL1;
	wire [(BLOCK_SIZEL1-1):0] dataDownInL1, dataDownOutL1;
	wire fetchReceiveL1, enableOutL1, writeCompleteInL1, writeOutL1;
	
	wire [(ADDR_LENGTH-1):0] addrInL2;
	wire [(BLOCK_SIZEL1-1):0] dataUpOutL2;
	wire [(BLOCK_SIZEL1-1):0] dataUpInL2;
	wire fetchCompleteL2, enableInL2, writeCompleteOutL2, writeInL2;
	wire [(ADDR_LENGTH-1):0] addrOutL2;
	wire [(BLOCK_SIZEL2-1):0] dataDownInL2, dataDownOutL2;
	wire fetchReceiveL2, enableOutL2, writeCompleteInL2, writeOutL2;
	
	wire [(ADDR_LENGTH-1):0] addrInMem;
	wire [(BLOCK_SIZEL2-1):0] dataUpOutMem, dataUpInMem;
	wire fetchCompleteMem, enableInMem, writeCompleteOutMem, writeInMem;
	
	reg clock, reset;
	
	parameter t = 10;
	parameter d = 50;
	
	// Top-level I/O
	assign 	dataOut 				= dataUpOutL1;
	assign 	addrInL1				= addrIn;
	assign 	dataUpInL1 			= dataIn;
	assign 	enableInL1			= enableIn;
	assign 	writeInL1			= writeIn;
	assign 	requestComplete	= fetchCompleteL1 | writeCompleteOutL1;
	
	// L1 DOWN I/O
	assign addrInL2					= addrOutL1;
	assign dataDownInL1				= dataUpOutL2;
	assign dataUpInL2					= dataDownOutL1;
	assign fetchReceiveL1			= fetchCompleteL2;
	assign enableInL2					= enableOutL1;
	assign writeCompleteInL1		= writeCompleteOutL2;
	assign writeInL2					= writeOutL1;
	
	// L2 DOWN I/O
	assign addrInMem					= addrOutL2;
	assign dataDownInL2				= dataUpOutMem;
	assign dataUpInMem				= dataDownOutL2;
	assign fetchReceiveL2			= fetchCompleteMem;
	assign enableInMem				= enableOutL2;
	assign writeCompleteInL2		= writeCompleteOutMem;
	assign writeInMem					= writeOutL2;

	cache 			#(.INDEX_SIZE(INDEX_SIZEL1), .ADDR_LENGTH(ADDR_LENGTH), .BLOCK_SIZE(BLOCK_SIZEL1), .RETURN_SIZE(32), .WRITE_MODE(WRITE_MODE))
			L1 		(addrInL1, 	dataUpOutL1, 	dataUpInL1, 	fetchCompleteL1, 	enableInL1, 	writeCompleteOutL1, 	writeInL1,
						 addrOutL1,	dataDownInL1,	dataDownOutL1,	fetchReceiveL1,	enableOutL1,	writeCompleteInL1,	writeOutL1,
						 clock, 		reset);
						 
	cache 			#(.INDEX_SIZE(INDEX_SIZEL2), .ADDR_LENGTH(ADDR_LENGTH), .BLOCK_SIZE(BLOCK_SIZEL2), .RETURN_SIZE(BLOCK_SIZEL1), .WRITE_MODE(WRITE_MODE))
			L2 		(addrInL2, 	dataUpOutL2, 	dataUpInL2, 	fetchCompleteL2, 	enableInL2, 	writeCompleteOutL2, 	writeInL2,
						 addrOutL2,	dataDownInL2,	dataDownOutL2,	fetchReceiveL2,	enableOutL2,	writeCompleteInL2,	writeOutL2,
						 clock, 		reset);
	
	mainMem			#(.SIZE(SIZEMEM), .ADDR_LENGTH(ADDR_LENGTH), .RETURN_SIZE(BLOCK_SIZEL2)) 
			memory	(addrInMem, dataUpOutMem, 	dataUpInMem, 	fetchCompleteMem, enableInMem, 	writeCompleteOutMem, writeInMem,
						 clock, 		reset);
	
	always #(t/2) clock = ~clock;
		
	integer i = 0;
	initial begin
		clock <= 0;
		enableIn <= 0;
		reset <= 1'b1;			@(posedge clock);
		reset <= 1'b0;			@(posedge clock);
		writeIn <= 0;			@(posedge clock);
	
		// Read tests
		for (integer i = 0; i<20; i++) begin
			addrIn = i;//{$random} % 64;
			enableIn = 1;
			#(d*t);
			enableIn = 0;
			#t;
		end
		
		// write
		writeIn <= 1;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		#(100*t);
		// reset
					@(posedge clock);
		reset = 1;	@(posedge clock);
					@(posedge clock);
		
		// WRITE AROUND tests
//		addrIn <= 0;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		writeIn <= 1;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		writeIn <= 0;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 1;
//		writeIn <= 0;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		
//		addrIn = 4;					@(posedge clock);
//		writeIn <= 0;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		writeIn <= 1;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		writeIn <= 0;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
		
		// WRITE THROUGH TESTS
//		addrIn = 0;					@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		writeIn <= 1;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		writeIn <= 0;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;

//		// WRITE BACK TESTS
//		addrIn = 0;					@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		writeIn <= 1;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		writeIn <= 0;				@(posedge clock);
//		addrIn = 4;					@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 8;					@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 12;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 12;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 16;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 0;					@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 24;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 32;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 40;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 48;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 0;					@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 48;				@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
//		
//		addrIn = 0;					@(posedge clock);
//		enableIn <= 1;				@(posedge clock);
//		#(100*t);
//		enableIn <= 0;				@(posedge clock);
//		#t;
		
		#(10*t);
		$stop;
	end
endmodule 