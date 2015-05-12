`protect
module mainMem #(parameter LENGTH=1024, BLOCK_SIZE=32, MEM_DELAY=0) (data_out, done, data_in, addr, we, enable, clk);
	parameter ADDR_LENGTH = $clog2(LENGTH);
	parameter COUNTER_SIZE = $clog2(MEM_DELAY);
	
	output reg [(BLOCK_SIZE-1):0] data_out;
	output reg done;
	
	input [(BLOCK_SIZE-1):0] data_in;
	input [(ADDR_LENGTH-1):0] addr;
	input we, enable, clk;
	
	// state-holding memory
	reg [(BLOCK_SIZE-1):0] mem [(LENGTH-1):0];
	// counter to track delay
	reg [COUNTER_SIZE-1:0] counter = 0;
	
	parameter [1:0] IDLE = 2'b00, DELAY = 2'b01, READ = 2'b10;
	reg [1:0] state = IDLE;
	
	always @(*) begin
		// state logic
		case (state)
				IDLE:		begin
								if (enable)
									if (MEM_DELAY == 0)
										state = READ;
									else
										state = DELAY;
								else
									state = IDLE;
							end
				DELAY:	begin
								if (counter >= MEM_DELAY)
									state = READ;
								else
									state = DELAY;
							end
				READ: 	begin
								if (done)
									state = IDLE;
								else
									state = READ;
							end
			endcase
	end
	
	// always check for instant reads
	always @(*) begin
		if (state == READ) begin
			data_out = mem[addr];
			if (we) begin
				mem[addr] = data_in; end
			done = 1;
		end
	end
	
	// output logic
	always @(posedge clk) begin
		case (state)
			IDLE:		begin
							counter = 0;
							done = 0;
						end
			DELAY:	begin
							counter <= counter + 1;
						end
		endcase
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
	wire done;
	reg [31:0] data_in;
	reg [8:0] addr;
	reg we, enable, clk;
	parameter t = 10;
	parameter d = 70;
	
	mainMem #(.LENGTH(512), .BLOCK_SIZE(), .MEM_DELAY(d)) test (.data_out, .done, .data_in, .addr, .we, .enable, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		clk = 0;
		data_in = 31'b0;
		addr = 10;
		we = 0;
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