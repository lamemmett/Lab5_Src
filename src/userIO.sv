module userIO #(parameter ID=1234567)
	(clock, reset, dataIn, enable, requestComplete, dataOut);
	
	parameter MAX_CACHE_LEVELS = 4;
	input clock, reset, enable;
	input [31:0] dataIn;
	output requestComplete;
	output [31:0] dataOut;
	
	initial begin
		static integer HASH = ID * 17;
		static integer numCacheLevels = 4;//3 + (HASH % 3);	// 3-5 cache levels
		integer blockSizes[MAX_CACHE_LEVELS-1:0];
		integer numCacheIndices[MAX_CACHE_LEVELS-1:0];
		integer numAssoIndices[MAX_CACHE_LEVELS-1:0];
		integer cacheSizes[MAX_CACHE_LEVELS-1:0];
		
		blockSizes[0] = 64;
		// calculate cache size-related parameters
		for (integer i = 0; i < numCacheLevels; i++) begin
			// calculate block sizes
			if (i != 0) begin
				blockSizes[i] = blockSizes[i-1] * ((2*((HASH/(10*i)) % 2)) + 2);	// lower cache block size is 2/4 times bigger than one above
			end 

			// calculate number of cache indices for each levels
			numCacheIndices[i] = (((HASH/(10**i))%10) % 8) + 1;
			if (numCacheIndices[i] > 4) begin
				numAssoIndices[i] = (((3*HASH/(10**i))%10) % 2) + 1;
			end else if (numCacheIndices[i] > 2) begin
				numAssoIndices[i] = (((5*HASH/(10**i))%10) % 4) + 1;
			end else begin
				numAssoIndices[i] = (((7*HASH/(10**i))%10) % 8) + 1;
			end
			
			// calculate cache sizes
			cacheSizes[i] = blockSizes[i] * numCacheIndices[i] * numAssoIndices[i];
		end
	end
endmodule 

module userIO_testbench();
	reg clock, reset, enable;
	reg [31:0] dataIn;
	wire requestComplete;
	wire [31:0] dataOut;
	
	userIO #(.ID(1130291)) cacheSystem (clock, reset, dataIn, enable, requestComplete, dataOut);
	
	initial begin
		#20;
		$stop;
	end
endmodule 