`timescale 1ns/1ps
`ifdef RTL
`include "IDC.v"
`elsif GATE
`include "IDC_SYN.v"
`endif

`ifdef CG
`include "PATTERN_CG.v"
`elsif NCG
`include "PATTERN.v"
`endif


module TESTBED();
	wire clk, rst_n, in_valid, cg_en;
	wire [6:0] in_data;
	wire [3:0] op;
	wire out_valid;
	wire [6:0] out_data;	

	
initial begin
	`ifdef RTL
		`ifdef CG
		$fsdbDumpfile("IDC_CG.fsdb");
		`elsif NCG
		$fsdbDumpfile("IDC.fsdb");
		`endif
		$fsdbDumpvars();
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		`ifdef CG
		//$fsdbDumpfile("IDC_SYN_CG.fsdb");
		`elsif NCG
		//$fsdbDumpfile("IDC_SYN.fsdb");
		`endif
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
	.cg_en(cg_en), 
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
	.cg_en(cg_en),
	.in_data(in_data),
	.op(op),
	// Input signals
	.out_valid(out_valid),
	.out_data(out_data)
);

endmodule

