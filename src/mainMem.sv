`protect
module mainMem #(parameter SIZE=1024, ADDR_LENGTH=10, MEM_DELAY=10, BLOCK_SIZE=32, RETURN_SIZE=64)
					 (addrIn, 	dataUpOut, 	dataUpIn, 		fetchComplete, enableIn, 	writeCompleteOut, writeIn,
					  clock, reset);
	
	parameter COUNTER_SIZE = $clog2(MEM_DELAY);
	
	// I/O STUFF	------
	input clock, reset;
	
	// UP I/O
	input 		[(ADDR_LENGTH-1):0] 	addrIn;
	output reg 	[(RETURN_SIZE-1):0] 	dataUpOut;
	input 		[(RETURN_SIZE-1):0] 	dataUpIn;
	output reg								fetchComplete;
	input 									enableIn;
	output reg 								writeCompleteOut;
	input										writeIn;
	
	// Counters and flags
	reg [COUNTER_SIZE-1:0] counter = 0;
	reg startCounter = 0;
	integer numReads = RETURN_SIZE / 2;
	wire			[(ADDR_LENGTH-1):0] 	baseAddr = addrIn / (RETURN_SIZE / 32) * 2;
	
	// MEM CONTENTS
	reg [(BLOCK_SIZE-1):0] mem [(SIZE-1):0];
	
	// Asynchronous output logic
	always @(*) begin
		if (~enableIn) begin
			dataUpOut = 'x;
			fetchComplete = 0;
			writeCompleteOut = 0;
			counter = 0;
			startCounter = 0;
		end
		else if (enableIn) begin
			startCounter = 1;
			if (counter >= MEM_DELAY) begin
				startCounter = 0;
				if (writeIn) begin
					mem[addrIn] = dataUpIn;
					writeCompleteOut = 1;
				end
				else begin
					for (integer i=0; i<numReads; i++) begin
						dataUpOut[i*BLOCK_SIZE +: BLOCK_SIZE] = mem[baseAddr + i];
					end
					fetchComplete = 1;
				end
			end
		end
	end

	// Counter increment
	always @(posedge clock) begin
		if (startCounter) begin
			counter <= counter + 1;
		end
	end
	
	// initialize each memory location to its index
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