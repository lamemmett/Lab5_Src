`protect
module mainMem #(parameter LENGTH=1024, BLOCK_SIZE=32, MEM_DELAY=0) (data_out, fetchComplete, data_in, addr, write, enable, clk);
	parameter ADDR_LENGTH = $clog2(LENGTH);
	parameter COUNTER_SIZE = $clog2(MEM_DELAY);
	
	output reg [(BLOCK_SIZE-1):0] data_out;
	output reg fetchComplete;
	
	input [(BLOCK_SIZE-1):0] data_in;
	input [(ADDR_LENGTH-1):0] addr;
	input write, enable, clk;
	
	// state-holding memory
	reg [(BLOCK_SIZE-1):0] mem [(LENGTH-1):0];
	// counter to track delay
	reg [COUNTER_SIZE-1:0] counter = 0;
	reg start_counter = 0;
	
	always @(*) begin
		if (~enable) begin
			data_out = 'x;
			fetchComplete = 0;
			counter = 0;
			start_counter = 0;
		end
		// check if data here after timer elapses
		else if (~write) begin
			start_counter = 1;
			if (counter >= MEM_DELAY) begin
				start_counter = 0;
				fetchComplete = 1;
				data_out = mem[addr];
			end
		end
		// write
		else begin
			mem[addr] = data_in;
		end
	end

	// output logic
	always @(posedge clk) begin
		if (start_counter) begin
			counter <= counter + 1;
		end
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
	wire fetchComplete;
	reg [31:0] data_in;
	reg [8:0] addr;
	reg write, enable, clk;
	parameter t = 10;
	parameter d = 70;
	
	mainMem #(.LENGTH(512), .BLOCK_SIZE(), .MEM_DELAY(d)) test (.data_out, .fetchComplete, .data_in, .addr, .write, .enable, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		clk = 0;
		data_in = 31'b0;
		addr = 10;
		write = 0;
		enable = 1;
		#(d*t);
		enable = 0;
		assert (data_out == 10);	// access index 10, value should appear MEM_DELAY cycles later
		
		#t;
		
		addr = 50;
		enable = 1;
		#(d*t);
		assert (data_out == 50);	// access index 50, value should appear MEM_DELAY cycles later
		enable = 0;
		
		#t;
		
		addr = 50;
		enable = 1;
		#(d*t);
		assert (data_out == 50);	// access index 50, value should appear MEM_DELAY cycles later
		enable = 0;
		
		#(100*t);
		$stop;
	end
endmodule 