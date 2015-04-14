`protect // associativity 
module dm_cache #(parameter SIZE=128, ADDR_LENGTH=10, DELAY=10, BLOCK_SIZE=32)
					  (data_out, found_data, miss, addr_in, data_in, writeEnable, enable, reset, clk);
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

	// CACHE CONTENTS
	reg [(SIZE/BLOCK_SIZE-1):0] [(BLOCK_SIZE-1):0] 	data;
	reg [(SIZE/BLOCK_SIZE-1):0] [(TAG_SIZE-1):0] 	tags;
	reg [(SIZE/BLOCK_SIZE-1):0] 							valid_bits;
	
	// various counters and flags
	reg waiting = 0;
	reg [COUNTER_SIZE-1:0] counter;
	reg finish_delay = 0;
	
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
	
	// wait for lower cache to return data and write to cache
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
	wire found_dataL1, found_dataL2, missL1, missL2;
	
	reg [9:0] addr_in;
	reg [31:0] data_inL1, data_inL2;
	reg writeEnableL1, writeEnableL2, enable, reset, clk;
	
	parameter t = 10;
	parameter d = 20;
	
	//data_out, found_data, miss, addr_in, data_in, writeEnable, enable, reset, clk)
	dm_cache	L1 (data_out, found_dataL1, missL1, addr_in, data_inL1, writeEnableL1, enable, reset, clk);
	dm_cache	#(.SIZE(256))
				L2 (data_inL1, writeEnableL1, missL2, addr_in, data_inL2, writeEnableL2, missL1, reset, clk);
	
	mainMem	memory (.data_out(data_inL2), .requestComplete(writeEnableL2), .data_in(32'b0), .addr(addr_in), .we(1'b0), .enable(missL2), .clk);
	
	always #(t/2) clk = ~clk;
		
	integer i = 0;
	
	initial begin
		clk = 0;
		reset = 1'b1; #(t/2);
		reset = 1'b0; #(t/2);
		
		#(d*t);
		
		// fill up both caches
		for (i=0; i <32; i+=4) begin
			addr_in = i;
			enable = 1;
			#(100*t);
			enable = 0;
			#t;
		end
		
		// access an element that is in L2 but had capacity overflow in L1
		addr_in = 4;
		enable = 1;
		#(100*t);
		enable = 0;
		#t;
		
		// repeat same access to see if value is now stored in L1
		addr_in = 4;
		enable = 1;
		#(100*t);
		$stop;
	end
endmodule 