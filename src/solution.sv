module solution #(parameter ID = 1234567) ();
`protect
	
	/* macros for convenience and clarity
		Access accesses, reading & waiting for the requestComplete
		Reset resets, emptying the cache
	 */
	 
	`define ACCESS(ADDR, DELAY)												\
		addr <= ADDR;	enable <= 1;					@(posedge clock);	\
		while (~requestComplete && DELAY < 10000) begin						\
			DELAY <= DELAY + 1;							@(posedge clock);	\
			if(requestComplete) break;										\
		end																	\
		enable <= 0;									@(posedge clock);	\
		if (DELAY >= 10000) begin											\
			$display(" ");													\
			$write("ACCESS ERROR");											\
			$display(" ");													\
		end
		
	`define RESET 															\
		reset <= 1; 									@(posedge clock);	\
		reset <= 0;										@(posedge clock);
	
	/* parameters */
	reg clock, reset, enable;
	reg [15:0] addr;
	wire requestComplete;
	wire [31:0] dataOut;
	
	/* create clock */
	parameter t = 10;
	always #(t/2) clock = ~clock;
	
	/* cache system with user ID */
	cacheSystem #(.ID(ID)) myCache (clock, reset, addr, enable, requestComplete, dataOut);
	
	/* integers for information that needs to be found */
	int L1delay = 0, L1size = 0, L1indices = 0, L1blockSize = 0, L1associativity = 0;
	int L2delay = 0, L2size = 0, L2indices = 0, L2blockSize = 0, L2associativity = 0;
	int L3delay = 0, L3size = 0, L3indices = 0, L3blockSize = 0, L3associativity = 0;
	int MEMdelay = 0;
	
	/* other integers 
	
	   TOTALdelay : tracks the total delay of the system (self explanatory)
	   CHECKdelay : used to hold delay when checking if data has been evicted
	   TEMPdelay : holds delay
	   onetime: used to preform a block of code only once through a loop
	   i : used in for loops
	   j : used in for loops
	   L1spots : (L1size / 32) How many data loctions are in cache.
	   L2spots : (L2size / 32)
	   L3spots : (L3size / 32)
	   increment : variable used to increment various cache block sizes
	
	 */
	int TOTALdelay = 0;
	int CHECKdelay = 0;
	int TEMPdelay = 0;
	int onetime = 0;
	int i = 0;
	int j = 0;
	int L1spots = 0;
	int L2spots = 0;
	int L3spots = 0;
	int increment = 0;
	
	/* preform tests */
	initial begin
	
		/* First initialize inputs and reset the cache system so that all of
		   the caches are empty. */
		enable <= 0; clock <= 0; addr <= 0;
		`RESET;
		
		/* Preform a read operation on address 0, because the caches are empty,
		   all caches will experience a cold start miss and the total delay of
		   the system will be returned. */
		`ACCESS(0, TOTALdelay);
		
		/* Similarily preform another read operation on the same address; data
		   should now be in the L1 cache. This will give the L1 delay. */
		`ACCESS(0, L1delay);
		
//		$write("=== L1 ANALYSIS ==="); $display("");
//		$write("L1 INDICIES: "); $write(0); $display("");
//		$write("L2 DELAY: "); $write(TOTALdelay); $display("");
		
		/* onetime is used to ensure that a block of code only runs the first
		   time through the do-while loop. increment is simply the increment at
		   which address locations are read. */
		onetime = 1;
		increment = 1;
		
		do begin
		
			/* This do-while loop repeats until a new block is read to the L1
			   cache. When a new block is read in the delay is such that this
			   loop is left. The if statement after this loop then records
			   the L2 delay, which will be determined by the delay of reading
			   in a new block. The block size is also recorded, along with the
			   increment value needed to read in a new block, rather then 
			   preform multiple reads on a single block. */
			do begin
				L1spots = L1spots + increment;
//				$write("L1 INDICIES: "); $write(L1spots); $display("");
				TEMPdelay = 0;
				`ACCESS(L1spots, TEMPdelay);
//				$write("L1 DELAY: "); $write(TEMPdelay); $display("");
			end while (TEMPdelay == L1delay);
			
			/* This occurs only once through the loop. */
			if(onetime) begin
				L2delay = TEMPdelay - L1delay;
				L1blockSize = L1spots * 32;
				increment = L1spots;
			end
			onetime = 0;
			
			/* Here previous locations in the cache are checked. If one was
			   evicted, it signals that the cache has experienced a capacity
			   miss. The size of the cache is also now known. */
			for(i = 0; i <= L1spots ; i = i + increment) begin
				CHECKdelay = 0;
//				$write("CHECK INDICIES: "); $write(i); $display("");
				`ACCESS(i, CHECKdelay);
				
//				$write("CHECK DELAY: "); $write(CHECKdelay); $display("");
				if(CHECKdelay != L1delay) break;
			end
		end while(CHECKdelay == L1delay);
		L1size = L1spots * 32;
		
		/* Reset the cache before finding cache indicies */
//		$write("ASSOCIATIVITY/INDICIES"); $display("");
		`RESET;
//		$write("RESET"); $display("");
		
		/* First loop though and fill the L1 cache. Access location in
		   multiples of L1's block size. */
		for(i = 0; i < L1size / 32; i = i + L1blockSize / 32) begin
			TEMPdelay = 0;
//			$write("INDICIES: "); $write(i); $display("");
			`ACCESS(i, TEMPdelay);
//			$write("DELAY: "); $write(TEMPdelay); $display("");
		end
		
		/* Now access the data adress equal to twice the number of spots 
		   (size / 32) in L1 minus the number of spots in a block of L1
		   (blocksize / 32). If the cache is fully associative, data in the
		   first index and that index's first associativity spot will be
		   replaced (0). If the cache is 2 way associative, data in the second
		   index and that index's first associativity spot will be replaced. 
		   Following the pattern, if the cache is n way associative, data in
		   the n-th index and that index's first associativty spot will be
		   replaced. */
		TEMPdelay = 0;
//		$write("INDICIES: "); $write(L1size / 32 * 2 - L1blockSize/32); $display("");
		`ACCESS(L1size / 32 * 2 - L1blockSize/32, TEMPdelay);
//		$write("DELAY: "); $write(TEMPdelay); $display("");
		
		/* Now Access locations , to find which data is missing. Since the
		   the cache was filled in order, the data missing will tell which
		   index has data replaced in the access above. Using indicies, size,
		   and block size, associativity can now be calculatied.*/
		i = 0;
		j = 0;
		do begin
			CHECKdelay = 0;
//			$write("CHECK: "); $write(j); $display("");
			`ACCESS(j, CHECKdelay);
//			$write("DELAY: "); $write(CHECKdelay); $display("");
			if(j == 2 ** i * L1blockSize / 32 - L1blockSize / 32) begin
				i = i + 1;
			end
			
			j = j + L1blockSize / 32;
		end while (CHECKdelay == L1delay);
		L1indices = 2 ** (i - 1);
		L1associativity = L1size / L1blockSize / L1indices;
				
		/* Alternative method to find associativity of L1; it's slower and hard
           to scale up for other cache levels. */
//		$write("ASSOCIATIVITY/INDICIES"); $display("");
//		`ACCESS(0, CHECKdelay);		
//		L1associativity = 0;
//		do begin
//			CHECKdelay = 0;
//			L1associativity = L1associativity + 1;
//			for(i = L1associativity; i > 0; i = i - 1) begin
//				TEMPdelay = 0;
//				`ACCESS(i * L1spots, TEMPdelay);
//			end
//			`ACCESS(0, CHECKdelay);
//		end while(CHECKdelay == L1delay);
//		L1indices = L1size / L1blockSize / L1associativity;
		
		/* Reset cache and now begin identifying L2 properties */
//		$write("=== L2 ANALYSIS ==="); $display("");
		`RESET;
//		$write("RESET"); $display("");
		
//		$write("L2 INDICIES: "); $write(0); $display("");
		TEMPdelay = 0;
		`ACCESS(0, TEMPdelay);
//		$write("L2 DELAY: "); $write(TEMPdelay); $display("");
		
		/* Here L2's block size, L2's size, and L3 delay are found using the
		   same structure of loops as previously done for L1. */
		onetime = 1;
		do begin
			do begin
				L2spots = L2spots + increment;
//				$write("L2 INDICIES: "); $write(L2spots); $display("");
				TEMPdelay = 0;
				`ACCESS(L2spots, TEMPdelay);
//				$write("L2 DELAY: "); $write(TEMPdelay); $display("");
			end while (TEMPdelay <= L2delay + L1delay);
			if(onetime) begin
				L3delay = TEMPdelay - L2delay - L1delay;
				L2blockSize = L2spots * 32;
				increment = L2spots;
			end
			onetime = 0;
			for(i = 0; i <= L2spots ; i = i + increment) begin
				CHECKdelay = 0;
//				$write("CHECK INDICIES: "); $write(i); $display("");
				`ACCESS(i, CHECKdelay);
//				$write("CHECK DELAY: "); $write(CHECKdelay); $display("");
				if(CHECKdelay > L2delay + L1delay) break;
			end
		end while(CHECKdelay <= L2delay + L1delay);
		L2size = L2spots * 32;
		
		/* Reset the cache before finding cache indicies */
//		$write("ASSOCIATIVITY/INDICIES"); $display("");
		`RESET;
//		$write("RESET"); $display("");
		
		/* First loop though and fill the L2 cache. Access location in
		   multiples of L1's block size to ensure that the 0th spot is evicted
		   from L1. */
		for(i = 0; i < L2size / 32; i = i + L1blockSize / 32) begin
			TEMPdelay = 0;
//			$write("INDICIES: "); $write(i); $display("");
			`ACCESS(i, TEMPdelay);
//			$write("DELAY: "); $write(TEMPdelay); $display("");
		end
		
		/* Now access the data adress equal to twice the number of spots 
		   (size / 32) in L2 minus the number of spots in a block of L2
		   (blocksize / 32). If the cache is fully associative, data in the
		   first index and that index's first associativity spot will be
		   replaced (0). If the cache is 2 way associative, data in the second
		   index and that index's first associativity spot will be replaced. 
		   Following the pattern, if the cache is n way associative, data in
		   the n-th index and that index's first associativty spot will be
		   replaced. */
		TEMPdelay = 0;
//		$write("INDICIES: "); $write(L2size / 32 * 2 - L2blockSize/32); $display("");
		`ACCESS(L2size / 32 * 2 - L2blockSize/32, TEMPdelay);
//		$write("DELAY: "); $write(TEMPdelay); $display("");
		
		
		/* Now Access locations , to find which data is missing. Since the
		   the cache was filled in order, the data missing will tell which
		   index has data replaced in the access above. Using indicies, size,
		   and block size, associativity can now be calculatied.*/
		i = 0;
		j = 0;
		do begin
			CHECKdelay = 0;
//			$write("CHECK: "); $write(j); $display("");
			`ACCESS(j, CHECKdelay);
//			$write("DELAY: "); $write(CHECKdelay); $display("");
			if(j == 2 ** i * L2blockSize / 32 - L2blockSize / 32) begin
				i = i + 1;
			end
			
			/* Access locations in multiples determined by L1s block size to
			   ensure that the data is evicted from L1 as well. */
			j = j + L1blockSize / 32;
		end while (CHECKdelay <= L2delay + L1delay);
		L2indices = 2 ** (i - 1);
		L2associativity = L2size / L2blockSize / L2indices;
		
		/* Reset cache and now begin identifying L3 properties */
//		$write("=== L3 ANALYSIS ==="); $display("");
		`RESET;
//		$write("RESET"); $display("");
		
//		$write("L3 INDICIES: "); $write(0); $display("");
		TEMPdelay = 0;
		`ACCESS(0, TEMPdelay);
//		$write("L3 DELAY: "); $write(TEMPdelay); $display("");
		
		/* Here L3's block size, L3's size, and MEM delay are found using the
		   same structure of loops as previously done for L1. */
		onetime = 1;
		do begin
			do begin
				L3spots = L3spots + increment;
//				$write("L3 INDICIES: "); $write(L3spots); $display("");
				TEMPdelay = 0;
				`ACCESS(L3spots, TEMPdelay);
//				$write("L3 DELAY: "); $write(TEMPdelay); $display("");
			end while (TEMPdelay <= L3delay + L2delay + L1delay);
			if(onetime) begin
				MEMdelay = TEMPdelay - L3delay - L2delay - L1delay;
				L3blockSize = L3spots * 32;
				increment = L3spots;
			end
			onetime = 0;
			for(i = 0; i <= L3spots ; i = i + increment) begin
				CHECKdelay = 0;
//				$write("CHECK INDICIES: "); $write(i); $display("");
				`ACCESS(i, CHECKdelay);
//				$write("CHECK DELAY: "); $write(CHECKdelay); $display("");
				if(CHECKdelay > L3delay + L2delay + L1delay) break;
			end
		end while(CHECKdelay <= L3delay + L2delay + L1delay);
		L3size = L3spots * 32;
		
		/* Reset the cache before finding cache indicies */
//		$write("ASSOCIATIVITY/INDICIES"); $display("");
		`RESET;
//		$write("RESET"); $display("");
		
		/* First loop though and fill the L3 cache. Access location in
		   multiples of L1's block size to ensure that the 0th spot is evicted
		   from L1 and L2. */
		for(i = 0; i < L3size / 32; i = i + L1blockSize / 32) begin
			TEMPdelay = 0;
//			$write("INDICIES: "); $write(i); $display("");
			`ACCESS(i, TEMPdelay);
//			$write("DELAY: "); $write(TEMPdelay); $display("");
		end
		
		/* Now access the data adress equal to twice the number of spots 
		   (size / 32) in L3 minus the number of spots in a block of L3
		   (blocksize / 32). If the cache is fully associative, data in the
		   first index and that index's first associativity spot will be
		   replaced (0). If the cache is 2 way associative, data in the second
		   index and that index's first associativity spot will be replaced. 
		   Following the pattern, if the cache is n way associative, data in
		   the n-th index and that index's first associativty spot will be
		   replaced. */
		TEMPdelay = 0;
//		$write("INDICIES: "); $write(L3size / 32 * 2 - L3blockSize/32); $display("");
		`ACCESS(L3size / 32 * 2 - L3blockSize/32, TEMPdelay);
//		$write("DELAY: "); $write(TEMPdelay); $display("");
		
		
		/* Now Access locations , to find which data is missing. Since the
		   the cache was filled in order, the data missing will tell which
		   index has data replaced in the access above. Using indicies, size,
		   and block size, associativity can now be calculatied.*/
		i = 0;
		j = 0;
		do begin
			CHECKdelay = 0;
//			$write("CHECK: "); $write(j); $display("");
			`ACCESS(j, CHECKdelay);
//			$write("DELAY: "); $write(CHECKdelay); $display("");
			if(j == 2 ** i * L3blockSize / 32 - L3blockSize / 32) begin
				i = i + 1;
			end
			
			/* Access locations in multiples determined by L1s block size to
			   ensure that the data is evicted from L1 and L2 as well. */
			j = j + L1blockSize / 32;
		end while (CHECKdelay <= L3delay + L2delay + L1delay);
		L3indices = 2 ** (i - 1);
		L3associativity = L3size / L3blockSize / L3indices;
				
//		$display(" ");
//		$display(" ");
//		$write(TOTALdelay);
//		$display(" ");
//		$write(TEMPdelay);
		
//		$display(" ");
		
		$write("L1 DELAY: "); $write(L1delay); $display(" CLOCK CYCLE(S)");
		$write("L1 BLOCK SIZE: "); $write(L1blockSize); $display(" BITS");
		$write("L1 SIZE: "); $write(L1size); $display(" BITS");
//		$write("L1 SPOTS: "); $write(L1spots); $display("");
		$write("L1 INDICIES: "); $write(L1indices); $display("");
		$write("L1 ASSOCIATIVITY: "); $display(L1associativity);
		
		$display(" ");
		
		$write("L2 DELAY: "); $write(L2delay); $display(" CLOCK CYCLE(S)");
		$write("L2 BLOCK SIZE: "); $write(L2blockSize); $display(" BITS");
		$write("L2 SIZE: "); $write(L2size); $display(" BITS");
//		$write("L2 SPOTS: "); $write(L2spots); $display("");
		$write("L2 INDICIES: "); $write(L2indices); $display("");
		$write("L2 ASSOCIATIVITY: "); $display(L2associativity);
		
		$display(" ");
		
		$write("L3 DELAY: "); $write(L3delay); $display(" CLOCK CYCLE(S)");
		$write("L3 BLOCK SIZE: "); $write(L3blockSize); $display(" BITS");
		$write("L3 SIZE: "); $write(L3size); $display(" BITS");
//		$write("L3 SPOTS: "); $write(L3spots); $display("");
		$write("L3 INDICIES: "); $write(L3indices); $display("");
		$write("L3 ASSOCIATIVITY: "); $display(L3associativity);
		
		$display(" ");
		
		$write("MEM DELAY: "); $write(MEMdelay); $display(" CLOCK CYCLE(S)");
		$stop;
	end
endmodule
`endprotect