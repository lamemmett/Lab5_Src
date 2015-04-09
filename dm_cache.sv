`protect // associativity 
module dm_cache (data_out, found_data, miss, addr_in, data_in, writeEnable, enable, reset, clk);
	parameter SIZE = 128;
	parameter ADDR_LENGTH = 10;
	parameter DELAY = 50;
	parameter BLOCK_SIZE = 32;
	
	parameter COUNTER_SIZE = $clog2(DELAY);
	
	parameter BYTE_SELECT_SIZE = $clog2(BLOCK_SIZE/8); // 2
	parameter INDEX_SIZE = $clog2(SIZE/BLOCK_SIZE); // 2
	parameter TAG_SIZE = ADDR_LENGTH - BYTE_SELECT_SIZE - INDEX_SIZE; // 6
	
	output reg [31:0] data_out; // 8 bits
	output reg found_data, miss = 0;
	
	input [(ADDR_LENGTH-1):0] addr_in; // 10 bits
	input [(BLOCK_SIZE-1):0] data_in;
	input writeEnable, enable, reset, clk;
	
	wire [BYTE_SELECT_SIZE-1:0] 	byteSelect 	= addr_in[(BYTE_SELECT_SIZE-1):0];
	wire [INDEX_SIZE-1:0]			cacheIndex 	= addr_in[(BYTE_SELECT_SIZE+INDEX_SIZE-1):(BYTE_SELECT_SIZE)];
	wire [TAG_SIZE-1:0]				tag 			= addr_in[(ADDR_LENGTH-1):(BYTE_SELECT_SIZE+INDEX_SIZE)];

	reg [(SIZE/BLOCK_SIZE-1):0] [(BLOCK_SIZE-1):0] data;
	reg [(INDEX_SIZE-1):0] [(TAG_SIZE-1):0] tags;
	reg [(INDEX_SIZE-1):0] valid_bits;
	
	initial begin
		valid_bits[0] = 1;
		tags[0] = 6'b000011;
		data[0] = 32'b1;
	end
	
	reg waiting = 0;
	reg [COUNTER_SIZE-1:0] counter;
	reg finish_delay = 0;
	reg [31:0] data_f;
	
	// enable signal initializes counter nulls the output value
	always @(posedge enable) begin
		miss = 0;
		counter = 1;
		waiting = 1;
		finish_delay = 0;
		data_out = 32'bx;
		found_data = 1'bx;
	end
	
	// increment counter per clok cycle, once delay has been reached set flags
	always @(posedge clk) begin
		if (waiting) begin
			counter++; end
		if (counter == DELAY) begin
			waiting = 0;
			finish_delay = 1; end
	end
	
	// Once delay done, check if data exists and return it
	always @(posedge finish_delay) begin
		if (tags[cacheIndex] == tag && valid_bits[cacheIndex] == 1) begin
			found_data = 1;
			data_out = data[cacheIndex]; end
		else begin
			miss = 1;
			found_data = 0; end
	end
	
	// wait for lower cache to return data
	always @(posedge writeEnable) begin
		data_out = data_in;
		valid_bits[cacheIndex] = 1;
		tags[cacheIndex] = tag;
		data[cacheIndex] = data_in;
		found_data = 1;
	end
endmodule
`endprotect

module dm_cache_testbench();
	wire [31:0] data_out, dontCare; // always 1 byte
	wire found_data, miss;
	
	reg [9:0] addr_in;
	reg [31:0] data_in;
	reg writeEnable, enable, reset, clk;
	
	parameter t = 10;
	parameter d = 20;
	
	dm_cache	cache (.data_out, .found_data, .miss, .addr_in, .data_in, .writeEnable, .enable, .reset, .clk);
	mainMem	memory (.data_out(data_in), .requestComplete(writeEnable), .data_in(32'b0), .addr(addr_in), .we(1'b0), .enable(miss), .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		clk = 0;
		reset = 1'b1; #(t/2);
		reset = 1'b0; #(t/2);
		
		#(d*t);
		
		addr_in = 50;
		enable = 1;
		#(100*t);
		
		addr_in = 4;
		enable = 0;
		#t;
		enable = 1;
		#(200*t);
		
		enable = 0;
		#t;
		enable = 1;
		#(100*t);
		$stop;
	end
endmodule 