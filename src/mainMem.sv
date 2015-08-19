/* This is the main memory module. It models a variable size direct mapped main
   memory. This module is used in conjunction with the cache module to simulate
   a multi layer memory structure.
   
    PARAMETERS:
        SIZE: determines the number of cache indices
		ADDR_LENGTH: number of bits required to address memory
		MEM_DELAY: delay experienced when accessing main memory
		BLOCK_SIZE: number of bits in an individual block in memory
			*REQUIREMENTS
				BLOCK_SIZE can not be the same as the RETURN_SIZE, it must be
				larger by a factor of 2.
		RETURN_SIZE: number of bits returned up to higher cache
			*REQUIREMENTS:
				RETURN_SIZE can not be the same as the BLOCK_SIZE, it must be
				smaller by a factor of 2.
	
	I/O: 
		addrIn: address selected for cache operation
		dataUpOut: data output to the cache above
		dataUpIn: data input from the cache above
		fetchComplete: signal that outputs when a fetch operation finishes
		    (1 = fetch finished)
		enableIn: signal that starts this module
			(1 = enabled, else disabled)
		writeCompleteOut: signals that outputs when a write operation finishes
		    (1 = write finished)
		writeIn: signal that determines whether the cache is writing or reading
		    (1 = write, else read)
		clock: system clock
		reset: resets cache system (1 = reset)
		
 */
`protect
module mainMem #(parameter SIZE=1024, ADDR_LENGTH=10, MEM_DELAY=10, BLOCK_SIZE=32, RETURN_SIZE=64)
					 (addrIn, 	dataUpOut, 	dataUpIn, 		fetchComplete, enableIn, 	writeCompleteOut, writeIn,
					  clock, reset);
	
	/* size of the counter used to count to delay */
	parameter COUNTER_SIZE = $clog2(MEM_DELAY);
	
	/* number of bits needed to address the main memory's entire index */
	parameter SELECT_SIZE = $clog2(RETURN_SIZE/32);
	
	/* I/O STUFF */
	input clock, reset;
	
	input 		[(ADDR_LENGTH-1):0] 	addrIn;
	output reg 	[(RETURN_SIZE-1):0] 	dataUpOut;
	input 		[(RETURN_SIZE-1):0] 	dataUpIn;
	output reg							fetchComplete;
	input 								enableIn;
	output reg 							writeCompleteOut;
	input								writeIn;
	
	/* Counters, Flags, Etc
		
		counter: counter which counter the main memory's delay
		startCounter: flag that indicates whether to startCounter
			(1 = start)
		
		numReader: integer used to track the number of reads done. Used in a
			for loop to return data in multiple memory spots.
		
		zeros: filler zeros used in baseAddr, length determined by SELECT_SIZE
		baseAddr: the first address in main memory
		
		mem = registers where data is stored in main memory
	 */
	reg [COUNTER_SIZE:0] counter = 0;
	reg startCounter = 0;
	
	integer numReads = RETURN_SIZE / 2;
	wire 			[(SELECT_SIZE-1):0]		zeroes = 0;
	wire			[(ADDR_LENGTH-1):0] 	baseAddr = {addrIn[(ADDR_LENGTH-1):SELECT_SIZE], zeroes};
	
	reg [(BLOCK_SIZE-1):0] mem [(SIZE-1):0];
	
	/* Asynchronous output logic */
	always @(*) begin
		/*  */
		dataUpOut = dataUpOut;
		fetchComplete = fetchComplete;
		writeCompleteOut = writeCompleteOut;
		startCounter = startCounter;
		mem = mem;
		
		/* If the main memory module isn't enabled, reset I/O, counters, flags,
		   etc. */
		if (~enableIn) begin
			dataUpOut = 'x;
			fetchComplete = 0;
			writeCompleteOut = 0;
			counter = 0;
			startCounter = 0;
		end
		
		/* If main memory is enabled, start the counter. */
		else if (enableIn) begin
			startCounter = 1;
			
			/* main memory delay has occurred, so stop the counter. */
			if (counter >= MEM_DELAY) begin
				startCounter = 0;
				
				/* preforming a write operation */
				if (writeIn) begin
				
					/* write data in into the appropriate location and signal a
					writeCompleteOut */
					mem[addrIn] = dataUpIn;
					writeCompleteOut = 1;
				end
				
				/* preforming a read operation */
				else begin
					/* find data, output it, and signal a fetchComplete */
					for (integer i=0; i<numReads; i++) begin
						dataUpOut[i*BLOCK_SIZE +: BLOCK_SIZE] = mem[baseAddr + i];
					end
					fetchComplete = 1;
				end
			end
		end
	end

	/* At every posedge if startCounter is true, increment the counter to track
	   main memory delay. If main memory isn't enabled, reset the counter to 0.
	 */
	always @(posedge clock) begin
		if(~enableIn)
			counter <= 0;
		else if (startCounter) begin
			counter <= counter + 1;
		end
	end
	
	/* initialize each memory location to its index */
	initial begin
		integer i;
		for (i=0; i<SIZE; i++) begin
			mem[i] = i;
		end
	end
endmodule
`endprotect

module mainMem_testbench();
	wire [31:0] dataUpOut;
	wire fetchComplete, writeCompleteOut;
	reg [31:0] dataUpIn;
	reg [9:0] addrIn;
	reg writeIn, enableIn, clock, reset;
	parameter t = 10;
	parameter d = 50;
	
	mainMem test (.addrIn,	.dataUpOut, 	.dataUpIn, 	.fetchComplete, .enableIn, .writeCompleteOut, .writeIn,
					  .clock, 	.reset);
	
	always #(t/2) clock = ~clock;
	
	initial begin
		clock = 0;
		dataUpIn = 31'b0;
		
		// Read tests
		addrIn = 10;
		writeIn = 0;
		enableIn = 1;
		#(d*t);
		enableIn = 0;
		assert (dataUpOut == 10);	// access index 10, value should appear MEM_DELAY cycles later
		
		#t;
		
		addrIn = 50;
		enableIn = 1;
		#(d*t);
		assert (dataUpOut == 50);	// access index 50, value should appear MEM_DELAY cycles later
		enableIn = 0;
		
		#t;
		
		addrIn = 50;
		enableIn = 1;
		#(d*t);
		assert (dataUpOut == 50);	// access index 50, value should appear MEM_DELAY cycles later
		enableIn = 0;
		
		#t;
		
		// Write tests
		addrIn = 1;
		writeIn = 1;
		enableIn = 1;
		#(d*t);
		enableIn = 0;
		
		#t;
		$stop;
	end
endmodule 