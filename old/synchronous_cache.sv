`protect // associativity 
module dm_cache (data_out, req_out, miss_out, addr_in, data_in, req_in, miss_in, reset, clk);
	parameter SIZE = 128;
	parameter ADDR_LENGTH = 10;
	parameter DELAY = 50;
	parameter BLOCK_SIZE = 32;
	
	parameter COUNTER_SIZE = $clog2(DELAY);
	
	parameter BYTE_SELECT_SIZE = $clog2(BLOCK_SIZE/8); // 2
	parameter INDEX_SIZE = $clog2(SIZE/BLOCK_SIZE); // 2
	parameter TAG_SIZE = ADDR_LENGTH - BYTE_SELECT_SIZE - INDEX_SIZE; // 6
	
	output reg [7:0] data_out; // 8 bits
	output reg req_out, miss_out;
	
	input [(ADDR_LENGTH-1):0] addr_in; // 10 bits
	input [(BLOCK_SIZE-1):0] data_in;
	input req_in, miss_in, reset, clk;

	reg [(SIZE/BLOCK_SIZE-1):0] [(BLOCK_SIZE/8-1):0] [7:0] mem;
	reg [(SIZE/BLOCK_SIZE-1):0] [(TAG_SIZE-1):0] tag;
	reg [(SIZE/BLOCK_SIZE-1):0] valid;
	
	reg [COUNTER_SIZE-1:0] counter;
	
	reg enabled;
	always @(*) begin
		if(miss_in) enabled = 1'b1;
		if(req_out || reset) enabled = 1'b0;
	end
	
	reg delay_finish;
	always @(*) begin
		if(counter >= (DELAY-1)) delay_finish = 1'b1;
		if(req_out || reset) delay_finish = 1'b0;
	end
	
	reg [7:0] data_f;
	reg found_data;
	integer i, j;
	always @(*) begin
		if(delay_finish) begin
			for(i = 0; i < INDEX_SIZE; i++) begin
				if(tag[i] == addr_in[(ADDR_LENGTH-1):(BYTE_SELECT_SIZE+INDEX_SIZE)] && valid[i] == 1'b1) begin
					for(j = 0; j < BYTE_SELECT_SIZE; j++) begin
						if(j == addr_in[(BYTE_SELECT_SIZE-1):0]) begin
							found_data = 1'b1;
							data_f = mem[i][j];
						end
					end
				end
				else begin
					found_data = 1'b0;
				end
			end
		end
	end
	
	integer value;
	integer k, l;
	always @(posedge clk) begin
		/* On reset clear memory and flags */
		if(reset) begin
			//mem <= 32'h00000000;
			//tag <= 6'b000000;
			//valid <= 1'b0;
			value = 0;
			for (k = 0; k < INDEX_SIZE; k++) begin
				for (l = 0; l < BLOCK_SIZE/8; l++) begin
					mem[k][l] = value;
					value++;
				end
			end
			///////////////////
			tag[1] = 6'b000000;
			valid[1] = 1'b1;
			///////////////////
		end
		
		/* Cache is enabled */
		if(enabled) begin
			counter <= counter + 1;
		end
		
		/* Cache is disabled */
		if(!enabled) begin
			counter <= 0;
		end
		
		/* Data is found in cache */
		if(found_data) begin
			data_out <= data_f;
		end
		
		/* Data is not found in cache */
		if(!found_data) begin
			data_out <= 8'hFF;
		end
		
		
	end
	
	
	always @(posedge miss_in) begin
		counter = 0;
	end
	
	
endmodule
`endprotect


module dm_cache_testbench();
	wire [7:0] data_out; // always 32 bits
	wire req_out, miss_out;
	
	reg [9:0] addr_in;
	reg [31:0] data_in;
	reg req_in, miss_in, reset, clk;
	
	dm_cache	test (.data_out, .req_out, .miss_out, .addr_in, .data_in, .req_in, .miss_in, .reset, .clk);
	
	parameter CLOCK_PERIOD = 100;
	initial clk = 1;
	always begin
		#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	
	integer i;
	initial begin
		reset = 1'b1; 						@(posedge clk);
		reset = 1'b0; miss_in = 1'b1; addr_in = 10'b0000000001; @(posedge clk);
						  miss_in = 0'b0; @(posedge clk);
		for(int i = 1; i < 50; i++)	@(posedge clk);
		for(int i = 1; i < 50; i++)	@(posedge clk);
		
		$stop;
	end
endmodule