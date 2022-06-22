//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2022 Spring
//   Lab06-Exercise		: RSA Algorithm
//   Author     	    : Heng-Yu Liu (nine87129.ee10@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESETBED.v
//   Module Name : TESETBED
//   Release version : V1.0 (Release Date: 2022-03)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/1ps 

`ifdef RTL
    `include "PATTERN_IP.v"
    `include "RSA_IP_demo.v"
`endif

`ifdef GATE
    `include "PATTERN_IP.v"
    `include "RSA_IP_demo_SYN.v"
`endif

module TESTBED; 

// Parameter
parameter IP_WIDTH = 3;

// Connection wires
wire [IP_WIDTH-1:0]   IN_P, IN_Q;
wire [IP_WIDTH*2-1:0] IN_E;
wire [IP_WIDTH*2-1:0] OUT_N, OUT_D;


initial begin
    `ifdef RTL
        $fsdbDumpfile("RSA_IP_demo.fsdb");
        $fsdbDumpvars(0,"+mda");
        $fsdbDumpvars();
    `endif
    `ifdef GATE
        $sdf_annotate("RSA_IP_demo_SYN.sdf",My_IP);
        $fsdbDumpfile("RSA_IP_demo_SYN.fsdb");
        $fsdbDumpvars(0,"+mda");
        $fsdbDumpvars();
    `endif
end

`ifdef RTL
    RSA_IP_demo #(.WIDTH(IP_WIDTH)) My_IP (
            .IN_P(IN_P), 
            .IN_Q(IN_Q),
            .IN_E(IN_E),
            .OUT_N(OUT_N),
            .OUT_D(OUT_D)
    );
    
    PATTERN_IP #(.WIDTH(IP_WIDTH)) My_PATTERN (
            .IN_P(IN_P), 
            .IN_Q(IN_Q),
            .IN_E(IN_E),
            .OUT_N(OUT_N),
            .OUT_D(OUT_D)
    );

`elsif GATE
    RSA_IP_demo My_IP (
            .IN_P(IN_P), 
            .IN_Q(IN_Q),
            .IN_E(IN_E),
            .OUT_N(OUT_N),
            .OUT_D(OUT_D)
    );
    
    PATTERN_IP #(.WIDTH(IP_WIDTH)) My_PATTERN (
            .IN_P(IN_P), 
            .IN_Q(IN_Q),
            .IN_E(IN_E),
            .OUT_N(OUT_N),
            .OUT_D(OUT_D)
    );

`endif  


endmodule