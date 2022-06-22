//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : RSA_TOP.v
//   Module Name : RSA_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "RSA_IP.v"
//synopsys translate_on

module RSA_TOP (
    // Input signals
    clk, rst_n, in_valid,
    in_p, in_q, in_e, in_c,
    // Output signals
    out_valid, out_m
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [3:0] in_p, in_q;
input [7:0] in_e, in_c;
output reg out_valid;
output reg [7:0] out_m;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
parameter IDLE = 4'd0;
parameter RD = 4'd1;
parameter IDLE2 = 4'd4;
parameter Set_C = 4'd6;
parameter OP = 4'd2;
parameter IDLE3 = 4'd5;
parameter DONE = 4'd3;


integer i;
//================================================================
// Wire & Reg Declaration
//================================================================
reg [3:0] state_cs,state_ns;
reg [7:0] counter;
reg [3:0] round_counter;
reg [3:0]in_p_reg;
reg [3:0]in_q_reg;
reg [7:0]in_e_reg;
reg [7:0]in_c_reg[0:7];
//reg [7:0]out_m_reg[0:7];
reg [7:0]OUT_N_reg;
reg [7:0]OUT_D_reg;


reg [7:0]tmp_mod1;
//reg [7:0]tmp_mod2;

wire doneRD,doneOP,doneOUTPUT,doneDecrypt;
assign doneRD = counter==7;
assign doneOP = counter==OUT_D_reg;
assign doneOUTPUT = counter==8;
assign doneDecrypt = round_counter==8;
//================================================================
// DESIGN
//================================================================
wire signed[7:0] OUT_N,OUT_D;
// soft ip
RSA_IP #(.WIDTH(4)) I_RSA_IP ( .IN_P(in_p_reg), .IN_Q(in_q_reg), .IN_E(in_e_reg), .OUT_N(OUT_N), .OUT_D(OUT_D) );

// FSM
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else 
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE:state_ns = in_valid?RD:IDLE;
		RD : state_ns = doneRD?IDLE2:RD;
		IDLE2:state_ns = doneDecrypt?IDLE3:Set_C;
		Set_C:state_ns = OP;
		OP : state_ns = doneOP?IDLE2:OP;
		IDLE3: state_ns = DONE;
		DONE:state_ns = doneOUTPUT?IDLE:DONE;
		default:state_ns = state_cs;
	endcase
end

// Counter
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_ns==IDLE || state_ns==IDLE2 || state_ns==IDLE3)
		counter<=0;
	else if(state_ns==RD || state_ns ==OP || state_ns==DONE)
		counter<=counter+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_counter<=0;
	else if(state_ns == IDLE)
		round_counter<=0;
	else if(state_ns==IDLE2 && state_cs==OP)
		round_counter<=round_counter+1;
end
// reg
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<8;i=i+1)
			out_m_reg[i]<=0;
	else if(state_cs==IDLE)
		for(i=0;i<8;i=i+1)
			out_m_reg[i]<=0;
	else if(state_cs==OP && state_ns==IDLE2)
		out_m_reg[round_counter]<=tmp_mod1;
end
*/
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		OUT_N_reg<=0;
	else if(state_cs==RD && counter==7)
		OUT_N_reg<=OUT_N;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		OUT_D_reg<=0;
	else if(state_cs==RD && counter==7)
		OUT_D_reg<=OUT_D;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		in_p_reg<=0;
	else if(state_ns==RD && state_cs==IDLE)
		in_p_reg<=in_p;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		in_q_reg<=0;
	else if(state_ns==RD && state_cs==IDLE)
		in_q_reg<=in_q;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		in_e_reg<=0;
	else if(state_ns==RD && state_cs==IDLE)
		in_e_reg<=in_e;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<8;i=i+1)
			in_c_reg[i]<=0;
	else if(state_ns==RD || state_cs==RD)
		in_c_reg[counter]<=in_c;
	else if(state_cs==OP && state_ns==IDLE2)
		in_c_reg[round_counter]<=tmp_mod1;
end

reg [7:0]choose_val;
//reg [7:0]choose_val2;

reg [7:0]tmp_out1;
reg [7:0]tmp_out2;
reg [15:0]tmp_out3;

reg [7:0] round_c;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_c<=0;
	else if(state_ns==Set_C)
		round_c<=tmp_out1;
	
end

always@(*)begin
	if(state_ns== Set_C)
		choose_val = in_c_reg[round_counter];
	else if(state_ns==OP && counter==0)
		choose_val = 1;
	else if(state_ns==OP)
		choose_val = tmp_mod1;
	else
		choose_val = 0;
end
/*
always@(*)begin
	if(state_ns==OP && counter==0)
		choose_val2 = in_c_reg[round_counter];
	else if(state_ns==OP)
		choose_val2 = in_c_reg[round_counter];
	else
		choose_val2 = 0;
end
*/
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		tmp_mod1<=0;
	else if(state_ns==OP)
		tmp_mod1<=tmp_out3;
end
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		tmp_mod2<=0;
	else if(state_ns==OP)
		tmp_mod2<=choose_val2;
end
*/
// operation

always@(*)begin
	tmp_out1 = choose_val % OUT_N_reg;
end

always@(*)begin
	tmp_out3 = (tmp_out1*round_c) % OUT_N_reg;
end

//================================================================
// OUTPUT
//================================================================

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_m<=0;
	else if(state_ns==IDLE)
		out_m<=0;
	else if(state_ns==DONE)
		out_m<=in_c_reg[counter];
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_valid<=0;
	else if(state_ns==IDLE)
		out_valid<=0;
	else if(state_ns==DONE)
		out_valid<=1;
end

endmodule