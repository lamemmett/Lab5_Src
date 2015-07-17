module cache #(parameter INDEX_SIZE=1, ADDR_LENGTH=10, CACHE_DELAY=10, BLOCK_SIZE=128, RETURN_SIZE=32, ASSOCIATIVITY=2, WRITE_MODE=2'b10)
				(addrIn, 	dataUpOut, 	dataUpIn, 		fetchComplete, enableIn, 	writeCompleteOut,   writeIn,
				 addrOut,	dataDownIn,	dataDownOut,	fetchReceive,	enableOut,	writeCompleteIn,	writeOut,
				 clock,     reset);
	
	parameter [1:0] WRITE_AROUND = 2'b00, WRITE_THROUGH = 2'b01, WRITE_BACK = 2'b10;
	
	parameter COUNTER_SIZE = $clog2(CACHE_DELAY);
	
	parameter WORD_SELECT_SIZE = $clog2(BLOCK_SIZE/RETURN_SIZE);
	parameter INDEX_SELECT_SIZE = $clog2(INDEX_SIZE);
	parameter TAG_SIZE = ADDR_LENGTH - $clog2(BLOCK_SIZE/32) - INDEX_SELECT_SIZE;
	
	parameter NUM_ASSO_BITS = $clog2(ASSOCIATIVITY);
	
	// I/O STUFF	------
	
	input clock, reset;
	
	// UP I/O
	input 		[(ADDR_LENGTH-1):0] 	addrIn;
	output reg 	[(RETURN_SIZE-1):0] 	dataUpOut;
	input 		[(RETURN_SIZE-1):0] 	dataUpIn;
	output reg							fetchComplete;
	input 								enableIn;
	output reg							writeCompleteOut;
	input								writeIn;
	
	// DOWN I/O
	output reg 	[(ADDR_LENGTH-1):0] 	addrOut;
	input			[(BLOCK_SIZE-1):0]	dataDownIn;
	output reg	[(BLOCK_SIZE-1):0]	dataDownOut;
	input										fetchReceive;
	output reg								enableOut;
	input 									writeCompleteIn;
	output reg								writeOut;
	
	wire [WORD_SELECT_SIZE-1:0]	wordSelect 	= addrIn[(ADDR_LENGTH - 1 - TAG_SIZE - INDEX_SELECT_SIZE) -: WORD_SELECT_SIZE];
	wire [INDEX_SELECT_SIZE-1:0]			cacheIndex 	= addrIn[(ADDR_LENGTH - 1 - TAG_SIZE) -: INDEX_SELECT_SIZE];
	wire [TAG_SIZE-1:0]				tag 			= addrIn[(ADDR_LENGTH-1) -: TAG_SIZE];
	
	// CACHE CONTENTS
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(BLOCK_SIZE-1):0]  data;
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(TAG_SIZE-1):0] 	 tags;
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0]							 validBits;
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] 							 dirtyBits;
	
	// Counters and flags
	reg [COUNTER_SIZE-1:0] counter;
	reg startCounter;
	reg waitingForLower = 0;
	// LRU ports
	reg LRUread = 0;
	reg LRUwrite = 0;
	reg [(NUM_ASSO_BITS-1):0] assoIndex = 0;
	wire [(NUM_ASSO_BITS-1):0] LRUoutput;
	
	// instantiate LRU module
	lru #(.INDEX_SIZE(INDEX_SIZE), .ASSOCIATIVITY(ASSOCIATIVITY),  .RANDOM(0)) LRU
		  (cacheIndex, assoIndex, LRUoutput, LRUwrite, LRUread, reset);
	
	always @(*) begin
		if (WRITE_MODE != WRITE_BACK)
			writeCompleteOut = writeCompleteIn;
		else
			writeCompleteOut = 0;
			
		if (~enableIn) begin
			// Reset UP I/O
			dataUpOut = 'x;
			fetchComplete = 0;
			
			// Reset DOWN I/O
			addrOut = 'x;
			dataDownOut = 'x;
			enableOut = 0;
			writeOut = 0;
			
			// Reset various counters and flags
			LRUread = 0;
			LRUwrite = 0;
			counter = 0;
		end
		else if (enableOut) begin	// missed in this cache, waiting for retrieval from lower level
			if (fetchReceive) begin
				enableOut = 0;
				// check dirty bits for write-back functionality
				if (dirtyBits[cacheIndex][LRUoutput] == 1) begin
					addrOut = {tags[cacheIndex], cacheIndex, wordSelect};
					dataDownOut = data[cacheIndex][LRUoutput];
					writeOut = 1;
					enableOut = 1;
					dirtyBits[cacheIndex][LRUoutput] = 0;
				end
				dataUpOut = dataDownIn[wordSelect*RETURN_SIZE +: RETURN_SIZE];
				validBits[cacheIndex][LRUoutput] = 1;
				tags[cacheIndex][LRUoutput] = tag;
				data[cacheIndex][LRUoutput] = dataDownIn;
				LRUwrite = 1;
				
				fetchComplete = 1;
			end
		end
		else if (enableIn) begin	// wait for counter delay, perform read/write operation
			startCounter = 1;
			if (counter >= CACHE_DELAY) begin
				startCounter = 0;
				// Read operation
				if (~writeIn) begin
					for (int j=0; j<ASSOCIATIVITY; j++) begin
						// data here
						if(tags[cacheIndex][j] == tag && validBits[cacheIndex][j] == 1) begin
							assoIndex = j;
							LRUread = 1;
							dataUpOut = data[cacheIndex][j][(wordSelect*RETURN_SIZE) +: RETURN_SIZE];
							fetchComplete = 1;
							break;	
						end
						// data not here
						else if (j == (ASSOCIATIVITY - 1)) begin
							addrOut = addrIn;
							enableOut = 1;
						end
					end
				end
				// Write operation
				else begin
					addrOut = addrIn;
					dataDownOut = dataUpIn;
					writeOut = 1;
					if (WRITE_MODE == WRITE_AROUND) begin
						for (int j=0; j<ASSOCIATIVITY; j++) begin
							if(tags[cacheIndex][j] == tag && validBits[cacheIndex][j] == 1) begin
								validBits[cacheIndex][j] = 0;
								enableOut = 1;
								break;	end
						end
					end
					else if (WRITE_MODE == WRITE_THROUGH) begin
						for (int j=0; j<ASSOCIATIVITY; j++) begin
							if(tags[cacheIndex][j] == tag && validBits[cacheIndex][j] == 1) begin
								data[cacheIndex][j][wordSelect*BLOCK_SIZE +: 32] = dataUpIn;
								enableOut = 1;
								break;	end
						end
					end
					else begin	// WRITE_BACK
						for (int j=0; j<ASSOCIATIVITY; j++) begin
							if(tags[cacheIndex][j] == tag && validBits[cacheIndex][j] == 1) begin
								dirtyBits[cacheIndex][j] = 1'b1;
								tags[cacheIndex][j] = tag;
								data[cacheIndex][j][wordSelect*BLOCK_SIZE +: 32] = dataUpIn;
								writeOut = 0;
								enableOut = 0;
								writeCompleteOut = 1;
								break;	end
							else if (j == (ASSOCIATIVITY - 1)) begin	// Try writing to lower cache if data not present here
								writeOut = 1;
								enableOut = 1;
							end
						end
					end

				end
			end
		end
	end
	
	always @(posedge clock) begin
		if (startCounter) begin
			counter <= counter + 1;
		end
	end
endmodule

module cache_testbench();
	parameter [1:0] WRITE_AROUND = 2'b00, WRITE_THROUGH = 2'b01, WRITE_BACK = 2'b10;
	
	// cache parameters
	parameter WRITE_MODE = WRITE_BACK;
	
	parameter INDEX_SIZEL1 = 2;
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
//		for (integer i = 0; i<20; i++) begin
//			addrIn = {$random} % 64;
//			enableIn = 1;
//			#(d*t);
//			enableIn = 0;
//			#t;
//		end
		
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

		// WRITE BACK TESTS
		addrIn = 0;					@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		writeIn <= 1;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		writeIn <= 0;				@(posedge clock);
		addrIn = 4;					@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 8;					@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 12;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 12;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 16;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 0;					@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 24;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 32;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 40;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 48;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 0;					@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 48;				@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		addrIn = 0;					@(posedge clock);
		enableIn <= 1;				@(posedge clock);
		#(100*t);
		enableIn <= 0;				@(posedge clock);
		#t;
		
		#(10*t);
		$stop;
	end
endmodule 