`protect // associativity 
module dm_cache (data_out, req_out, miss_out, addr_in, data_in, req_in, miss_in, reset, clk);
	parameter SIZE = 128;
	parameter ADDR_LENGTH = 10;
	parameter DELAY = 50;
	parameter BLOCK_SIZE = 4;
	
	parameter COUNTER_SIZE = $clog2(DELAY);
	
	parameter BYTE_SELECT_SIZE = $clog2(BLOCK_SIZE); // 2
	parameter INDEX_SIZE = $clog2(SIZE/BLOCK_SIZE/8); // 2
	parameter TAG_SIZE = ADDR_LENGTH - BYTE_SELECT_SIZE - INDEX_SIZE; // 6
	
	output reg [7:0] data_out; // 8 bits
	output reg req_out, miss_out;
	
	input [(ADDR_LENGTH-1):0] addr_in; // 10 bits
	input [(BLOCK_SIZE-1):0] data_in;
	input req_in, miss_in, reset, clk;

	reg [(INDEX_SIZE-1):0] [(BLOCK_SIZE-1):0] mem;
	reg [(INDEX_SIZE-1):0] [(TAG_SIZE-1):0] tag;
	reg [(INDEX_SIZE-1):0] valid;
	
	reg waiting;
	reg [COUNTER_SIZE-1:0] counter;
	reg finish_delay;
	reg found_data;
	reg [31:0] data_f;
	
	integer i, j;
	// increment counter per clock cycle until delay is reached
	always @(posedge clk) begin
		if(reset) begin
			for(i = 0; i < INDEX_SIZE; i++) begin
					valid[i] = 1'b0;
					tag[i] = 6'b000000;
					mem[i] = 32'h00000000;
			end
		end
		if(waiting) begin
			if(req_in = 1'b1) begin
				data_out = data_in;
				waiting = 1'b0;
			end
		end
		else begin
			if(miss_in) begin
				counter++;
				if (counter == (DELAY-1)) begin
					finish_delay = 1'b1;
					counter = 1'b0; 
				end
			end
			else begin
				counter = 0; // initialize counter
				req_out = 1'b0;
				miss_out = 1'b0;
				finish_delay = 1'b0;
				found_data = 1'b0;
				data_out = 32'hXXXXXXXX;
			end
			if(finish_delay) begin
				for(j = 0; j < INDEX_SIZE; j++) begin
					if(tag[j] == addr_in[(ADDR_LENGTH-1):(BYTE_SELECT_SIZE+INDEX_SIZE)] && valid[j] == 1'b1) begin
						found_data = 1'b1;
						data_out = mem[j];
					end
				end
			end
			if(!found_data) begin
				waiting = 1'b1;
			end
		end
	end
endmodule
`endprotect

module dm_cache_testbench();
	wire [31:0] data_out; // always 32 bits
	wire req_out, miss_out;
	
	reg [8:0] addr_in;
	reg [31:0] data_in;
	reg req_in, miss_in, reset, clk;
	
	parameter t = 10;
	parameter d = 20;
	
	dm_cache	test (.data_out, .req_out, .miss_out, .addr_in, .data_in, .req_in, .miss_in, .reset, .clk);
	
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