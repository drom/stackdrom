// $Id$
// test bench

`define SYSCLK_PERIOD 2000
`define RESET_TIME 10000

module tb ();

	logic clk, reset_n;

	initial
		begin
			reset_n = 0;
			#(`RESET_TIME);
			reset_n = 1;
		end

	always
		begin
			clk = 1;
			#(`SYSCLK_PERIOD/2);
			clk = 0;
			#(`SYSCLK_PERIOD/2);
		end

hornet DUT (
	.clk     (clk),
	.reset_n (reset_n)
);

endmodule
