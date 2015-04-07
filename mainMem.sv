`protect
module mainMem #(parameter LENGTH=1024, BLOCK_SIZE=32, DELAY=50) (data_out, requestComplete, data_in, addr, we, enable, clk);
	parameter ADDR_LENGTH = $clog2(LENGTH);
	parameter COUNTER_SIZE = $clog2(DELAY);
	
	output reg [(BLOCK_SIZE-1):0] data_out;
	output reg requestComplete = 0;
	
	input [(BLOCK_SIZE-1):0] data_in;
	input [(ADDR_LENGTH-1):0] addr;
	input we, enable, clk;
	
	// state-holding memory
	reg [(BLOCK_SIZE-1):0] mem [(LENGTH-1):0];
	// counter to track delay
	reg [COUNTER_SIZE-1:0] counter = 1;
	
	// reset counter and request status when new address is accessed
	always @(posedge enable) begin
		counter = 1;
		requestComplete = 0;
	end
	
	// increment counter per clock cycle until delay is reached
	always @(posedge clk) begin
		if (!requestComplete) begin
			counter++; end
		if (counter == (DELAY)) begin
			requestComplete = 1; end
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
	wire [31:0] data_out;
	wire requestComplete;
	reg [31:0] data_in;
	reg [8:0] addr;
	reg we, enable, clk;
	parameter t = 10;
	parameter d = 70;
	
	mainMem #(.LENGTH(512), .BLOCK_SIZE(), .DELAY(d)) test (.data_out, .requestComplete, .data_in, .addr, .we, .enable, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		clk = 0;
		data_in = 31'b0;
		addr = 10;
		we = 0;
		enable = 1;
		#(d*t);
		enable = 0;
		assert (data_out == 10);	// access index 10, value should appear DELAY cycles later
		
		#t;
		
		addr = 50;
		enable = 1;
		#(d*t);
		assert (data_out == 50);	// access index 50, value should appear DELAY cycles later
		enable = 0;
		
		#t;
		
		addr = 50;
		enable = 1;
		#(d*t);
		assert (data_out == 50);	// access index 50, value should appear DELAY cycles later
		enable = 0;
		
		#(100*t);
		$stop;
	end
endmodule 