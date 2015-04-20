module lru #(parameter INDEX_SIZE = 4, ASSOCIATIVITY = 1)
	(index, asso_index, select, write_trigger, read_trigger, reset);
	parameter COUNT_SIZE = $clog2(ASSOCIATIVITY);
	
	output reg [(COUNT_SIZE-1):0] select;
	
	input [(INDEX_SIZE-1):0] index;
	input [(COUNT_SIZE-1):0] asso_index;
	
	input write_trigger, read_trigger, reset;
	
	reg [(INDEX_SIZE-1):0][(ASSOCIATIVITY-1):0][(COUNT_SIZE-1):0] mem;
	
	integer i, j;
	initial begin
		for(i = 0; i < INDEX_SIZE; i++) begin
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				mem[i][j] = j;
			end
		end
	end
  
	always @(posedge reset) begin
		for(i = 0; i < INDEX_SIZE; i++) begin
			for(j = 0; j < ASSOCIATIVITY; j++)begin
				mem[i][j] = j;
			end
		end
	end
	
	always @(posedge write_trigger) begin
		for(j = 0; j < ASSOCIATIVITY; j++)begin
			mem[index][j] -= 1'b1;
			if(mem[index][j] >= ASSOCIATIVITY) begin
				mem[index][j] = ASSOCIATIVITY-1;
			end
			if(mem[index][j] == 0) begin
				select = mem[index][j];
			end
		end
	end
	
	reg [(ASSOCIATIVITY-1):0] v;
	always @(posedge read_trigger) begin
		for(j = 0; j < ASSOCIATIVITY; j++)begin
			if(j == asso_index) begin
				v = mem[index][j];
				mem[index][j] = ASSOCIATIVITY;
			end
		end
		for(j = 0; j < ASSOCIATIVITY; j++)begin
			if(mem[index][j] > v ) begin
				mem[index][j] -= 1'b1;
			end
			if(mem[index][j] == 0) begin
				select = mem[index][j];
			end
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