
module userIO();
	
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
	reg [14:0] addr;
	wire requestComplete;
	wire [31:0] dataOut;
	
	/* create clock */
	parameter t = 10;
	always #(t/2) clock = ~clock;
	
	/* cache system with user ID (ENTER YOUR ID) */
	cacheSystem #(.ID(1234567)) myCache (clock, reset, addr, enable, requestComplete, dataOut);
	
	/* integers for information that needs to be found */
	int L1delay = 0, L1size = 0, L1indices = 0, L1blockSize = 0, L1associativity = 0;
	int L2delay = 0, L2size = 0, L2indices = 0, L2blockSize = 0, L2associativity = 0;
	int L3delay = 0, L3size = 0, L3indices = 0, L3blockSize = 0, L3associativity = 0;
	int MEMdelay = 0;
	
	/* other integers */
	int TOTALdelay = 0;
	
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
		
		/* Write Your Testbench */
		
		
		
		
		
		
		
		
		
		/* Display Answers */
		
		$write("L1 DELAY: "); $write(L1delay); $display(" CLOCK CYCLE(S)");
		$write("L1 BLOCK SIZE: "); $write(L1blockSize); $display(" BITS");
		$write("L1 SIZE: "); $write(L1size); $display(" BITS");
		$write("L1 INDICIES: "); $write(L1indices); $display("");
		$write("L1 ASSOCIATIVITY: "); $display(L1associativity);
		
		$display(" ");
		
		$write("L2 DELAY: "); $write(L2delay); $display(" CLOCK CYCLE(S)");
		$write("L2 BLOCK SIZE: "); $write(L2blockSize); $display(" BITS");
		$write("L2 SIZE: "); $write(L2size); $display(" BITS");
		$write("L2 INDICIES: "); $write(L2indices); $display("");
		$write("L2 ASSOCIATIVITY: "); $display(L2associativity);
		
		$display(" ");
		
		$write("L3 DELAY: "); $write(L3delay); $display(" CLOCK CYCLE(S)");
		$write("L3 BLOCK SIZE: "); $write(L3blockSize); $display(" BITS");
		$write("L3 SIZE: "); $write(L3size); $display(" BITS");
		$write("L3 INDICIES: "); $write(L3indices); $display("");
		$write("L3 ASSOCIATIVITY: "); $display(L3associativity);
		
		$display(" ");
		
		$write("MEM DELAY: "); $write(MEMdelay); $display(" CLOCK CYCLE(S)");
		$stop;
	end
endmodule 