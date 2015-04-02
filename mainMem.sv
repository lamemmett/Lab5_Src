`protect
module mainMem #(parameter LENGTH=1024, BLOCK_SIZE=8, DELAY=50) (data_out, data_in, addr, we, clk);
	parameter ADDR_LENGTH = $clog2(LENGTH);
	parameter COUNTER_SIZE = $clog2(DELAY);
	
	output reg [(BLOCK_SIZE-1):0] data_out;
	input [(BLOCK_SIZE-1):0] data_in;
	input [(ADDR_LENGTH-1):0] addr;
	input we, clk;
	reg [(BLOCK_SIZE-1):0] mem [(LENGTH-1):0];
	
	reg [COUNTER_SIZE-1:0] counter = 0;
	reg requestComplete = 0;
	
	// reset counter and request status when new address is accessed
	always @(addr) begin
		counter = 0;
		requestComplete = 0;
	end
	
	// increment counter per clock cycle until delay is reached
	always @(posedge clk) begin
		counter++;
		if (counter == (DELAY-1)) begin
			requestComplete = 1;
			counter = 0; end
	end
	
	// return data out value once delay has been reached
	always @(posedge requestComplete) begin
		data_out = mem[addr];
		if (we)
			mem[addr] <= data_in;
	end
	
	initial begin
		// initialize each memory location to its index
		integer i;
		for (i=0; i<LENGTH; i++) begin
			mem[i] = i;
		end
	end
endmodule
`endprotect

module mainMem_testbench();
	wire [7:0] data_out;
	reg [7:0] data_in;
	reg [8:0] addr;
	reg we, clk;
	parameter t = 10;
	parameter d = 70;
	
	mainMem #(.LENGTH(512), .BLOCK_SIZE(), .DELAY(d)) test (.data_out, .data_in, .addr, .we, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		clk = 0;
		data_in = 8'b0;
		addr = 10;
		we = 0;
		#(d*t);
		assert (data_out == 10);	// access index 10, value should appear 5 cycles later
		
		addr = 50;
		#(d*t);
		assert (data_out == 50);	// access index 50, value should appear 5 cycles later
		
		#(100*t);
		$stop;
	end
endmodule 