module userIO #(parameter ID=1234567)
	(clock, reset, dataIn, enable, requestComplete, dataOut);
	initial begin
		int HASH = ID * 37;
		int numCacheLevels = 3 + (HASH % 3);	// 3-5 cache levels
		int[numCacheLevels] blockSizes;
		int[numCacheLevels] numCacheIndices;
		int[numCacheLevels] numAssoIndices;
		int[numCacheLevels] cacheSizes;
		
		blockSizes[0] = 64;
		// calculate cache size-related parameters
		for (int i = 1; i < numCacheLevels) begin
			// calculate block sizes
			blockSizes[i] = blockSizes[i-1] * ((2*(HASH & i)) + 2);	// lower cache block size is 2/4 times bigger than one above
			
			// calculate number of cache indices for each levels
			numCacheIndices[i] = (HASH % 8) + 1;
			if (numCacheIndices[i] = > 4) begin
				numAssoIndices[i] = (HASH % 2) + 1;
			end else if (numCacheIndices[i] > 2) begin
				numAssoIndices[i] = (HASH % 4) + 1;
			end else begin
				numAssoIndices[i] = (HASH % 8) + 1;
			end
			
			// calculate cache sizes
			cacheSizes[i] = blockSizes[i] * numCacheIndices[i] * numAssoIndices[i];
		end
	end
endmodule 

module userIO_testbench();
	
endmodule 