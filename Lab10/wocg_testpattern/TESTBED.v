`timescale 1ns/1ps
`ifdef RTL
`include "IDC_wocg.v"
`elsif GATE
`include "IDC_SYN.v"
`endif


`include "PATTERN.v"

module TESTBED();
	wire clk, rst_n, in_valid;
	wire [6:0] in_data;
	wire [3:0] op;
	wire out_valid;
	wire [6:0] out_data;	

	
initial begin
	`ifdef RTL
		$fsdbDumpfile("IDC.fsdb");
		$fsdbDumpvars();
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("IDC_SYN.fsdb");
		$sdf_annotate("IDC_SYN.sdf",I_IDC);      
		//$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
end

IDC I_IDC
(
	// Input signals
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_data(in_data),
	.op(op),
	// Output signals
	.out_valid(out_valid),
	.out_data(out_data)
);


PATTERN I_PATTERN
(
	// Output signals
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_data(in_data),
	.op(op),
	// Input signals
	.out_valid(out_valid),
	.out_data(out_data)
);

endmodule

