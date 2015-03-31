module mainMem #(parameter LENGTH=1024, WIDTH=8, DELAY=50) (data_out, data_in, addr, we, clk);
	parameter ADDR_LENGTH = $clog2(LENGTH);
	
	output reg [(WIDTH-1):0] data_out;
	input      [(WIDTH-1):0] data_in;
	input      [(ADDR_LENGTH-1):0] addr;
	input            we, clk;
	reg        [(WIDTH-1):0] mem       [(LENGTH-1):0];
	
	reg [99:0] counter = 0;
	reg requestComplete = 0;
	always @(posedge clk) begin
		counter++;
		if (counter == (DELAY-1)) begin
			requestComplete = 1;
			counter = 0; end
		else
			requestComplete = 0;
	end
	
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

module mainMem_testbench();
	wire 		[5:0] data_out;
	reg      [5:0] data_in;
	reg      [8:0] addr;
	reg            we, clk;
	parameter t = 10;
	
	mainMem #(.LENGTH(512), .WIDTH(6), .DELAY(50)) test (.data_out, .data_in, .addr, .we, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		clk = 0;
		data_in = 6'b0;
		addr = 10;
		we = 0;
		#(50*t);
		assert (data_out == 10);	// access index 10, value should appear 5 cycles later
		
		addr = 50;
		#(50*t);
		assert (data_out == 50);	// access index 50, value should appear 5 cycles later
		
		#(100*t);
		$stop;
	end
endmodule 