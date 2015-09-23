module userIO();
	`define READADDR(ADDR) 								\
		addr = ADDR;										\
		enable <= 1;				@(posedge clock);	\
		while (~requestComplete) #t;					\
		enable <= 0;				@(posedge clock);	\
		#t;
		
	`define RESET 											\
		reset = 1; 			@(posedge clock);			\
		reset = 0;			@(posedge clock);			\
		i = 0; temp = 0; j = 0;
	reg clock, reset, enable, write;
	reg [31:0] dataIn;
	reg [15:0] addr;
	wire requestComplete;
	wire [31:0] dataOut;
	parameter t = 10;
	
	cacheSystem #(.ID(1130294)) myCache (clock, reset, addr, enable, write, dataIn, requestComplete, dataOut);
	
	always #(t/2) clock = ~clock;
	
	integer start = 0, lastDelay = 0, temp = 0, i = 0, j = 0, overallDelay = 0;
	integer L1delay = 0, L1blockSize = 0, L1associativity = 0, L1size = 0;
	integer L2delay = 0, L2blockSize = 0, L2associativity = 0, L2size = 0;
	integer L3delay = 0, L3blockSize = 0, L3associativity = 0, L3size = 0;
	
	// -- UTILITIES --
	// Log start and stop times on console
	always @(posedge enable) begin
		start <= $time;				@(posedge clock);
	end
	// display and save delay of last operation
	always @(posedge requestComplete) begin
		lastDelay = ($time-start)/t;
		if (lastDelay > L2delay + L1delay && lastDelay < overallDelay)
					L3delay = lastDelay - L2delay - L1delay;
		//$write("Delay of last operation: "); $display(lastDelay);
	end
	
	// BEGIN TESTS
	initial begin
		// Reset and initialize cache
		enable = 0;
		dataIn = 0;
		clock = 0;
		write = 0;
		addr = 0;
		reset = 1;
		#(2*t);
		reset <= 0;		@(posedge clock);
		
		// read address 0, loads into all caches
		`READADDR(0);
		overallDelay = lastDelay;
		
		// read address 0 again, the delay time of this operation is the L1 cache delay
		`READADDR(0);
		L1delay = lastDelay;
		
		// Solve all delays
		while (lastDelay == L1delay) begin
			i++;
			`READADDR(i);
		end	L1blockSize = i*32; i = 1;
		L2delay = lastDelay - L1delay;
		
		// Solve L1 size
		do begin
			i++; j = 0;
			for (temp = 0; temp < i; temp++) begin
				`READADDR(j*L1blockSize/32);
				j++;
			end
			`READADDR(0);
		end while (lastDelay <= L1delay);		// if mem(0) has been evicted, you've exceeded L1 capacity
		L1size = (i-1) * L1blockSize;
		
		`RESET;
		
		// Solve L1 associativity
		do begin
			i++; j = 0;
			for (temp = 0; temp < i; temp++) begin
				`READADDR(j*(L1size/32));
				j++;
			end
			`READADDR(0);
		end while (lastDelay <= L1delay);
		L1associativity = j - 1;
		
		`RESET;
		
		`READADDR(0);
		
		// Solve L2 and L3 block sizes
		do begin
			i++;
			`READADDR(i);
			if (lastDelay > (L1delay + L2delay) && L2blockSize == 0)
				L2blockSize = i * 32;
		end while (lastDelay < overallDelay);
		L3blockSize = i * 32;
		
		`RESET;
		
		// Solve L2 size
		do begin
			i++; j = 0;
			for (temp = 0; temp < i; temp++) begin
				`READADDR(j*L2blockSize/32);
				j++;
			end
			`READADDR(0);
		end while (lastDelay <= L1delay + L2delay);		// if mem(0) has been evicted, you've exceeded L2 capacity
		L2size = (i-1) * L2blockSize;
		
		`RESET;
		
		// Solve L2 associativity
		do begin
			i++; j = 0;
			for (temp = 0; temp < i; temp++) begin
				`READADDR(j*(L2size/32));
				j++;
			end
			`READADDR(0);
		end while (lastDelay <= L1delay + L2delay);
		L2associativity = j - 1;
		
		`RESET;
		
		// Solve L3 size
		do begin
			i++; j = 0;
			for (temp = 0; temp < i; temp++) begin
				`READADDR(j*L3blockSize/32);
				j++;
			end
			`READADDR(0);
		end while (lastDelay < overallDelay);		// if mem(0) has been evicted, you've exceeded L2 capacity
		L3size = (i-1) * L3blockSize;
		
		`RESET;
		
		// Solve L3 associativity
		do begin
			i++; j = 0;
			for (temp = 0; temp < i; temp++) begin
				`READADDR(j*(L3size/32));
				j++;
			end
			`READADDR(0);
		end while (lastDelay < overallDelay);
		L3associativity = j - 1;
		
		$write("L1 DELAY: "); $write(L1delay); $display(" CLOCK CYCLE(S)");
		$write("L1 BLOCK SIZE: "); $write(L1blockSize); $display(" BITS");
		$write("L1 SIZE: "); $write(L1size); $display(" BITS");
		$write("L1 ASSOCIATIVITY: "); $display(L1associativity);
		
		$display(" ");
		
		$write("L2 DELAY: "); $write(L2delay); $display(" CLOCK CYCLE(S)");
		$write("L2 BLOCK SIZE: "); $write(L2blockSize); $display(" BITS");
		$write("L2 SIZE: "); $write(L2size); $display(" BITS");
		$write("L2 ASSOCIATIVITY: "); $display(L2associativity);
		
		$display(" ");
		
		$write("L3 DELAY: "); $write(L3delay); $display(" CLOCK CYCLE(S)");
		$write("L3 BLOCK SIZE: "); $write(L3blockSize); $display(" BITS");
		$write("L3 SIZE: "); $write(L3size); $display(" BITS");
		$write("L3 ASSOCIATIVITY: "); $display(L3associativity);
		
		$display(" ");
		
		$write("MEM DELAY: "); $write(overallDelay  - L3delay - L2delay - L1delay); $display(" CLOCK CYCLE(S)");
		$stop;
	end

endmodule 