module lru #(parameter INDEX_SIZE = 4, ASSOCIATIVITY = 1)
	(index, asso_index, select, write_trigger, read_trigger, reset, clk);
	parameter COUNT_SIZE = $clog2(ASSOCIATIVITY);
	parameter NUM_INDICES = $clog2(INDEX_SIZE);
	
	output reg [(COUNT_SIZE-1):0] select = 0;
	
	input [(NUM_INDICES-1):0] index;
	input [(COUNT_SIZE-1):0] asso_index;
	
	input write_trigger, read_trigger, reset, clk;
	
	reg [(INDEX_SIZE-1):0][(ASSOCIATIVITY-1):0][(COUNT_SIZE-1):0] mem;
	reg [(ASSOCIATIVITY-1):0] v;
	
	reg reading = 0, writing = 0;
	
	integer i, j;
	initial begin
		for(i = 0; i < INDEX_SIZE; i++) begin
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				mem[i][j] = j;
			end
		end
	end
	
	always @(*) begin
		select = select;
		for(j = 0; j < ASSOCIATIVITY; j++)begin
			if(mem[index][j] == 0) begin
				select = j;
			end
		end
		// reset cache contents
		if (reset) begin
			for(i = 0; i < INDEX_SIZE; i++) begin
				for(j = 0; j < ASSOCIATIVITY; j++)begin
					mem[i][j] <= j;
				end
			end
		end
		
		if (write_trigger & ~writing) begin
			writing = 1;
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				mem[index][j] -= 1'b1;
				if(mem[index][j] >= ASSOCIATIVITY) begin
					mem[index][j] <= ASSOCIATIVITY-1;
				end
			end
		end
		
		if (read_trigger & ~reading) begin
			reading = 1;
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				if(j == asso_index) begin
					v <= mem[index][j];
				end
			end
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				if(mem[index][j] > v ) begin
					mem[index][j] <= mem[index][j] - 1'b1;
				end
				if(mem[index][j] == v) begin
					mem[index][j] <= ASSOCIATIVITY - 1;
				end
			end
		end
		
		if (~read_trigger & ~write_trigger) begin
			reading = 0;
			writing = 0;
		end
	end
endmodule

module lru_testbench();
	wire [(3-1):0] select;
	
	reg [(2-1):0] index;
	reg [(3-1):0] asso_index;
	
	reg write_trigger, read_trigger, reset;

	lru #(.INDEX_SIZE(2), .ASSOCIATIVITY(6)) test
	(.index, .asso_index, .select, .write_trigger, .read_trigger, .reset);
	
	integer i;
	initial begin
		write_trigger <= 1'b0; read_trigger <= 1'b0; index = 1'b0; #10;
		write_trigger <= 1'b1; #10;
		write_trigger <= 1'b0; #10;
		write_trigger <= 1'b1; #10;
		asso_index = 3'b101;   read_trigger <= 1'b1; #10;
	end
endmodule
