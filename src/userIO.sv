module userIO #(parameter ID=1234567)
	(clock, reset, addr, enable, write, dataIn, requestComplete, dataOut);
	
	parameter NUM_CACHE_LEVELS = 4;
	parameter ADDR_LENGTH = 13;
	input clock, reset, enable, write;
	input [31:0] dataIn;
	input [(ADDR_LENGTH-1):0] addr;
	output requestComplete;
	output [31:0] dataOut;
	
	generate
		parameter HASH = ID * 37;
		
		parameter BLOCK_SIZE_L1 = 64;
		parameter BLOCK_SIZE_L2 = BLOCK_SIZE_L1 * ((2*((HASH/(10**1)) % 2)) + 2);
		parameter BLOCK_SIZE_L3 = BLOCK_SIZE_L2 * ((2*((HASH/(10**2)) % 2)) + 2);
		parameter BLOCK_SIZE_L4 = BLOCK_SIZE_L3 * ((2*((HASH/(10**3)) % 2)) + 2);
		
		parameter NUM_CACHE_INDEX_L1 	= (((HASH/(10**0))%10) % 8) + 1;
		parameter NUM_CACHE_INDEX_L2 	= (((HASH/(10**1))%10) % 8) + 1;
		parameter NUM_CACHE_INDEX_L3 	= (((HASH/(10**2))%10) % 8) + 1;
		parameter NUM_CACHE_INDEX_L4	= (((HASH/(10**3))%10) % 8) + 1;
		
		parameter NUM_ASSO_INDEX_L1 	= (((47*HASH/(10**0))%10) % 8) + 1;
		parameter NUM_ASSO_INDEX_L2 	= (((47*HASH/(10**1))%10) % 8) + 1;
		parameter NUM_ASSO_INDEX_L3 	= (((47*HASH/(10**2))%10) % 8) + 1;
		parameter NUM_ASSO_INDEX_L4	= (((47*HASH/(10**3))%10) % 8) + 1;
		
		// GENERATE THE ACTUAL CACHES
		cache #(.INDEX_SIZE(NUM_CACHE_INDEX_L1), .ADDR_LENGTH(ADDR_LENGTH), .BLOCK_SIZE(BLOCK_SIZE_L1), .ASSOCIATIVITY(NUM_ASSO_INDEX_L1))
				L1 (addrIn, 	dataUpOut, 	dataUpIn, 		fetchComplete, enableIn, 	writeCompleteOut,   writeIn,
				 addrOut,	dataDownIn,	dataDownOut,	fetchReceive,	enableOut,	writeCompleteIn,	writeOut,
				 clock,     reset);
	endgenerate
	
//	initial begin
//		static integer i = 0;
//		blockSizes[0] = 64;
//		// calculate cache size-related parameters
//		//for (integer i = 0; i < NUM_CACHE_LEVELS; i++) begin
//			// calculate block sizes
//			if (i != 0) begin
//				blockSizes[i] = blockSizes[i-1] * ((2*((HASH/(10*i)) % 2)) + 2);	// lower cache block size is 2 or 4 times bigger than one above
//			end
//
//			// calculate number of cache indices for each levels
//			numCacheIndices[i] = (((HASH/(10**i))%10) % 8) + 1;
//			if (numCacheIndices[i] > 4) begin
//				numAssoIndices[i] = (((3*HASH/(10**i))%10) % 2) + 1;
//			end else if (numCacheIndices[i] > 2) begin
//				numAssoIndices[i] = (((5*HASH/(10**i))%10) % 4) + 1;
//			end else begin
//				numAssoIndices[i] = (((7*HASH/(10**i))%10) % 8) + 1;
//			end
//			
//			// calculate cache sizes
//			cacheSizes[i] = blockSizes[i] * numCacheIndices[i] * numAssoIndices[i];
//		//end
//		
//		//generate
//			// Create the memory system with numCacheLevels cache levels
//			wire [(ADDR_LENGTH-1):0] addrInL1;
//			wire [31:0] dataUpOutL1;
//			wire [31:0] dataUpInL1;
//			wire fetchCompleteL1, enableInL1, writeCompleteOutL1, writeInL1;
//			wire [(ADDR_LENGTH-1):0] addrOutL1;
//			wire [blockSizes[0]-1:0] dataDownInL1, dataDownOutL1;
//			wire fetchReceiveL1, enableOutL1, writeCompleteInL1, writeOutL1;
//		//endgenerate
//	end
	
endmodule 

module userIO_testbench();
	parameter i = 34;
	reg clock, reset, enable;
	reg [31:0] dataIn;
	wire requestComplete;
	wire [31:0] dataOut;
	
	//userIO #(.ID(1130291)) cacheSystem (clock, reset, dataIn, enable, requestComplete, dataOut);
	
	initial begin
		#20;
		$stop;
	end

	parameter x = i *37;
		
	userIO #(.ID(x)) cacheSystem2 (clock, reset, dataIn, enable, requestComplete, dataOut);
endmodule 