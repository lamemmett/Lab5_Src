`protect
module mainMem #(parameter LENGTH=1024, BLOCK_SIZE=32, MEM_DELAY=10) (data_out, fetchComplete, data_in, addr, write, enable, clk);
	parameter ADDR_LENGTH = $clog2(LENGTH);
	parameter COUNTER_SIZE = $clog2(MEM_DELAY);
	
	output reg [(BLOCK_SIZE-1):0] data_out;
	output reg fetchComplete;
	reg writeComplete = 0;
	
	input [(BLOCK_SIZE-1):0] data_in;
	input [(ADDR_LENGTH-1):0] addr;
	input write, enable, clk;
	
	// state-holding memory
	reg [(BLOCK_SIZE-1):0] mem [(LENGTH-1):0];
	// counter to track delay
	reg [COUNTER_SIZE-1:0] counter = 0;
	
	parameter [1:0] IDLE = 2'b00, DELAY = 2'b01, READ = 2'b10, WRITE = 2'b11;
	reg [1:0] state = IDLE;
	
	always @(*) begin
		// state logic
		case (state)
				IDLE:		begin
								if(write)
									mem[addr] = data_in;
								if(enable) begin
									if (MEM_DELAY == 0)
										state = READ;
									else
										state = DELAY;
									end
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
								if (fetchComplete)
									state = IDLE;
								else
									state = READ;
							end
				WRITE: 	begin // not used
								if (writeComplete)
									state = IDLE;
								else
									state = WRITE;
							end
			endcase
	end
	
	// always check for instant reads
	always @(*) begin
		if (state == READ) begin
			data_out = mem[addr];
			fetchComplete = 1;
		end
		if (state == WRITE) begin
			mem[addr] = data_in;
			writeComplete = 1;
		end
	end
	
	// output logic
	always @(posedge clk) begin
		case (state)
			IDLE:		begin
							counter <= 0;
							fetchComplete <= 0;
							writeComplete <= 0;
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