`protect // associativity 
module cache #(parameter SIZE=1024, BLOCK_SIZE=32, ASSOCIATIVITY=1, DELAY=50) 
	(data_out, req_out, miss_out, addr_in, data_in, req_in, miss_in, reset, clk);
	
	parameter ADDR_LENGTH = $clog2(SIZE);
	parameter COUNTER_SIZE = $clog2(DELAY);
	
	parameter BYTE_SELECT_SIZE = $clog2(BLOCK_SIZE/8);
	parameter INDEX_SIZE = $clog2(SIZE/BLOCK_SIZE/ASSOCIATIVITY);
	parameter TAG_SIZE = ADDR_LENGTH - BYTE_SELECT_SIZE - INDEX_SIZE;
	
	output reg [31:0] data_out; // always 32 bits
	output reg req_out, miss_out;
	
	input [(ADDR_LENGTH-1):0] addr_in;
	input [(BLOCK_SIZE-1):0] data_in;
	input req_in, miss_in, reset, clk;

	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(BLOCK_SIZE-1):0] mem;
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(TAG_SIZE-1):0] tag;
	reg [(INDEX_SIZE-1):0] [(ASSOCIATIVITY-1):0] valid;
	
	
	reg [COUNTER_SIZE-1:0] counter;
	reg finish_delay;
	reg found_data;
	reg [31:0] data_f;
	
	// reset counter, request, and miss status when recieving a miss
	always @(posedge miss_in) begin
		counter = 0; // initialize counter
		req_out = 1'b0;
		miss_out = 1'b0;
		finish_delay = 1'b0;
		found_data = 1'b0;
		data_out = 32'hXXXXXXXX;
	end
	
	integer i, j;
	
	// increment counter per clock cycle until delay is reached
	always @(posedge clk) begin
		if(reset) begin
			for(i = 0; i < INDEX_SIZE; i++) begin
				for(j = 0; j < ASSOCIATIVITY; j++) begin
					valid[i][j] = 1'b0;
					tag[i][j] = {32'b0}[TAG_SIZE:1];
					mem[i][j] = {128'b0}[BLOCK_SIZE:1];
				end
			end
		end
		if(miss_in) begin
			counter++;
			if (counter == (DELAY-1)) begin
				finish_delay = 1'b1;
				counter = 1'b0; 
			end
		end
		else counter = 0;
	end
		
	integer k, l;
	
	// return data out value once delay has been reached
	always @(posedge finish_delay) begin
		for(k = 0; k < INDEX_SIZE; k++) begin
			for(l = 0; l < ASSOCIATIVITY; l++) begin
				if(tag[l][k] == addr_in[(ADDR_LENGTH-1):(BYTE_SELECT_SIZE+INDEX_SIZE)]
					&& valid[l][k] == 1'b1) begin
					found_data = 1'b1;
					data_out = mem[l][k];
				end
			end
		end
		if(!found_data) begin
			req_out = 1'b1;
			
			//data_out =;
		end
		else begin
			req_out = 1'b1;
			data_out = 32'hXXXXXXXX;
		end
	end

endmodule
`endprotect

module cache_testbench();
	wire [31:0] data_out; // always 32 bits
	wire req_out, miss_out;
	
	reg [8:0] addr_in;
	reg [31:0] data_in;
	reg req_in, miss_in, reset, clk;
	
	parameter t = 10;
	parameter d = 20;
	
	cache #(.SIZE(512), .BLOCK_SIZE(), .ASSOCIATIVITY(), .DELAY(d))
	test (.data_out, .req_out, .miss_out, .addr_in, .data_in, .req_in, .miss_in, .reset, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		reset = 1'b1; #(t/2);
		reset = 1'b0; #(t/2);
		
		#(d*t);
		
		addr_in = 50;
		
		#(d*5*t);
		$stop;
	end
endmodule 