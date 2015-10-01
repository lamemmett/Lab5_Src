`protect
/* Cache system which generated the cache structure in accordance to the ID
   It's a wrapper for the insideSystem since no writes */
module cacheSystem #(parameter ID=1234567)
	(clock, reset, addrIn, enableIn, requestComplete, dataOut);
	
	parameter ADDR_LENGTH = 15;
	
	input clock, reset, enableIn;
	input [(ADDR_LENGTH-1):0] addrIn;
	output requestComplete;
	output [31:0] dataOut;
	
	insideSystem #(.ID(ID), .ADDR_LENGTH(ADDR_LENGTH)) rom
		(.clock, .reset, .addrIn, .enableIn, .writeIn(1'b0), .dataIn('X), .requestComplete, .dataOut);

endmodule

/* vistigal module from write and read cache attempt */
module insideSystem #(parameter ID=1234567, parameter ADDR_LENGTH = 15)
	(clock, reset, addrIn, enableIn, writeIn, dataIn, requestComplete, dataOut);
	
	parameter [1:0] WRITE_AROUND = 2'b00, WRITE_THROUGH = 2'b01, WRITE_BACK = 2'b10;
	
	input clock, reset, enableIn, writeIn;
	input [31:0] dataIn;
	input [(ADDR_LENGTH-1):0] addrIn;
	output requestComplete;
	output [31:0] dataOut;
	
	// determine cache parameters
	parameter HASH = (ID % 1000000) * 37;
	
	// Determine each cache's write-mode
	parameter WRITE_MODE_L1	= HASH 			% 3;
	parameter WRITE_MODE_L2 = (HASH / 10) 	% 3;
	parameter WRITE_MODE_L3 = (HASH / 100) % 3;
	
	// Each cache's block size is either 2 or 4 times bigger than the previous one
	parameter BLOCK_SIZE_L1 = 32 * ((2*((HASH/(10**0)) % 2)) + 2);
	parameter BLOCK_SIZE_L2 = BLOCK_SIZE_L1 * ((2*((HASH/(10**1)) % 2)) + 2);
	parameter BLOCK_SIZE_L3 = BLOCK_SIZE_L2 * ((2*((HASH/(10**2)) % 2)) + 2);
	
	// compute L1 parameters
	parameter L1slots = ((HASH/(10**0))%10) % 5 + 2;
	parameter NUM_CACHE_INDEX_L1 	= 2 ** (((17*HASH/(10**0))%10) % $clog2(L1slots));
	parameter NUM_ASSO_INDEX_L1 	= L1slots / NUM_CACHE_INDEX_L1;
	
	
	// compute L2 parameters
	parameter L2slots = ((HASH/(10**1))%10) % 4 + L1slots + 2;
	parameter NUM_CACHE_INDEX_L2 	= 2 ** (((17*HASH/(10**1))%10) % $clog2(L2slots));
	parameter NUM_ASSO_INDEX_L2 	= L2slots / NUM_CACHE_INDEX_L2;
	
	// compute L3 parameters
	parameter L3slots = ((HASH/(10**2))%10) % 4 + L2slots + 4;
	parameter NUM_CACHE_INDEX_L3 	= 2 ** (((17*HASH/(10**2))%10) % $clog2(L3slots));
	parameter NUM_ASSO_INDEX_L3 	= L3slots / NUM_CACHE_INDEX_L3;
	
	// num associativity indices is between 1-4
	parameter CACHE_DELAY_L1		= ((23*HASH/(10**0))%9) + 1;
	parameter CACHE_DELAY_L2		= ((23*HASH/(10**1))%9 + 1) * 10;
	parameter CACHE_DELAY_L3		= ((23*HASH/(10**2))%9 + 1) * 100;
	parameter CACHE_DELAY_MEM		= 1000;
	
	// CONNECTING WIRES FOR THE CACHE SYSTEM
	wire [(ADDR_LENGTH-1):0] addrInL1;
	wire [31:0] dataUpOutL1;
	wire [31:0] dataUpInL1;
	wire fetchCompleteL1, enableInL1, writeCompleteOutL1, writeInL1;
	wire [(ADDR_LENGTH-1):0] addrOutL1;
	wire [(BLOCK_SIZE_L1-1):0] dataDownInL1, dataDownOutL1;
	wire fetchReceiveL1, enableOutL1, writeCompleteInL1, writeOutL1;
	
	wire [(ADDR_LENGTH-1):0] addrInL2;
	wire [(BLOCK_SIZE_L1-1):0] dataUpOutL2;
	wire [(BLOCK_SIZE_L1-1):0] dataUpInL2;
	wire fetchCompleteL2, enableInL2, writeCompleteOutL2, writeInL2;
	wire [(ADDR_LENGTH-1):0] addrOutL2;
	wire [(BLOCK_SIZE_L2-1):0] dataDownInL2, dataDownOutL2;
	wire fetchReceive_L2, enableOutL2, writeCompleteInL2, writeOutL2;
	
	wire [(ADDR_LENGTH-1):0] addrInL3;
	wire [(BLOCK_SIZE_L2-1):0] dataUpOutL3;
	wire [(BLOCK_SIZE_L2-1):0] dataUpInL3;
	wire fetchCompleteL3, enableInL3, writeCompleteOutL3, writeInL3;
	wire [(ADDR_LENGTH-1):0] addrOutL3;
	wire [(BLOCK_SIZE_L3-1):0] dataDownInL3, dataDownOutL3;
	wire fetchReceiveL3, enableOutL3, writeCompleteInL3, writeOutL3;
	
	wire [(ADDR_LENGTH-1):0] addrInMem;
	wire [(BLOCK_SIZE_L3-1):0] dataUpOutMem, dataUpInMem;
	wire fetchCompleteMem, enableInMem, writeCompleteOutMem, writeInMem;
	
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
	assign addrInL3					= addrOutL2;
	assign dataDownInL2				= dataUpOutL3;
	assign dataUpInL3					= dataDownOutL2;
	assign fetchReceiveL2			= fetchCompleteL3;
	assign enableInL3					= enableOutL2;
	assign writeCompleteInL2		= writeCompleteOutL3;
	assign writeInL3					= writeOutL2;
	
	// L3 DOWN I/O
	assign addrInMem					= addrOutL3;
	assign dataDownInL3				= dataUpOutMem;
	assign dataUpInMem				= dataDownOutL3;
	assign fetchReceiveL3			= fetchCompleteMem;
	assign enableInMem				= enableOutL3;
	assign writeCompleteInL3		= writeCompleteOutMem;
	assign writeInMem					= writeOutL3;
	
	// INSTANTIATE THE ACTUAL CACHES
	cache 			#(.INDEX_SIZE(NUM_CACHE_INDEX_L1), .ADDR_LENGTH(ADDR_LENGTH), .CACHE_DELAY(CACHE_DELAY_L1), 
						  .BLOCK_SIZE(BLOCK_SIZE_L1), .RETURN_SIZE(32), .ASSOCIATIVITY(NUM_ASSO_INDEX_L1), .WRITE_MODE(WRITE_MODE_L1))
			L1 		(addrInL1, 	dataUpOutL1, 	dataUpInL1, 	fetchCompleteL1, 	enableInL1, 	writeCompleteOutL1, 	writeInL1,
						 addrOutL1,	dataDownInL1,	dataDownOutL1,	fetchReceiveL1,	enableOutL1,	writeCompleteInL1,	writeOutL1,
						 clock, 		reset);
						 
	cache 			#(.INDEX_SIZE(NUM_CACHE_INDEX_L2), .ADDR_LENGTH(ADDR_LENGTH), .CACHE_DELAY(CACHE_DELAY_L2), 
						  .BLOCK_SIZE(BLOCK_SIZE_L2), .RETURN_SIZE(BLOCK_SIZE_L1), .ASSOCIATIVITY(NUM_ASSO_INDEX_L2), .WRITE_MODE(WRITE_MODE_L2))
			L2 		(addrInL2, 	dataUpOutL2, 	dataUpInL2, 	fetchCompleteL2, 	enableInL2, 	writeCompleteOutL2, 	writeInL2,
						 addrOutL2,	dataDownInL2,	dataDownOutL2,	fetchReceiveL2,	enableOutL2,	writeCompleteInL2,	writeOutL2,
						 clock, 		reset);
						 
	cache 			#(.INDEX_SIZE(NUM_CACHE_INDEX_L3), .ADDR_LENGTH(ADDR_LENGTH), .CACHE_DELAY(CACHE_DELAY_L3), 
						  .BLOCK_SIZE(BLOCK_SIZE_L3), .RETURN_SIZE(BLOCK_SIZE_L2), .ASSOCIATIVITY(NUM_ASSO_INDEX_L3), .WRITE_MODE(WRITE_MODE_L3))
			L3 		(addrInL3, 	dataUpOutL3, 	dataUpInL3, 	fetchCompleteL3, 	enableInL3, 	writeCompleteOutL3, 	writeInL3,
						 addrOutL3,	dataDownInL3,	dataDownOutL3,	fetchReceiveL3,	enableOutL3,	writeCompleteInL3,	writeOutL3,
						 clock, 		reset);
	
	mainMem			#(.SIZE(2**ADDR_LENGTH), .ADDR_LENGTH(ADDR_LENGTH), .MEM_DELAY(CACHE_DELAY_MEM), .RETURN_SIZE(BLOCK_SIZE_L3)) 
			memory	(addrInMem, dataUpOutMem, 	dataUpInMem, 	fetchCompleteMem, enableInMem, 	writeCompleteOutMem, writeInMem,
						 clock, 		reset); 
endmodule
`endprotect