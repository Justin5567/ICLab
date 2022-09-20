// synopsys translate_off 
`ifdef RTL
`include "GATED_OR.v"
`else
`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on
module IDC(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	op,
	// Output signals
	out_valid,
	out_data
);


// INPUT AND OUTPUT DECLARATION  
input		clk;
input		rst_n;
input		in_valid;
input		cg_en;
input signed [6:0] in_data;
input [3:0] op;

output reg 		  out_valid;//
output reg  signed [6:0] out_data;

//================================================================
// parameter and integer
//================================================================
integer i;

parameter IDLE 	= 4'd0;
parameter RD 	= 4'd1;
parameter IDLE2 = 4'd2;
parameter OP	= 4'd3;
parameter WR	= 4'd4;
parameter PLACE = 4'd6;
parameter DONE	= 4'd5;
//================================================================
// register and wire
//================================================================
reg [3:0] state_cs, state_ns;
reg [5:0] counter;
reg [3:0] round_counter;
reg signed [6:0] img_reg [0:63];
reg [3:0] op_reg [0:14];
reg [2:0] pos_x,pos_y;



wire [5:0]curr_position;
reg done_round;
wire move_op;
wire done_OP;
wire done_output;
wire [3:0]curr_op;

wire [5:0]window_idx0;
wire [5:0]window_idx1;
wire [5:0]window_idx2;
wire [5:0]window_idx3;



assign window_idx0 = curr_position;
assign window_idx1 = curr_position+1;
assign window_idx2 = curr_position+8;
assign window_idx3 = curr_position+9;

assign curr_position = {pos_y,pos_x};
assign done_OP = round_counter==15;
assign done_output = counter==16;
assign move_op = (curr_op==5 || curr_op==6 || curr_op==7 || curr_op==8 || curr_op==2 || curr_op==3);
assign curr_op = op_reg[round_counter];


reg sleep_img_r[0:63];
wire clk_img_r[0:63];

reg zoom_cg;
wire clk_zoom;

wire window_open_sig[0:63];


genvar window_open_idx;
generate
	for(window_open_idx = 0; window_open_idx<64; window_open_idx = window_open_idx+1)begin
		assign window_open_sig[window_open_idx] = (window_open_idx==window_idx0 || window_open_idx==window_idx1 || window_open_idx==window_idx2 || window_open_idx==window_idx3);
	end
endgenerate


always@(*)begin
	if(curr_op==4)
		done_round = counter==0;
	else
		done_round = counter==2;
end

//================================================================
// Clock gate
//================================================================
// 1 => gated, 0 => not gated
genvar sleep_idx;
generate
	for(sleep_idx = 0; sleep_idx<64; sleep_idx = sleep_idx+1)begin
		always@(*)begin
			if(state_ns==RD)begin
				if(counter==sleep_idx)
					sleep_img_r[sleep_idx] = 0;
				else
					sleep_img_r[sleep_idx] = 1;
			end
			else if(state_ns==IDLE)
				sleep_img_r[sleep_idx] = 0;
			else if(state_cs==IDLE2 && state_ns==IDLE2)begin
				if(sleep_idx==window_idx0 || sleep_idx==window_idx1 || sleep_idx==window_idx2 || sleep_idx==window_idx3)
					sleep_img_r[sleep_idx] = 0;
				else
					sleep_img_r[sleep_idx] = 0;
					
			end
			else if(state_cs==WR || state_cs==OP)begin
				if(sleep_idx==window_idx0 || sleep_idx==window_idx1 || sleep_idx==window_idx2 || sleep_idx==window_idx3)
					sleep_img_r[sleep_idx] = 0;
				else
					sleep_img_r[sleep_idx] = 1;
			end
			else if(state_ns==PLACE)
				sleep_img_r[sleep_idx] = 0;
			else if(state_ns==DONE)
				sleep_img_r[sleep_idx] = 1;
			else 
				sleep_img_r[sleep_idx] = 0;
		end
	end
endgenerate
//zoom cg

always@(*)begin
	if(state_ns==PLACE || state_ns==DONE)
		zoom_cg = 0;
	else
		zoom_cg = 1;
end

GATED_OR GATED_z0 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg), .RST_N(rst_n), .CLOCK_GATED(clk_zoom));
/*
GATED_OR GATED_z1 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[1]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[1]));
GATED_OR GATED_z2 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[2]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[2]));
GATED_OR GATED_z3 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[3]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[3]));
GATED_OR GATED_z4 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[4]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[4]));
GATED_OR GATED_z5 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[5]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[5]));
GATED_OR GATED_z6 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[6]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[6]));
GATED_OR GATED_z7 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[7]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[7]));
GATED_OR GATED_z8 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[8]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[8]));
GATED_OR GATED_z9 ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[9]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[9]));
GATED_OR GATED_z10( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[10]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[10]));
GATED_OR GATED_z11( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[11]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[11]));
GATED_OR GATED_z12( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[12]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[12]));
GATED_OR GATED_z13( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[13]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[13]));
GATED_OR GATED_z14( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[14]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[14]));
GATED_OR GATED_z15( .CLOCK(clk), .SLEEP_CTRL(cg_en&&zoom_cg[15]), .RST_N(rst_n), .CLOCK_GATED(clk_zoom[15]));
*/
// img cg
GATED_OR GATED_r0( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[0]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[0]));
GATED_OR GATED_r1( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[1]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[1]));
GATED_OR GATED_r2( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[2]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[2]));
GATED_OR GATED_r3( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[3]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[3]));
GATED_OR GATED_r4( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[4]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[4]));
GATED_OR GATED_r5( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[5]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[5]));
GATED_OR GATED_r6( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[6]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[6]));
GATED_OR GATED_r7( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[7]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[7]));
GATED_OR GATED_r8( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[8]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[8]));
GATED_OR GATED_r9( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[9]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[9]));

GATED_OR GATED_r10( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[10]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[10]));
GATED_OR GATED_r11( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[11]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[11]));
GATED_OR GATED_r12( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[12]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[12]));
GATED_OR GATED_r13( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[13]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[13]));
GATED_OR GATED_r14( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[14]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[14]));
GATED_OR GATED_r15( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[15]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[15]));
GATED_OR GATED_r16( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[16]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[16]));
GATED_OR GATED_r17( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[17]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[17]));
GATED_OR GATED_r18( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[18]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[18]));
GATED_OR GATED_r19( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[19]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[19]));

GATED_OR GATED_r20( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[20]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[20]));
GATED_OR GATED_r21( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[21]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[21]));
GATED_OR GATED_r22( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[22]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[22]));
GATED_OR GATED_r23( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[23]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[23]));
GATED_OR GATED_r24( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[24]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[24]));
GATED_OR GATED_r25( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[25]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[25]));
GATED_OR GATED_r26( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[26]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[26]));
GATED_OR GATED_r27( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[27]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[27]));
GATED_OR GATED_r28( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[28]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[28]));
GATED_OR GATED_r29( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[29]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[29]));

GATED_OR GATED_r30( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[30]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[30]));
GATED_OR GATED_r31( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[31]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[31]));
GATED_OR GATED_r32( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[32]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[32]));
GATED_OR GATED_r33( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[33]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[33]));
GATED_OR GATED_r34( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[34]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[34]));
GATED_OR GATED_r35( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[35]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[35]));
GATED_OR GATED_r36( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[36]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[36]));
GATED_OR GATED_r37( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[37]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[37]));
GATED_OR GATED_r38( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[38]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[38]));
GATED_OR GATED_r39( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[39]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[39]));

GATED_OR GATED_r40( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[40]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[40]));
GATED_OR GATED_r41( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[41]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[41]));
GATED_OR GATED_r42( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[42]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[42]));
GATED_OR GATED_r43( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[43]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[43]));
GATED_OR GATED_r44( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[44]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[44]));
GATED_OR GATED_r45( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[45]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[45]));
GATED_OR GATED_r46( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[46]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[46]));
GATED_OR GATED_r47( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[47]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[47]));
GATED_OR GATED_r48( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[48]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[48]));
GATED_OR GATED_r49( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[49]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[49]));

GATED_OR GATED_r50( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[50]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[50]));
GATED_OR GATED_r51( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[51]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[51]));
GATED_OR GATED_r52( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[52]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[52]));
GATED_OR GATED_r53( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[53]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[53]));
GATED_OR GATED_r54( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[54]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[54]));
GATED_OR GATED_r55( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[55]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[55]));
GATED_OR GATED_r56( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[56]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[56]));
GATED_OR GATED_r57( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[57]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[57]));
GATED_OR GATED_r58( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[58]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[58]));
GATED_OR GATED_r59( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[59]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[59]));

GATED_OR GATED_r60( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[60]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[60]));
GATED_OR GATED_r61( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[61]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[61]));
GATED_OR GATED_r62( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[62]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[62]));
GATED_OR GATED_r63( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_img_r[63]), .RST_N(rst_n), .CLOCK_GATED(clk_img_r[63]));

//================================================================
// Design
//================================================================
// fsm
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else 
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE: 		state_ns = (in_valid)?RD:IDLE;
		RD :		state_ns = (!in_valid)?IDLE2:RD;
		IDLE2: 		state_ns = (done_OP)?PLACE:(move_op)?IDLE2:OP;
		OP: 		state_ns = done_round?WR:OP;
		WR:			state_ns = IDLE2;
		PLACE:		state_ns = DONE;
		DONE: 		state_ns = (done_output)?IDLE:DONE;
		default: 	state_ns = state_cs;
	endcase
end	


// reg
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		pos_x<=0;
	else if(state_ns==IDLE)
		pos_x<=3;
	else if(state_cs==IDLE2 && state_ns==IDLE2)begin
		if(curr_op==5) //up
			pos_x<=pos_x;
		else if(curr_op==6)begin //left
			if(pos_x==0)
				pos_x<=pos_x;
			else
				pos_x<=pos_x-1;
		end
		else if(curr_op==7) //down
			pos_x<=pos_x;
		else if(curr_op==8)begin //right
			if(pos_x==6)
				pos_x<=pos_x;
			else
				pos_x<=pos_x+1;
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		pos_y<=0;
	else if(state_ns==IDLE)
		pos_y<=3;
	else if(state_cs==IDLE2 && state_ns==IDLE2)begin
		if(curr_op==5)begin //up
			if(pos_y==0)
				pos_y<=pos_y;
			else
				pos_y<=pos_y-1;
		end
		else if(curr_op==6) //left
			pos_y<=pos_y;
		else if(curr_op==7)begin //down
			if(pos_y==6)
				pos_y<=pos_y;
			else
				pos_y<=pos_y+1;
		end
		else if(curr_op==8) //right
			pos_y<=pos_y;
	end
end


reg signed [6:0] window_reg[0:3];
reg signed [8:0] tmp_reg_1;
reg signed [7:0] tmp_reg_2;


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		tmp_reg_1<=0;
	else if(state_cs==OP && curr_op==1)begin
		tmp_reg_1<=img_reg[window_idx0]+img_reg[window_idx1];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		tmp_reg_2<=0;
	else if(state_cs==OP && curr_op==1)begin
		tmp_reg_2<=img_reg[window_idx2]+img_reg[window_idx3];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			window_reg[i]<=0;
	else if(state_cs==IDLE2 && state_ns==OP)begin
		window_reg[0]<=img_reg[window_idx0];
		window_reg[1]<=img_reg[window_idx1];
		window_reg[2]<=img_reg[window_idx2];
		window_reg[3]<=img_reg[window_idx3];
	end
	else if(state_cs==OP  && curr_op==0)begin
		case(counter)
			0:begin
				// group 1
				if(window_reg[0]<window_reg[1])begin
					window_reg[0] <= window_reg[1];
					window_reg[1] <= window_reg[0];
				end
				// group 2
				if(window_reg[2]<window_reg[3]) begin
					window_reg[2] <= window_reg[3];
					window_reg[3] <= window_reg[2];
				end
			end
			1:begin
				if(window_reg[0]>window_reg[2])begin
					window_reg[0]<=window_reg[0];
					window_reg[1]<=window_reg[2];
				end
				else begin
					window_reg[0]<=window_reg[2];
					window_reg[1]<=window_reg[0];
				end
				if(window_reg[1]>window_reg[3])begin
					window_reg[2]<=window_reg[1];
					window_reg[3]<=window_reg[3];
				end
				else begin
					window_reg[2]<=window_reg[3];
					window_reg[3]<=window_reg[1];
				end
			end
			2:begin
				window_reg[0]<=(window_reg[1]+window_reg[2])/2; 
				window_reg[1]<=(window_reg[1]+window_reg[2])/2; 
				window_reg[2]<=(window_reg[1]+window_reg[2])/2; 
				window_reg[3]<=(window_reg[1]+window_reg[2])/2; 
			end
		endcase
	end
	else if(state_cs==OP  && curr_op==1)begin
		if(counter==1)begin
			window_reg[0]<=(tmp_reg_1+tmp_reg_2)/4;
		end
		else begin
			window_reg[0]<=window_reg[0];
			window_reg[1]<=window_reg[0];
			window_reg[2]<=window_reg[0];
			window_reg[3]<=window_reg[0];
		end
	end
	else if(state_cs==OP && curr_op==4)begin
		window_reg[0]<=window_reg[0]*-1 ;
		window_reg[1]<=window_reg[1]*-1 ;
		window_reg[2]<=window_reg[2]*-1 ;
		window_reg[3]<=window_reg[3]*-1 ;
	end
end

genvar img_reg_idx;
generate
	for(img_reg_idx = 0; img_reg_idx<64; img_reg_idx = img_reg_idx+1)begin
		always@(posedge clk_img_r[img_reg_idx] or negedge rst_n)begin
			if(!rst_n)
				img_reg[img_reg_idx]<=0;
			else if(state_ns==IDLE)
				img_reg[img_reg_idx]<=0;
			else if(state_ns==RD && img_reg_idx==counter)
				img_reg[img_reg_idx]<=in_data;
			else if(state_cs==RD && state_ns==IDLE2)begin
			
			end
			else if(window_open_sig[img_reg_idx]==1)begin
				if(state_ns==IDLE2 && curr_op==2)begin
					if(img_reg_idx==window_idx0)
						img_reg[img_reg_idx]<=img_reg[window_idx1];
					else if(img_reg_idx==window_idx1)
						img_reg[img_reg_idx]<=img_reg[window_idx3];
					else if(img_reg_idx==window_idx2)
						img_reg[img_reg_idx]<=img_reg[window_idx0];
					else if(img_reg_idx==window_idx3)
						img_reg[img_reg_idx]<=img_reg[window_idx2];
				end
				else if(state_ns==IDLE2 && curr_op==3)begin
					if(img_reg_idx==window_idx0)
						img_reg[img_reg_idx]<=img_reg[window_idx2];
					else if(img_reg_idx==window_idx1)
						img_reg[img_reg_idx]<=img_reg[window_idx0];
					else if(img_reg_idx==window_idx2)
						img_reg[img_reg_idx]<=img_reg[window_idx3];
					else if(img_reg_idx==window_idx3)
						img_reg[img_reg_idx]<=img_reg[window_idx1];
				end
				else if(state_cs==WR && (curr_op==4||curr_op==0 || curr_op==1))begin
					if(img_reg_idx==window_idx0)
						img_reg[img_reg_idx]<=window_reg[0];
					else if(img_reg_idx==window_idx1)
						img_reg[img_reg_idx]<=window_reg[1];
					else if(img_reg_idx==window_idx2)
						img_reg[img_reg_idx]<=window_reg[2];
					else if(img_reg_idx==window_idx3)
						img_reg[img_reg_idx]<=window_reg[3];
				end
			end
		end
	end
endgenerate


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<15;i=i+1)
			op_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<15;i=i+1)
			op_reg[i]<=0;
	else if(state_ns==RD)
		op_reg[counter]<=op;
end




// counter
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_ns==IDLE2 || state_ns==IDLE)
		counter<=0;
	else if(state_cs==OP || state_ns==RD || state_ns == DONE)
		counter<=counter+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_counter<=0;
	else if(state_ns==IDLE)
		round_counter<=0;
	else if((state_cs==WR || state_cs==IDLE2) && state_ns==IDLE2)
		round_counter<=round_counter+1;
end

// output signals
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_valid<=0;
	else if(state_ns==IDLE)
		out_valid<=0;
	else if(state_ns==DONE)
		out_valid<=1;
end


reg signed [6:0] zoom [0:15];

always@(posedge clk_zoom or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<16;i=i+1)
			zoom[i]<=0;
	else if(state_ns==PLACE)begin
		if(pos_x<4 && pos_y<4)begin
			zoom[0] <= img_reg[curr_position+9];
			zoom[1] <= img_reg[curr_position+10];
			zoom[2] <= img_reg[curr_position+11];
			zoom[3] <= img_reg[curr_position+12];
			zoom[4] <= img_reg[curr_position+17];
			zoom[5] <= img_reg[curr_position+18];
			zoom[6] <= img_reg[curr_position+19];
			zoom[7] <= img_reg[curr_position+20];
			zoom[8] <= img_reg[curr_position+25];
			zoom[9] <= img_reg[curr_position+26];
			zoom[10] <= img_reg[curr_position+27];
			zoom[11] <= img_reg[curr_position+28];
			zoom[12] <= img_reg[curr_position+33];
			zoom[13] <= img_reg[curr_position+34];
			zoom[14] <= img_reg[curr_position+35];
			zoom[15] <= img_reg[curr_position+36];
		end
		else begin
			zoom[0] <= img_reg[0];
			zoom[1] <= img_reg[2];
			zoom[2] <= img_reg[4];
			zoom[3] <= img_reg[6];
			zoom[4] <= img_reg[16];
			zoom[5] <= img_reg[18];
			zoom[6] <= img_reg[20];
			zoom[7] <= img_reg[22];
			zoom[8] <= img_reg[32];
			zoom[9] <= img_reg[34];
			zoom[10] <= img_reg[36];
			zoom[11] <= img_reg[38];
			zoom[12] <= img_reg[48];
			zoom[13] <= img_reg[50];
			zoom[14] <= img_reg[52];
			zoom[15] <= img_reg[54];
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_data<=0;
	else if(state_ns==IDLE)
		out_data<=0;
	else if(state_ns==DONE)begin
		out_data<=zoom[counter];
	end
end



endmodule // IDC