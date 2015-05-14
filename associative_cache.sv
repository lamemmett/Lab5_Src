`protect // associativity 
module associative_cache #(parameter SIZE=128, ADDR_LENGTH=10, CACHE_DELAY=0, BLOCK_SIZE=32, RETURN_SIZE=8, ASSOCIATIVITY=4)
					  (data_out, done, miss, addr_in, data_in, writeEnable, enable, reset, clk);
	parameter COUNTER_SIZE = $clog2(CACHE_DELAY);
	
	parameter BYTE_SELECT_SIZE = $clog2(BLOCK_SIZE/8);
	parameter INDEX_SIZE = $clog2(SIZE/BLOCK_SIZE);
	parameter TAG_SIZE = ADDR_LENGTH - BYTE_SELECT_SIZE - INDEX_SIZE;
	
	output reg [(RETURN_SIZE-1):0] data_out;
	output reg done, miss = 0;
	
	input [(ADDR_LENGTH-1):0] addr_in;
	input [(BLOCK_SIZE-1):0] data_in;
	input writeEnable, enable, reset, clk;
	
	wire [BYTE_SELECT_SIZE-1:0] 	byteSelect 	= addr_in[(BYTE_SELECT_SIZE-1):0];
	wire [INDEX_SIZE-1:0]			cacheIndex 	= addr_in[(BYTE_SELECT_SIZE+INDEX_SIZE-1):(BYTE_SELECT_SIZE)];
	wire [TAG_SIZE-1:0]				tag 			= addr_in[(ADDR_LENGTH-1):(BYTE_SELECT_SIZE+INDEX_SIZE)];

	// CACHE CONTENTS
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(BLOCK_SIZE-1):0] data;
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0] [(TAG_SIZE-1):0] 	tags;
	reg [(SIZE/BLOCK_SIZE-1):0] [(ASSOCIATIVITY-1):0]							valid_bits;
	
	// various counters and flags
	reg [COUNTER_SIZE-1:0] counter;
	reg finish_delay = 0;
	reg LRUread = 0;
	reg write_trigger = 0;
	parameter NUM_ASSO_BITS = $clog2(ASSOCIATIVITY);
	reg [(NUM_ASSO_BITS-1):0] asso_index = 0;
	wire [(NUM_ASSO_BITS-1):0] LRUoutput;
	
	// instantiate LRU module
	lru #(.INDEX_SIZE(SIZE/BLOCK_SIZE), .ASSOCIATIVITY(ASSOCIATIVITY)) LRU
		  (cacheIndex, asso_index, LRUoutput, write_trigger, LRUread, reset, clk);
	
	parameter [1:0] IDLE = 2'b00, DELAY = 2'b01, READ = 2'b10, FETCH = 2'b11;
	reg [1:0] state;
	
	always @(*) begin
		// state logic
		case (state)
				IDLE:		begin
								if (enable)
									if (CACHE_DELAY == 0)
										state = READ;
									else
										state = DELAY;
								else
									state = IDLE;
							end
				DELAY:	begin
								if (counter >= CACHE_DELAY)
									state = READ;
								else
									state = DELAY;
							end
				READ: 	begin
								if (done)
									state = IDLE;
								else if (miss)
									state = FETCH;
								else
									state = READ;
							end
				FETCH:	begin
								if (done)
									state = IDLE;
								else
									state = FETCH;
							end
			endcase
	end
	
	// async output logic
	always @(*) begin
		case (state)
			IDLE:		begin
							LRUread = 0;
							write_trigger = 0;
						end
			READ:		begin
							for (int j=0; j<ASSOCIATIVITY; j++) begin
								if(tags[cacheIndex][j] == tag && valid_bits[cacheIndex][j] == 1) begin
									asso_index = j;
									LRUread = 1;
									data_out = data[cacheIndex][j][((byteSelect+1)*RETURN_SIZE-1) -: RETURN_SIZE];
									done = 1;
									break;	end
								else if (j == (ASSOCIATIVITY - 1)) begin
									miss = 1;
									end
							end
						end
			FETCH:	begin
							miss = 0;
							if (writeEnable) begin
								write_trigger = 1;
								data_out = data_in;
								valid_bits[cacheIndex][LRUoutput] = 1;
								tags[cacheIndex][LRUoutput] = tag;
								data[cacheIndex][LRUoutput] = data_in;
								done = 1;
							end
						end
		endcase
	end
	
	// output logic
	always @(posedge clk) begin
		if (reset) begin
			state <= IDLE;
		end
		case (state)
			IDLE:		begin
							write_trigger <= 0;
							LRUread <= 0;
							miss <= 0;
							counter <= 0;
							finish_delay <= 0;
							done <= 0;
						end
			DELAY:	begin
							counter <= counter + 1;
						end
			READ: 	begin
							
						end
			FETCH:	begin
							
						end
		endcase
	end
endmodule
`endprotect

module associative_cache_testbench();
	wire [7:0] data_out, dontCare; // always 1 byte
	wire doneL1, doneL2, missL1, missL2;
	
	reg [9:0] addr_in;
	reg [31:0] data_inL1, data_inL2;
	reg writeEnableL1, writeEnableL2, enable, reset, clk;
	
	parameter t = 10;
	parameter d = 20;
	
	//data_out, done, miss, addr_in, data_in, writeEnable, enable, reset, clk)
	associative_cache	L1 (data_out, doneL1, missL1, addr_in, data_inL1, writeEnableL1, enable, reset, clk);
	associative_cache	#(.SIZE(256), .RETURN_SIZE(32))
				L2 (data_inL1, writeEnableL1, missL2, addr_in, data_inL2, writeEnableL2, missL1, reset, clk);
	
	mainMem	#(.BLOCK_SIZE(32))
				memory (.data_out(data_inL2), .done(writeEnableL2), .data_in(32'b0), .addr(addr_in), .we(1'b0), .enable(missL2), .clk);
	
	
	always #(t/2) clk = ~clk;
		
	integer i = 0;
	initial begin
		clk <= 0;
		reset <= 1'b1;			@(posedge clk);
		reset <= 1'b0;			@(posedge clk);
		
									@(posedge clk);
		
		// fill up both caches
		for (i=0; i<128; i++) begin
			addr_in <= i;		@(posedge clk);
			enable <= 1;		@(posedge clk);
			enable <= 0;		@(posedge clk);
			#(100*t);
		end
		
		// access an element that is in L2 but had capacity overflow in L1
		addr_in = 4;		@(posedge clk);
		enable <= 1;		@(posedge clk);
		enable <= 0;		@(posedge clk);
		#(100*t);
		
		// repeat same access to see if value is now stored in L1
		addr_in = 4;		@(posedge clk);
		enable <= 1;		@(posedge clk);
		enable <= 0;		@(posedge clk);
		#(100*t);
		$stop;
	end
endmodule 