`protect // associativity 
module associative_cache #(parameter SIZE=128, ADDR_LENGTH=10, DELAY=10, BLOCK_SIZE=32, RETURN_SIZE=8, ASSOCIATIVITY=2)
					  (data_out, found_data, miss, addr_in, data_in, writeEnable, enable, reset, clk);
	parameter COUNTER_SIZE = $clog2(DELAY);
	
	parameter BYTE_SELECT_SIZE = $clog2(BLOCK_SIZE/8); // 2
	parameter INDEX_SIZE = $clog2(SIZE/BLOCK_SIZE); // 2
	parameter TAG_SIZE = ADDR_LENGTH - BYTE_SELECT_SIZE - INDEX_SIZE; // 6
	
	output reg [(RETURN_SIZE-1):0] data_out;
	output reg found_data, miss = 0;
	
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
	parameter NUM_ASSO_BITS = $clog2(ASSOCIATIVITY);
	reg [(NUM_ASSO_BITS-1):0] asso_index = 0;
	wire [(NUM_ASSO_BITS-1):0] LRUoutput;
	
	// instantiate LRU module
	lru #(.INDEX_SIZE(SIZE/BLOCK_SIZE), .ASSOCIATIVITY(ASSOCIATIVITY)) LRU
		  (cacheIndex, asso_index, LRUoutput, writeEnable, LRUread, reset);
	
	/* enable signal initializes counter nulls the output value
	always @(posedge enable) begin
		LRUread = 0;
		miss = 0;
		counter = 1;
		finish_delay = 0;
		data_out = 32'bx;
		found_data = 1'b0;
	end*/
	
	parameter [2:0] IDLE = 3'b000, WAITING = 3'b001, READ = 3'b011, WRITE = 3'b100;
	reg [2:0] state;
	reg [2:0] next_state;
	
	always @(*) begin
		// next state logic
		case (state)
				IDLE:		begin
								if (enable)
									next_state = WAITING;
								else
									next_state = IDLE;
							end
				WAITING:	begin
								if (counter == DELAY - 1)
									next_state = READ;
								else
									next_state = WAITING;
							end
				READ: 	begin
								if (found_data)
									next_state = IDLE;
								else if (miss)
									next_state = WRITE;
								else
									next_state = READ;
							end
				WRITE:	begin
								if (found_data)
									next_state = IDLE;
								else
									next_state = WRITE;
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
							LRUread <= 0;
							miss <= 0;
							counter <= 1;
							finish_delay <= 0;
							found_data <= 0;
							// null out output if about to perform another search
							if (next_state == WAITING)
								data_out <= 'x;
						end
			WAITING:	begin
							counter <= counter + 1;
						end
			READ: 	begin
							for (int j=0; j<ASSOCIATIVITY; j++) begin
								if(tags[cacheIndex][j] == tag && valid_bits[cacheIndex][j] == 1) begin
									asso_index <= j;
									LRUread <= 1;
									data_out <= data[cacheIndex][j][((byteSelect+1)*RETURN_SIZE-1) -: RETURN_SIZE];
									found_data <= 1; 
									break;	end
								else if (j == (ASSOCIATIVITY - 1)) begin
									miss <= 1; end
							end
						end
			WRITE:	begin
							miss <= 0;
							if (writeEnable) begin
								data_out <= data_in;
								valid_bits[cacheIndex][0] <= 1;
								tags[cacheIndex][0] <= tag;
								data[cacheIndex][0] <= data_in;
								found_data <= 1; 
							end
						end
		endcase
		state = next_state;
	end
endmodule
`endprotect

module associative_cache_testbench();
	wire [7:0] data_out, dontCare; // always 1 byte
	wire found_dataL1, found_dataL2, missL1, missL2;
	
	reg [9:0] addr_in;
	reg [31:0] data_inL1, data_inL2;
	reg writeEnableL1, writeEnableL2, enable, reset, clk;
	
	parameter t = 10;
	parameter d = 20;
	
	//data_out, found_data, miss, addr_in, data_in, writeEnable, enable, reset, clk)
	associative_cache	L1 (data_out, found_dataL1, missL1, addr_in, data_inL1, writeEnableL1, enable, reset, clk);
	associative_cache	#(.SIZE(256), .RETURN_SIZE(32))
				L2 (data_inL1, writeEnableL1, missL2, addr_in, data_inL2, writeEnableL2, missL1, reset, clk);
	
	mainMem	#(.BLOCK_SIZE(32))
				memory (.data_out(data_inL2), .requestComplete(writeEnableL2), .data_in(32'b0), .addr(addr_in), .we(1'b0), .enable(missL2), .clk);
	
	
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
		addr_in = 4;
		enable = 1;
		#(30*t);
		enable = 0;
		#t;
		
		// repeat same access to see if value is now stored in L1
		addr_in = 4;
		enable = 1;
		#(100*t);
		$stop;
	end
endmodule 