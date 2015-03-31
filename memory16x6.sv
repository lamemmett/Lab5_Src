module memory16x6 (data_out, data_in, addr, we, clk);
	output reg [5:0] data_out;
	input      [5:0] data_in;
	input      [3:0] addr;
	input            we, clk;
	reg        [5:0] mem       [15:0];
	
	always @(posedge clk) begin
		data_out = mem[addr];
		if (we)
			mem[addr] <= data_in;
	end
	
	initial begin
		$readmemh("data.dat", mem);
	end
endmodule

module memory16x6_testbench();
	wire 		[5:0] data_out;
	reg      [5:0] data_in;
	reg      [3:0] addr;
	reg            we, clk;
	parameter t = 10;
	
	memory16x6 test (.data_out, .data_in, .addr, .we, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		clk = 0;
		#(10*t);
		$stop;
	end
endmodule 