module memoryIO (dataOut, delayCounter, requestReady, requestAck, addr, enable, clk);
	output 		[7:0]	dataOut;
	output reg 	[7:0]	delayCounter = 0;
	output reg			requestReady, requestAck;
	input 		[9:0]	addr;
	input 				enable, clk;
	
	always @(posedge enable) begin
		delayCounter	= 1;
		requestReady	= 0;
		requestAck		= 1;
	end
	
	always @(posedge clk) begin
		if (!requestReady) begin
			delayCounter++; end
	end
endmodule 

module memoryIO_testbench ();
	wire 		[7:0]	dataOut;
	wire 		[7:0]	delayCounter;
	wire				requestReady, requestAck;
	reg 		[9:0]	addr;
	reg 				enable, clk;
	
	parameter t = 10;
	
	memoryIO test (.dataOut, .delayCounter, .requestReady, .requestAck, .addr, .enable, .clk);
	
	always #(t/2) clk = ~clk;
	
	initial begin
		addr = 10'b0;
		enable = 0;
		clk = 0;
		#(3*t);
		enable = 1;
		#(50*t);
		$stop;
	end
endmodule 