`protect // associativity 
module cache #(parameter LENGTH=1024, BLOCK_SIZE=8, ASSOCIATIVITY=1, DELAY=50) (data_out, f_out, en_out, data_in, f_in, en_in, addr, we, clk);
	parameter ADDR_LENGTH = $clog2(LENGTH);
	parameter COUNTER_SIZE = $clog2(DELAY);
	
	parameter BYTE_SELECT_SIZE = $clog2(BLOCK_SIZE/8);
	parameter INDEX_SIZE = $clog2(LENGTH);
	parameter TAG_SIZE = ADDR_LENGTH - BYTE_SELECT_SIZE - INDEX_SIZE;
	
	output reg [(BLOCK_SIZE-1):0] data_out;
	output reg f_out, en_out;
	input [(BLOCK_SIZE-1):0] data_in;
	input f_in, en_in;
	input [(ADDR_LENGTH-1):0] addr;
	input we, clk;
	reg [(BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] mem [(LENGTH-1):0];
	
	reg [COUNTER_SIZE-1:0] counter = 0;
	reg requestComplete = 0;
		
	reg [(TAG_SIZE-1):0] [(ASSOCIATIVITY-1):0] tag [(LENGTH-1):0];
	reg [(ASSOCIATIVITY-1):0] valid [(LENGTH-1):0];
	
	integer i;
	
	// reset counter and request status when new address is accessed
	always @(addr) begin
		counter = 0;
		requestComplete = 0;
		f_out = 0;
		
		for(i = 0; i < LENGTH; i++) begin
			if(addr[ADDR_LENGTH-1] == tag
			
			
		end
		
	end
	
	// increment counter per clock cycle until delay is reached
	always @(posedge clk) begin
		if(en_in) begin
			counter++;
			if (counter == (DELAY-1)) begin
				requestComplete = 1;
				counter = 0; end
		end
		else counter = 0;
	end
	
	// return data out value once delay has been reached
	always @(posedge requestComplete) begin
		if(en_in) begin
			data_out = mem[addr];
			if(we && f_in)
				mem[addr] <= data_in;
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

module cache_testbench();
	wire [7:0] data_out;
	wire f_out, en_out;
	reg [7:0] data_in;
	reg [8:0] addr;
	reg f_in, en_in;;
	reg we, clk;
	parameter t = 10;
	parameter d = 20;
	
	cache #(.LENGTH(512), .BLOCK_SIZE(), .DELAY(d)) test (.data_out, .f_out, .en_out, .data_in, .f_in, .en_in, .addr, .we, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		clk = 0;
		addr = 10;
		we = 0;
		
		data_in = 8'b0;
		f_in = 0;
		en_in = 1;
		
		#(d*t);
		assert (data_out == 10);	// access index 10, value should appear 5 cycles later
		
		addr = 50;
		#(d*t);
		assert (data_out == 50);	// access index 50, value should appear 5 cycles later
		
		#(100*t);
		$stop;
	end
endmodule 