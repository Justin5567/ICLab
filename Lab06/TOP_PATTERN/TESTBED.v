//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2022 Spring
//   Lab06-Exercise		: RSA Algorithm
//   Author     	    : Heng-Yu Liu (nine87129.ee10@nytu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESETBED.v
//   Module Name : TESETBED
//   Release version : V1.0 (Release Date: 2018-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/1ps 

`ifdef RTL_TOP
  `include "RSA_TOP.v"
  `include "PATTERN.v"
`endif

`ifdef GATE_TOP
  `include "RSA_TOP_SYN.v"
  `include "PATTERN.v"
`endif
	  		  	
module TESTBED; 

//Connection wires
wire clk, rst_n;
wire in_valid, out_valid;
wire [3:0] in_p, in_q;
wire [7:0] in_e, in_c, out_m;

initial begin
	`ifdef RTL_TOP
		$fsdbDumpfile("RSA_TOP.fsdb");
		$fsdbDumpvars(0,"+mda");   
	`endif

	`ifdef GATE_TOP
		$sdf_annotate("RSA_TOP_SYN.sdf", My_DESIGN);
		$fsdbDumpfile("RSA_TOP_SYN.fsdb");
		$fsdbDumpvars(0,"+mda");    
	`endif
end

`ifdef RTL_TOP
	RSA_TOP My_DESIGN(
		.clk(clk),
		.rst_n(rst_n),
		.in_valid(in_valid),
		.in_p(in_p),
		.in_q(in_q),
		.in_e(in_e),
		.in_c(in_c),
		.out_valid(out_valid),
		.out_m(out_m)
	);

	PATTERN My_PATTERN(
		.clk(clk),
		.rst_n(rst_n),
		.in_valid(in_valid),
		.in_p(in_p),
		.in_q(in_q),
		.in_e(in_e),
		.in_c(in_c),
		.out_valid(out_valid),
		.out_m(out_m)
	);

`elsif GATE_TOP
	RSA_TOP My_DESIGN(
		.clk(clk),
		.rst_n(rst_n),
		.in_valid(in_valid),
		.in_p(in_p),
		.in_q(in_q),
		.in_e(in_e),
		.in_c(in_c),
		.out_valid(out_valid),
		.out_m(out_m)
	);
	
	PATTERN My_PATTERN(
		.clk(clk),
		.rst_n(rst_n),
		.in_valid(in_valid),
		.in_p(in_p),
		.in_q(in_q),
		.in_e(in_e),
		.in_c(in_c),
		.out_valid(out_valid),
		.out_m(out_m)
	);
`endif  

 
endmodule