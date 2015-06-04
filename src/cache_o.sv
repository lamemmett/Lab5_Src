module cache #(parameter SIZE=128, ADDR_LENGTH=10, CACHE_DELAY=10, BLOCK_SIZE=64, RETURN_SIZE=32, ASSOCIATIVITY=4, WRITE_MODE=2'b10)
				(addrIn, 	dataUpOut, 	dataUpIn, 		fetchComplete, enableIn, 	writeCompleteOut, writeIn,
				 addrOut,	dataDownIn,	dataDownOut,	fetchReceive,	enableOut,	writeCompleteIn,	writeOut,
				 clock, reset);
	
	parameter [1:0] WRITE_AROUND = 2'b00, WRITE_THROUGH = 2'b01, WRITE_BACK = 2'b10;
	
	parameter COUNTER_SIZE = $clog2(CACHE_DELAY);
	
	parameter WORD_SELECT_SIZE = $clog2(BLOCK_SIZE/32);
	parameter INDEX_SIZE = $clog2(SIZE/BLOCK_SIZE);
	parameter TAG_SIZE = ADDR_LENGTH - WORD_SELECT_SIZE - INDEX_SIZE;
	
	parameter NUM_ASSO_BITS = $clog2(ASSOCIATIVITY);
	
	// I/O STUFF	------
	
	input clock, reset;
	
	// UP I/O
	input 		[(ADDR_LENGTH-1):0] 	addrIn;
	output reg 	[(RETURN_SIZE-1):0] 	dataUpOut;
	input 		[(RETURN_SIZE-1):0] 	dataUpIn;
	output reg								fetchComplete;
	input 									enableIn;
	output 	 								writeCompleteOut;
	input										writeIn;
	
	// DOWN I/O
	output reg 	[(ADDR_LENGTH-1):0] 	addrOut;
	input			[(BLOCK_SIZE-1):0]	dataDownIn;
	output reg	[(BLOCK_SIZE-1):0]	dataDownOut;
	input										fetchReceive;
	output reg								enableOut;
	input 									writeCompleteIn;
	output reg								writeOut;
	
	assign writeCompleteOut = writeCompleteIn;
	
	wire [WORD_SELECT_SIZE-1:0]	wordSelect 	= addrIn[0 +: WORD_SELECT_SIZE];
	wire [INDEX_SIZE-1:0]			cacheIndex 	= addrIn[WORD_SELECT_SIZE +: INDEX_SIZE];
	wire [TAG_SIZE-1:0]				tag 			= addrIn[(ADDR_LENGTH-1):(WORD_SELECT_SIZE+INDEX_SIZE)];
	
	// CACHE CONTENTS
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(BLOCK_SIZE-1):0]  data;
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(TAG_SIZE-1):0] 	 tags;
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0]							 validBits;
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] 							 dirtyBits;
	
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
	lru #(.INDEX_SIZE(SIZE/BLOCK_SIZE), .ASSOCIATIVITY(ASSOCIATIVITY)) LRU
		  (cacheIndex, assoIndex, LRUoutput, LRUwrite, LRUread, reset, clock);
	
	always @(*) begin
//		if (wb_enable_in) begin
//			for (int j=0; j<ASSOCIATIVITY; j++) begin
//				if(tags[wb_cacheIndex][j] == tag && valid_bits[wb_cacheIndex][j] == 1) begin
//					data[wb_cacheIndex][j] = data_in;
//					break;	end
//			end
//		end
	
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
		else if (enableOut) begin	// retrieved data from lower cache, write data to cache now
			if (fetchReceive) begin
				// check dirty bits for write-back functionality
				if (dirtyBits[cacheIndex][LRUoutput] == 1) begin
					addrOut = {tags[cacheIndex], cacheIndex, wordSelect};
					dataDownOut = data[cacheIndex][LRUoutput];
					writeOut = 1;
					enableOut = 1;
				end
				LRUwrite = 1;
				dataUpOut = dataDownIn[wordSelect*32 +: RETURN_SIZE];
				validBits[cacheIndex][LRUoutput] = 1;
				tags[cacheIndex][LRUoutput] = tag;
				data[cacheIndex][LRUoutput] = dataDownIn;
				
				fetchComplete = 1;
			end
		end
		else if (enableIn) begin
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
							dataUpOut = data[cacheIndex][j][((wordSelect+1)*RETURN_SIZE-1) -: RETURN_SIZE];
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
	reg [31:0] dataOut;
	reg [31:0] dataIn = 32'hFFFFFFFF;
	reg [9:0] addrIn;
	reg requestComplete;
	reg enableIn;
	reg writeIn;
	
	wire [9:0] addrInL1;
	wire [31:0] dataUpOutL1;
	wire [31:0] dataUpInL1;
	wire fetchCompleteL1, enableInL1, writeCompleteOutL1, writeInL1;
	wire [9:0] addrOutL1;
	wire [63:0] dataDownInL1, dataDownOutL1;
	wire fetchReceiveL1, enableOutL1, writeCompleteInL1, writeOutL1;
	
	wire [9:0] addrInL2;
	wire [63:0] dataUpOutL2;
	wire [63:0] dataUpInL2;
	wire fetchCompleteL2, enableInL2, writeCompleteOutL2, writeInL2;
	wire [9:0] addrOutL2;
	wire [63:0] dataDownInL2, dataDownOutL2;
	wire fetchReceiveL2, enableOutL2, writeCompleteInL2, writeOutL2;
	
	wire [9:0] addrInMem;
	wire [63:0] dataUpOutMem, dataUpInMem;
	wire fetchCompleteMem, enableInMem, writeCompleteOutMem, writeInMem;
	
	reg clock, reset;
	
	parameter t = 10;
	parameter d = 50;
	
	// Top-level I/O
	assign 	addrInL1			= addrIn;
	assign 	dataUpInL1 		= dataIn;
	assign 	enableInL1		= enableIn;
	assign 	writeInL1		= writeIn;
	always @(*) begin
		dataOut 					= dataUpOutL1;
		requestComplete		= fetchCompleteL1 | writeCompleteOutL1;
	end
	
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

	cache L1 		(addrInL1, 	dataUpOutL1, 	dataUpInL1, 	fetchCompleteL1, 	enableInL1, 	writeCompleteOutL1, 	writeInL1,
						 addrOutL1,	dataDownInL1,	dataDownOutL1,	fetchReceiveL1,	enableOutL1,	writeCompleteInL1,	writeOutL1,
						 clock, 		reset);
						 
	cache 			#(.SIZE(256), .RETURN_SIZE(64))
			L2 		(addrInL2, 	dataUpOutL2, 	dataUpInL2, 	fetchCompleteL2, 	enableInL2, 	writeCompleteOutL2, 	writeInL2,
						 addrOutL2,	dataDownInL2,	dataDownOutL2,	fetchReceiveL2,	enableOutL2,	writeCompleteInL2,	writeOutL2,
						 clock, 		reset);
	
	mainMem memory	(addrInMem, dataUpOutMem, 	dataUpInMem, 	fetchCompleteMem, enableInMem, 	writeCompleteOutMem, writeInMem,
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
//		for (integer i = 0; i<128; i++) begin
//			addrIn = i;
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
		
		#(10*t);
		$stop;
	end
endmodule 