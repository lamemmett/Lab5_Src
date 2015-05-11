`protect
module mainMem #(parameter LENGTH=1024, BLOCK_SIZE=32, MEM_DELAY=50) (data_out, requestComplete, data_in, addr, we, enable, clk);
	parameter ADDR_LENGTH = $clog2(LENGTH);
	parameter COUNTER_SIZE = $clog2(MEM_DELAY);
	
	output reg [(BLOCK_SIZE-1):0] data_out;
	output reg requestComplete;
	
	input [(BLOCK_SIZE-1):0] data_in;
	input [(ADDR_LENGTH-1):0] addr;
	input we, enable, clk;
	
	// state-holding memory
	reg [(BLOCK_SIZE-1):0] mem [(LENGTH-1):0];
	// counter to track delay
	reg [COUNTER_SIZE-1:0] counter = 1;
	
	reg finishDelay = 0;
	
	reg [1:0] state, next_state;
	parameter [1:0] IDLE = 2'b00, DELAY = 2'b01, FETCH = 2'b10;
	
	// reset counter and request status when new address is accessed
	always @(posedge enable) begin
		counter = 1;
		finishDelay = 0;
		requestComplete = 0;
	end
	
	// increment counter per clock cycle until delay is reached
	always @(posedge clk) begin
		if (!requestComplete) begin
			counter++; end
		if (counter >= MEM_DELAY - 1) begin
			finishDelay = 1; end
	end
	
	// return data out value once delay has been reached
	always @(posedge finishDelay) begin
		data_out = mem[addr];
		if (we) begin
			mem[addr] <= data_in; end
		requestComplete = 1;
	end
	
	initial begin
		// initialize each memory location to its index
		integer i;
		for (i=0; i<LENGTH; i++) begin
			mem[i] = i;
		end
	end
	
	always @(*) begin
		// next state logic
		case (state)
			IDLE:		begin
							if (enable)
								next_state = DELAY;
							else
								next_state = IDLE;
						end
			DELAY:	begin
							if (counter >= CACHE_DELAY - 1)
								next_state = FETCH;
							else
								next_state = DELAY;
						end
			FETCH:	begin
							if (done)
								next_state = IDLE;
							else
								next_state = FETCH;
						end
		endcase
	end
	
	// output logic
	always @(posedge clk) begin
		if (reset) begin
			state <= IDLE;
			next_state <= IDLE;
		end
		case (state)
			IDLE:		begin
							counter <= 1;
							done <= 0;
							// null out output if about to perform another search
							if (next_state == DELAY)
								data_out <= 'x;
						end
			DELAY:	begin
							counter <= counter + 1;
						end
			FETCH:	begin
							write_trigger <= 0;
							miss <= 0;
							if (writeEnable) begin
								data_out <= data_in;
								valid_bits[cacheIndex][LRUoutput] <= 1;
								tags[cacheIndex][LRUoutput] <= tag;
								data[cacheIndex][LRUoutput] <= data_in;
								done <= 1;
							end
						end
		endcase
	end
	
	state = next_state;
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