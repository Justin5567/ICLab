module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_i,
	in_valid_k,
	in_valid_o,
	Image1,
	Image2,
	Image3,
	Kernel1,
	Kernel2,
	Kernel3,
	Opt,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch = 2;
parameter faithful_round = 0;
//--------------------------------
input  clk, rst_n, in_valid_i, in_valid_k, in_valid_o;
input [inst_sig_width+inst_exp_width:0] Image1, Image2, Image3;
input [inst_sig_width+inst_exp_width:0] Kernel1, Kernel2, Kernel3;
input [1:0] Opt;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------



// My parameter
parameter IDLE 		= 4'd0;
parameter RD_OPT 	= 4'd1;
parameter IDLE2 	= 4'd2;
parameter RD_IMG 	= 4'd3;
parameter IDLE3 	= 4'd4;
parameter RD_KER 	= 4'd5;
parameter IDLE4 	= 4'd6;

parameter COMP_K1	= 4'd9;
parameter COMP_K2	= 4'd10;
parameter COMP_K3	= 4'd11;
parameter IDLE5 	= 4'd12;
parameter COMP_OPT	= 4'd13;
parameter IDLE6 	= 4'd14;
parameter DONE 		= 4'd15;
parameter HOLD		=4'd7;
parameter HOLD2		=4'd8;
// Integer
integer i;

//---------------------------------------------------------------------
//   Reg & Wire
//---------------------------------------------------------------------
reg [3:0] state_cs,state_ns;
reg [9:0] counter;
reg [5:0] counter_img;
reg [5:0] counter_ker;
reg [1:0] Opt_reg;
reg [31:0]Image1_reg[0:15];
reg [31:0]Image2_reg[0:15];
reg [31:0]Image3_reg[0:15];
reg [31:0]Kernel1_reg [0:35];
reg [31:0]Kernel2_reg [0:35];
reg [31:0]Kernel3_reg [0:35];

reg [31:0]PICK_KERNEL [0:8];
reg [31:0]PICK_IMAGE  [0:8];

reg [31:0] output_reg [0:63];

reg doneALL;

wire doneReadImg;
wire doneReadKer;
wire doneCNN;
wire doneIMG;
wire doneKER;
wire doneOPT;
wire doneOUTPUT;

wire [31:0] mult_sum[0:8];
wire [31:0] add_sum[0:8];
wire [31:0] Leaky_Relu_Sum;
wire [31:0] curr_output_reg;
reg [5:0]counter2idx;
reg [5:0]past_counter2idx;

wire [31:0]leaky_relu_int;
assign leaky_relu_int = 32'b00111101110011001100110011001101;

wire [31:0]one_int;
assign one_int = 32'b00111111100000000000000000000000;

wire [31:0]neg_exp;
wire [31:0]pos_exp;
wire [31:0]tmp_add_sum;
wire [31:0]div_done_sum;

wire [31:0]case_four_sub_sum;

reg [31:0] round_add;


reg [31:0]OPT_add_selector;
reg [31:0]OPT_div_selector;
reg [31:0] pos_output_reg;
reg [31:0]neg_output_reg;

always@(*)begin
	if(Opt_reg==2)
		OPT_add_selector = one_int;
	else if(Opt_reg==3)
		OPT_add_selector = pos_exp;
	else
		OPT_add_selector = 32'd0;
end

always@(*)begin
	if(Opt_reg==2)
		OPT_div_selector = one_int;
	else if(Opt_reg==3)
		OPT_div_selector = case_four_sub_sum;
	else
		OPT_div_selector = 32'd0;
end

//---------------------------------------------------------------------
//   IP
//---------------------------------------------------------------------
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M0 (.a(PICK_IMAGE[0]), .b(PICK_KERNEL[0]), .rnd(3'b000), .z(mult_sum[0]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1 (.a(PICK_IMAGE[1]), .b(PICK_KERNEL[1]), .rnd(3'b000), .z(mult_sum[1]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2 (.a(PICK_IMAGE[2]), .b(PICK_KERNEL[2]), .rnd(3'b000), .z(mult_sum[2]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M3 (.a(PICK_IMAGE[3]), .b(PICK_KERNEL[3]), .rnd(3'b000), .z(mult_sum[3]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M4 (.a(PICK_IMAGE[4]), .b(PICK_KERNEL[4]), .rnd(3'b000), .z(mult_sum[4]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M5 (.a(PICK_IMAGE[5]), .b(PICK_KERNEL[5]), .rnd(3'b000), .z(mult_sum[5]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M6 (.a(PICK_IMAGE[6]), .b(PICK_KERNEL[6]), .rnd(3'b000), .z(mult_sum[6]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M7 (.a(PICK_IMAGE[7]), .b(PICK_KERNEL[7]), .rnd(3'b000), .z(mult_sum[7]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M8 (.a(PICK_IMAGE[8]), .b(PICK_KERNEL[8]), .rnd(3'b000), .z(mult_sum[8]));

wire [31:0]tmp2_add[0:8];
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(mult_sum[0]), .b(round_add), .rnd(3'b000), .z(tmp2_add[0]));//1
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U2 ( .a(mult_sum[1]), .b(mult_sum[2]), .rnd(3'b000), .z(tmp2_add[1]));//1
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U3 ( .a(mult_sum[3]), .b(mult_sum[4]), .rnd(3'b000), .z(tmp2_add[2]));//1
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U4 ( .a(mult_sum[5]), .b(mult_sum[6]), .rnd(3'b000), .z(tmp2_add[3]));//1
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U5 ( .a(mult_sum[7]), .b(mult_sum[8]), .rnd(3'b000), .z(tmp2_add[4]));//1
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U6 ( .a(tmp2_add[0]), .b(tmp2_add[1]), .rnd(3'b000), .z(tmp2_add[5]));//2
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U7 ( .a(tmp2_add[2]), .b(tmp2_add[3]), .rnd(3'b000), .z(tmp2_add[6]));//2
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U8 ( .a(tmp2_add[4]), .b(tmp2_add[5]), .rnd(3'b000), .z(tmp2_add[7]));//2+3
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U9 ( .a(tmp2_add[6]), .b(tmp2_add[7]), .rnd(3'b000), .z(tmp2_add[8]));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) L3 (.a(leaky_relu_int), .b(pos_output_reg), .rnd(3'b000), .z(Leaky_Relu_Sum)); //e^-x



always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		neg_output_reg<=0;
	else if(state_cs==HOLD)
		neg_output_reg<={!round_add[31],round_add[30:0]};
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		pos_output_reg<=0;
	else if(state_cs==HOLD)
		pos_output_reg<=round_add;
end
//assign neg_output_reg={!output_reg[past_counter2idx][31],output_reg[past_counter2idx][30:0]};

// opt3
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) E0 (.a(neg_output_reg),.z(neg_exp) );

// opt4
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) E1 (.a(pos_output_reg),.z(pos_exp) );
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) S0 ( .a(pos_exp), .b(neg_exp), .rnd(3'b000), .z(case_four_sub_sum) );

// opt3 and opt 4 reuse
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A0 ( .a(OPT_add_selector), .b(neg_exp), .rnd(3'b000), .z(tmp_add_sum) ); 
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) D0 ( .a(OPT_div_selector), .b(tmp_add_sum), .rnd(3'b000), .z(div_done_sum));

//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else 
		state_cs<=state_ns;
end


always@(*)begin
	case(state_cs)
		IDLE 	: state_ns = (in_valid_o==1)?RD_OPT:IDLE;
		RD_OPT	: state_ns = IDLE2;
		IDLE2	: state_ns = (in_valid_i)?RD_IMG:IDLE2;
		RD_IMG	: state_ns = (doneReadImg)?IDLE3:RD_IMG;
		IDLE3	: state_ns = (in_valid_k)?RD_KER:IDLE3;
		RD_KER	: state_ns = (doneReadKer)?IDLE4:RD_KER;
		IDLE4	: state_ns = COMP_K1;
		//SETUP_KER : state_ns = SETUP_IMG;
		//SETUP_IMG : state_ns = COMP_K1;
		COMP_K1 : state_ns = COMP_K2;
		COMP_K2 : state_ns = COMP_K3;
		COMP_K3 : state_ns = HOLD;
		HOLD	: state_ns = HOLD2;
		HOLD2	: state_ns = (doneALL)?COMP_OPT:COMP_K1;
		//COMP_K3 : state_ns = (doneKER && doneIMG)?COMP_OPT:COMP_K1;
		//IDLE5 	: state_ns = (doneKER && doneIMG)?COMP_OPT:(doneIMG)?SETUP_KER:SETUP_IMG;
		COMP_OPT: state_ns = (doneOPT)?IDLE6:COMP_OPT;
		IDLE6 	: state_ns = DONE;
		DONE	: state_ns = (doneOUTPUT)?IDLE:DONE;
		default : state_ns = state_cs;
	endcase
end

assign doneKER = counter_ker==3;
assign doneIMG = counter_img==15;

assign doneReadImg = counter==15;
assign doneReadKer = counter==35;
assign doneOPT 	  = counter==1;
assign doneOUTPUT = counter==64;


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		doneALL<=0;
	else if(state_cs==IDLE)
		doneALL<=0;
	else if(state_cs==COMP_K1 && doneKER && doneIMG)
		doneALL<=1;
	
end

//---------------------------------------------------------------------
//   Counter
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter2idx<=0;
	else if(state_ns==COMP_K1 || state_ns==COMP_OPT) begin
		case(counter_ker)
			0:begin
				case(counter_img)
					0: counter2idx <= 0;
					1: counter2idx <= 2;
					2: counter2idx <= 4;
					3: counter2idx <= 6;
					4: counter2idx <= 16;
					5: counter2idx <= 18;
					6: counter2idx <= 20;
					7: counter2idx <= 22;
					8: counter2idx <= 32;
					9: counter2idx <= 34;
					10:counter2idx <= 36;
					11:counter2idx <= 38;
					12:counter2idx <= 48;
					13:counter2idx <= 50;
					14:counter2idx <= 52;
					15:counter2idx <= 54;
					default: counter2idx <=0;
				endcase
			end
			1:begin
				case(counter_img)
					0: counter2idx <= 1;
					1: counter2idx <= 3;
					2: counter2idx <= 5;
					3: counter2idx <= 7;
					4: counter2idx <= 17;
					5: counter2idx <= 19;
					6: counter2idx <= 21;
					7: counter2idx <= 23;
					8: counter2idx <= 33;
					9: counter2idx <= 35;
					10:counter2idx <= 37;
					11:counter2idx <= 39;
					12:counter2idx <= 49;
					13:counter2idx <= 51;
					14:counter2idx <= 53;
					15:counter2idx <= 55;
					default: counter2idx <=0;
				endcase
			end
			2:begin
				case(counter_img)
					0: counter2idx <= 8;
					1: counter2idx <= 10;
					2: counter2idx <= 12;
					3: counter2idx <= 14;
					4: counter2idx <= 24;
					5: counter2idx <= 26;
					6: counter2idx <= 28;
					7: counter2idx <= 30;
					8: counter2idx <= 40;
					9: counter2idx <= 42;
					10:counter2idx <= 44;
					11:counter2idx <= 46;
					12:counter2idx <= 56;
					13:counter2idx <= 58;
					14:counter2idx <= 60;
					15:counter2idx <= 62;
					default: counter2idx <=0;
				endcase
			end
			3:begin
				case(counter_img)
					0: counter2idx <= 9;
					1: counter2idx <= 11;
					2: counter2idx <= 13;
					3: counter2idx <= 15;
					4: counter2idx <= 25;
					5: counter2idx <= 27;
					6: counter2idx <= 29;
					7: counter2idx <= 31;
					8: counter2idx <= 41;
					9: counter2idx <= 43;
					10:counter2idx <= 45;
					11:counter2idx <= 47;
					12:counter2idx <= 57;
					13:counter2idx <= 59;
					14:counter2idx <= 61;
					15:counter2idx <= 63;
					default: counter2idx <=0;
				endcase
			end
			default: counter2idx <= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_ns == IDLE || state_ns == IDLE2 || state_ns == IDLE3 || state_ns == IDLE4 || state_ns==IDLE5 || state_ns==IDLE6)
		counter<=0;
	else if(state_ns==RD_IMG || state_ns==RD_KER || state_ns==COMP_OPT ||state_ns==DONE)
		counter<=counter+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter_img<=0;
	else if(state_ns==IDLE)
		counter_img<=0;
	else if(state_ns==HOLD2 && doneIMG)
		counter_img<=0;
	else if(state_ns==HOLD2)
		counter_img<=counter_img+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter_ker<=0;
	else if(state_ns==IDLE)
		counter_ker<=0;
	else if(state_ns==COMP_K3 && doneIMG)
		counter_ker<=counter_ker+1;
end


//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		Opt_reg<=0;
	else if(state_ns==IDLE)
		Opt_reg<=0;
	else if(state_ns==RD_OPT)
		Opt_reg<=Opt;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<16;i=i+1)
			Image1_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<16;i=i+1)
			Image1_reg[i]<=0;
	else if(state_ns==RD_IMG || state_cs==RD_IMG)
		Image1_reg[counter]<=Image1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<16;i=i+1)
			Image2_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<16;i=i+1)
			Image2_reg[i]<=0;
	else if(state_ns==RD_IMG || state_cs==RD_IMG)
		Image2_reg[counter]<=Image2;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<16;i=i+1)
			Image3_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<16;i=i+1)
			Image3_reg[i]<=0;
	else if(state_ns==RD_IMG || state_cs==RD_IMG)
		Image3_reg[counter]<=Image3;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<36;i=i+1)
			Kernel1_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<36;i=i+1)
			Kernel1_reg[i]<=0;
	else if(state_ns==RD_KER || state_cs==RD_KER)
		Kernel1_reg[counter]<=Kernel1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<36;i=i+1)
			Kernel2_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<36;i=i+1)
			Kernel2_reg[i]<=0;
	else if(state_ns==RD_KER || state_cs==RD_KER)
		Kernel2_reg[counter]<=Kernel2;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<36;i=i+1)
			Kernel3_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<36;i=i+1)
			Kernel3_reg[i]<=0;
	else if(state_ns==RD_KER || state_cs==RD_KER)
		Kernel3_reg[counter]<=Kernel3;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<9;i=i+1)
			PICK_IMAGE[i] <= 0;
	else if(Opt_reg[1]==0)begin
		case(counter_img)
			0:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[0];
					PICK_IMAGE[1] <= Image1_reg[0];
					PICK_IMAGE[2] <= Image1_reg[1];
					PICK_IMAGE[3] <= Image1_reg[0];
					PICK_IMAGE[4] <= Image1_reg[0];
					PICK_IMAGE[5] <= Image1_reg[1];
					PICK_IMAGE[6] <= Image1_reg[4];
					PICK_IMAGE[7] <= Image1_reg[4];
					PICK_IMAGE[8] <= Image1_reg[5];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[0];
					PICK_IMAGE[1] <= Image2_reg[0];
					PICK_IMAGE[2] <= Image2_reg[1];
					PICK_IMAGE[3] <= Image2_reg[0];
					PICK_IMAGE[4] <= Image2_reg[0];
					PICK_IMAGE[5] <= Image2_reg[1];
					PICK_IMAGE[6] <= Image2_reg[4];
					PICK_IMAGE[7] <= Image2_reg[4];
					PICK_IMAGE[8] <= Image2_reg[5];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[0];
					PICK_IMAGE[1] <= Image3_reg[0];
					PICK_IMAGE[2] <= Image3_reg[1];
					PICK_IMAGE[3] <= Image3_reg[0];
					PICK_IMAGE[4] <= Image3_reg[0];
					PICK_IMAGE[5] <= Image3_reg[1];
					PICK_IMAGE[6] <= Image3_reg[4];
					PICK_IMAGE[7] <= Image3_reg[4];
					PICK_IMAGE[8] <= Image3_reg[5];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			1:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[0];
					PICK_IMAGE[1] <= Image1_reg[1];
					PICK_IMAGE[2] <= Image1_reg[2];
					PICK_IMAGE[3] <= Image1_reg[0];
					PICK_IMAGE[4] <= Image1_reg[1];
					PICK_IMAGE[5] <= Image1_reg[2];
					PICK_IMAGE[6] <= Image1_reg[4];
					PICK_IMAGE[7] <= Image1_reg[5];
					PICK_IMAGE[8] <= Image1_reg[6];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[0];
					PICK_IMAGE[1] <= Image2_reg[1];
					PICK_IMAGE[2] <= Image2_reg[2];
					PICK_IMAGE[3] <= Image2_reg[0];
					PICK_IMAGE[4] <= Image2_reg[1];
					PICK_IMAGE[5] <= Image2_reg[2];
					PICK_IMAGE[6] <= Image2_reg[4];
					PICK_IMAGE[7] <= Image2_reg[5];
					PICK_IMAGE[8] <= Image2_reg[6];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[0];
					PICK_IMAGE[1] <= Image3_reg[1];
					PICK_IMAGE[2] <= Image3_reg[2];
					PICK_IMAGE[3] <= Image3_reg[0];
					PICK_IMAGE[4] <= Image3_reg[1];
					PICK_IMAGE[5] <= Image3_reg[2];
					PICK_IMAGE[6] <= Image3_reg[4];
					PICK_IMAGE[7] <= Image3_reg[5];
					PICK_IMAGE[8] <= Image3_reg[6];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			2:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[1];
					PICK_IMAGE[1] <= Image1_reg[2];
					PICK_IMAGE[2] <= Image1_reg[3];
					PICK_IMAGE[3] <= Image1_reg[1];
					PICK_IMAGE[4] <= Image1_reg[2];
					PICK_IMAGE[5] <= Image1_reg[3];
					PICK_IMAGE[6] <= Image1_reg[5];
					PICK_IMAGE[7] <= Image1_reg[6];
					PICK_IMAGE[8] <= Image1_reg[7];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[1];
					PICK_IMAGE[1] <= Image2_reg[2];
					PICK_IMAGE[2] <= Image2_reg[3];
					PICK_IMAGE[3] <= Image2_reg[1];
					PICK_IMAGE[4] <= Image2_reg[2];
					PICK_IMAGE[5] <= Image2_reg[3];
					PICK_IMAGE[6] <= Image2_reg[5];
					PICK_IMAGE[7] <= Image2_reg[6];
					PICK_IMAGE[8] <= Image2_reg[7];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[1];
					PICK_IMAGE[1] <= Image3_reg[2];
					PICK_IMAGE[2] <= Image3_reg[3];
					PICK_IMAGE[3] <= Image3_reg[1];
					PICK_IMAGE[4] <= Image3_reg[2];
					PICK_IMAGE[5] <= Image3_reg[3];
					PICK_IMAGE[6] <= Image3_reg[5];
					PICK_IMAGE[7] <= Image3_reg[6];
					PICK_IMAGE[8] <= Image3_reg[7];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			3:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[2];
					PICK_IMAGE[1] <= Image1_reg[3];
					PICK_IMAGE[2] <= Image1_reg[3];
					PICK_IMAGE[3] <= Image1_reg[2];
					PICK_IMAGE[4] <= Image1_reg[3];
					PICK_IMAGE[5] <= Image1_reg[3];
					PICK_IMAGE[6] <= Image1_reg[6];
					PICK_IMAGE[7] <= Image1_reg[7];
					PICK_IMAGE[8] <= Image1_reg[7];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[2];
					PICK_IMAGE[1] <= Image2_reg[3];
					PICK_IMAGE[2] <= Image2_reg[3];
					PICK_IMAGE[3] <= Image2_reg[2];
					PICK_IMAGE[4] <= Image2_reg[3];
					PICK_IMAGE[5] <= Image2_reg[3];
					PICK_IMAGE[6] <= Image2_reg[6];
					PICK_IMAGE[7] <= Image2_reg[7];
					PICK_IMAGE[8] <= Image2_reg[7];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[2];
					PICK_IMAGE[1] <= Image3_reg[3];
					PICK_IMAGE[2] <= Image3_reg[3];
					PICK_IMAGE[3] <= Image3_reg[2];
					PICK_IMAGE[4] <= Image3_reg[3];
					PICK_IMAGE[5] <= Image3_reg[3];
					PICK_IMAGE[6] <= Image3_reg[6];
					PICK_IMAGE[7] <= Image3_reg[7];
					PICK_IMAGE[8] <= Image3_reg[7];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			4:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[0];
					PICK_IMAGE[1] <= Image1_reg[0];
					PICK_IMAGE[2] <= Image1_reg[1];
					PICK_IMAGE[3] <= Image1_reg[4];
					PICK_IMAGE[4] <= Image1_reg[4];
					PICK_IMAGE[5] <= Image1_reg[5];
					PICK_IMAGE[6] <= Image1_reg[8];
					PICK_IMAGE[7] <= Image1_reg[8];
					PICK_IMAGE[8] <= Image1_reg[9];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[0];
					PICK_IMAGE[1] <= Image2_reg[0];
					PICK_IMAGE[2] <= Image2_reg[1];
					PICK_IMAGE[3] <= Image2_reg[4];
					PICK_IMAGE[4] <= Image2_reg[4];
					PICK_IMAGE[5] <= Image2_reg[5];
					PICK_IMAGE[6] <= Image2_reg[8];
					PICK_IMAGE[7] <= Image2_reg[8];
					PICK_IMAGE[8] <= Image2_reg[9];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[0];
					PICK_IMAGE[1] <= Image3_reg[0];
					PICK_IMAGE[2] <= Image3_reg[1];
					PICK_IMAGE[3] <= Image3_reg[4];
					PICK_IMAGE[4] <= Image3_reg[4];
					PICK_IMAGE[5] <= Image3_reg[5];
					PICK_IMAGE[6] <= Image3_reg[8];
					PICK_IMAGE[7] <= Image3_reg[8];
					PICK_IMAGE[8] <= Image3_reg[9];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			5:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[0];
					PICK_IMAGE[1] <= Image1_reg[1];
					PICK_IMAGE[2] <= Image1_reg[2];
					PICK_IMAGE[3] <= Image1_reg[4];
					PICK_IMAGE[4] <= Image1_reg[5];
					PICK_IMAGE[5] <= Image1_reg[6];
					PICK_IMAGE[6] <= Image1_reg[8];
					PICK_IMAGE[7] <= Image1_reg[9];
					PICK_IMAGE[8] <= Image1_reg[10];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[0];
					PICK_IMAGE[1] <= Image2_reg[1];
					PICK_IMAGE[2] <= Image2_reg[2];
					PICK_IMAGE[3] <= Image2_reg[4];
					PICK_IMAGE[4] <= Image2_reg[5];
					PICK_IMAGE[5] <= Image2_reg[6];
					PICK_IMAGE[6] <= Image2_reg[8];
					PICK_IMAGE[7] <= Image2_reg[9];
					PICK_IMAGE[8] <= Image2_reg[10];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[0];
					PICK_IMAGE[1] <= Image3_reg[1];
					PICK_IMAGE[2] <= Image3_reg[2];
					PICK_IMAGE[3] <= Image3_reg[4];
					PICK_IMAGE[4] <= Image3_reg[5];
					PICK_IMAGE[5] <= Image3_reg[6];
					PICK_IMAGE[6] <= Image3_reg[8];
					PICK_IMAGE[7] <= Image3_reg[9];
					PICK_IMAGE[8] <= Image3_reg[10];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			6:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[1];
					PICK_IMAGE[1] <= Image1_reg[2];
					PICK_IMAGE[2] <= Image1_reg[3];
					PICK_IMAGE[3] <= Image1_reg[5];
					PICK_IMAGE[4] <= Image1_reg[6];
					PICK_IMAGE[5] <= Image1_reg[7];
					PICK_IMAGE[6] <= Image1_reg[9];
					PICK_IMAGE[7] <= Image1_reg[10];
					PICK_IMAGE[8] <= Image1_reg[11];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[1];
					PICK_IMAGE[1] <= Image2_reg[2];
					PICK_IMAGE[2] <= Image2_reg[3];
					PICK_IMAGE[3] <= Image2_reg[5];
					PICK_IMAGE[4] <= Image2_reg[6];
					PICK_IMAGE[5] <= Image2_reg[7];
					PICK_IMAGE[6] <= Image2_reg[9];
					PICK_IMAGE[7] <= Image2_reg[10];
					PICK_IMAGE[8] <= Image2_reg[11];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[1];
					PICK_IMAGE[1] <= Image3_reg[2];
					PICK_IMAGE[2] <= Image3_reg[3];
					PICK_IMAGE[3] <= Image3_reg[5];
					PICK_IMAGE[4] <= Image3_reg[6];
					PICK_IMAGE[5] <= Image3_reg[7];
					PICK_IMAGE[6] <= Image3_reg[9];
					PICK_IMAGE[7] <= Image3_reg[10];
					PICK_IMAGE[8] <= Image3_reg[11];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			7:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[2];
					PICK_IMAGE[1] <= Image1_reg[3];
					PICK_IMAGE[2] <= Image1_reg[3];
					PICK_IMAGE[3] <= Image1_reg[6];
					PICK_IMAGE[4] <= Image1_reg[7];
					PICK_IMAGE[5] <= Image1_reg[7];
					PICK_IMAGE[6] <= Image1_reg[10];
					PICK_IMAGE[7] <= Image1_reg[11];
					PICK_IMAGE[8] <= Image1_reg[11];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[2];
					PICK_IMAGE[1] <= Image2_reg[3];
					PICK_IMAGE[2] <= Image2_reg[3];
					PICK_IMAGE[3] <= Image2_reg[6];
					PICK_IMAGE[4] <= Image2_reg[7];
					PICK_IMAGE[5] <= Image2_reg[7];
					PICK_IMAGE[6] <= Image2_reg[10];
					PICK_IMAGE[7] <= Image2_reg[11];
					PICK_IMAGE[8] <= Image2_reg[11];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[2];
					PICK_IMAGE[1] <= Image3_reg[3];
					PICK_IMAGE[2] <= Image3_reg[3];
					PICK_IMAGE[3] <= Image3_reg[6];
					PICK_IMAGE[4] <= Image3_reg[7];
					PICK_IMAGE[5] <= Image3_reg[7];
					PICK_IMAGE[6] <= Image3_reg[10];
					PICK_IMAGE[7] <= Image3_reg[11];
					PICK_IMAGE[8] <= Image3_reg[11];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			8:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[4];
					PICK_IMAGE[1] <= Image1_reg[4];
					PICK_IMAGE[2] <= Image1_reg[5];
					PICK_IMAGE[3] <= Image1_reg[8];
					PICK_IMAGE[4] <= Image1_reg[8];
					PICK_IMAGE[5] <= Image1_reg[9];
					PICK_IMAGE[6] <= Image1_reg[12];
					PICK_IMAGE[7] <= Image1_reg[12];
					PICK_IMAGE[8] <= Image1_reg[13];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[4];
					PICK_IMAGE[1] <= Image2_reg[4];
					PICK_IMAGE[2] <= Image2_reg[5];
					PICK_IMAGE[3] <= Image2_reg[8];
					PICK_IMAGE[4] <= Image2_reg[8];
					PICK_IMAGE[5] <= Image2_reg[9];
					PICK_IMAGE[6] <= Image2_reg[12];
					PICK_IMAGE[7] <= Image2_reg[12];
					PICK_IMAGE[8] <= Image2_reg[13];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[4];
					PICK_IMAGE[1] <= Image3_reg[4];
					PICK_IMAGE[2] <= Image3_reg[5];
					PICK_IMAGE[3] <= Image3_reg[8];
					PICK_IMAGE[4] <= Image3_reg[8];
					PICK_IMAGE[5] <= Image3_reg[9];
					PICK_IMAGE[6] <= Image3_reg[12];
					PICK_IMAGE[7] <= Image3_reg[12];
					PICK_IMAGE[8] <= Image3_reg[13];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			9:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[4];
					PICK_IMAGE[1] <= Image1_reg[5];
					PICK_IMAGE[2] <= Image1_reg[6];
					PICK_IMAGE[3] <= Image1_reg[8];
					PICK_IMAGE[4] <= Image1_reg[9];
					PICK_IMAGE[5] <= Image1_reg[10];
					PICK_IMAGE[6] <= Image1_reg[12];
					PICK_IMAGE[7] <= Image1_reg[13];
					PICK_IMAGE[8] <= Image1_reg[14];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[4];
					PICK_IMAGE[1] <= Image2_reg[5];
					PICK_IMAGE[2] <= Image2_reg[6];
					PICK_IMAGE[3] <= Image2_reg[8];
					PICK_IMAGE[4] <= Image2_reg[9];
					PICK_IMAGE[5] <= Image2_reg[10];
					PICK_IMAGE[6] <= Image2_reg[12];
					PICK_IMAGE[7] <= Image2_reg[13];
					PICK_IMAGE[8] <= Image2_reg[14];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[4];
					PICK_IMAGE[1] <= Image3_reg[5];
					PICK_IMAGE[2] <= Image3_reg[6];
					PICK_IMAGE[3] <= Image3_reg[8];
					PICK_IMAGE[4] <= Image3_reg[9];
					PICK_IMAGE[5] <= Image3_reg[10];
					PICK_IMAGE[6] <= Image3_reg[12];
					PICK_IMAGE[7] <= Image3_reg[13];
					PICK_IMAGE[8] <= Image3_reg[14];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			10:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[5];
					PICK_IMAGE[1] <= Image1_reg[6];
					PICK_IMAGE[2] <= Image1_reg[7];
					PICK_IMAGE[3] <= Image1_reg[9];
					PICK_IMAGE[4] <= Image1_reg[10];
					PICK_IMAGE[5] <= Image1_reg[11];
					PICK_IMAGE[6] <= Image1_reg[13];
					PICK_IMAGE[7] <= Image1_reg[14];
					PICK_IMAGE[8] <= Image1_reg[15];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[5];
					PICK_IMAGE[1] <= Image2_reg[6];
					PICK_IMAGE[2] <= Image2_reg[7];
					PICK_IMAGE[3] <= Image2_reg[9];
					PICK_IMAGE[4] <= Image2_reg[10];
					PICK_IMAGE[5] <= Image2_reg[11];
					PICK_IMAGE[6] <= Image2_reg[13];
					PICK_IMAGE[7] <= Image2_reg[14];
					PICK_IMAGE[8] <= Image2_reg[15];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[5];
					PICK_IMAGE[1] <= Image3_reg[6];
					PICK_IMAGE[2] <= Image3_reg[7];
					PICK_IMAGE[3] <= Image3_reg[9];
					PICK_IMAGE[4] <= Image3_reg[10];
					PICK_IMAGE[5] <= Image3_reg[11];
					PICK_IMAGE[6] <= Image3_reg[13];
					PICK_IMAGE[7] <= Image3_reg[14];
					PICK_IMAGE[8] <= Image3_reg[15];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			11:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[6];
					PICK_IMAGE[1] <= Image1_reg[7];
					PICK_IMAGE[2] <= Image1_reg[7];
					PICK_IMAGE[3] <= Image1_reg[10];
					PICK_IMAGE[4] <= Image1_reg[11];
					PICK_IMAGE[5] <= Image1_reg[11];
					PICK_IMAGE[6] <= Image1_reg[14];
					PICK_IMAGE[7] <= Image1_reg[15];
					PICK_IMAGE[8] <= Image1_reg[15];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[6];
					PICK_IMAGE[1] <= Image2_reg[7];
					PICK_IMAGE[2] <= Image2_reg[7];
					PICK_IMAGE[3] <= Image2_reg[10];
					PICK_IMAGE[4] <= Image2_reg[11];
					PICK_IMAGE[5] <= Image2_reg[11];
					PICK_IMAGE[6] <= Image2_reg[14];
					PICK_IMAGE[7] <= Image2_reg[15];
					PICK_IMAGE[8] <= Image2_reg[15];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[6];
					PICK_IMAGE[1] <= Image3_reg[7];
					PICK_IMAGE[2] <= Image3_reg[7];
					PICK_IMAGE[3] <= Image3_reg[10];
					PICK_IMAGE[4] <= Image3_reg[11];
					PICK_IMAGE[5] <= Image3_reg[11];
					PICK_IMAGE[6] <= Image3_reg[14];
					PICK_IMAGE[7] <= Image3_reg[15];
					PICK_IMAGE[8] <= Image3_reg[15];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			12:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[8];
					PICK_IMAGE[1] <= Image1_reg[8];
					PICK_IMAGE[2] <= Image1_reg[9];
					PICK_IMAGE[3] <= Image1_reg[12];
					PICK_IMAGE[4] <= Image1_reg[12];
					PICK_IMAGE[5] <= Image1_reg[13];
					PICK_IMAGE[6] <= Image1_reg[12];
					PICK_IMAGE[7] <= Image1_reg[12];
					PICK_IMAGE[8] <= Image1_reg[13];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[8];
					PICK_IMAGE[1] <= Image2_reg[8];
					PICK_IMAGE[2] <= Image2_reg[9];
					PICK_IMAGE[3] <= Image2_reg[12];
					PICK_IMAGE[4] <= Image2_reg[12];
					PICK_IMAGE[5] <= Image2_reg[13];
					PICK_IMAGE[6] <= Image2_reg[12];
					PICK_IMAGE[7] <= Image2_reg[12];
					PICK_IMAGE[8] <= Image2_reg[13];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[8];
					PICK_IMAGE[1] <= Image3_reg[8];
					PICK_IMAGE[2] <= Image3_reg[9];
					PICK_IMAGE[3] <= Image3_reg[12];
					PICK_IMAGE[4] <= Image3_reg[12];
					PICK_IMAGE[5] <= Image3_reg[13];
					PICK_IMAGE[6] <= Image3_reg[12];
					PICK_IMAGE[7] <= Image3_reg[12];
					PICK_IMAGE[8] <= Image3_reg[13];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			13:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[8];
					PICK_IMAGE[1] <= Image1_reg[9];
					PICK_IMAGE[2] <= Image1_reg[10];
					PICK_IMAGE[3] <= Image1_reg[12];
					PICK_IMAGE[4] <= Image1_reg[13];
					PICK_IMAGE[5] <= Image1_reg[14];
					PICK_IMAGE[6] <= Image1_reg[12];
					PICK_IMAGE[7] <= Image1_reg[13];
					PICK_IMAGE[8] <= Image1_reg[14];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[8];
					PICK_IMAGE[1] <= Image2_reg[9];
					PICK_IMAGE[2] <= Image2_reg[10];
					PICK_IMAGE[3] <= Image2_reg[12];
					PICK_IMAGE[4] <= Image2_reg[13];
					PICK_IMAGE[5] <= Image2_reg[14];
					PICK_IMAGE[6] <= Image2_reg[12];
					PICK_IMAGE[7] <= Image2_reg[13];
					PICK_IMAGE[8] <= Image2_reg[14];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[8];
					PICK_IMAGE[1] <= Image3_reg[9];
					PICK_IMAGE[2] <= Image3_reg[10];
					PICK_IMAGE[3] <= Image3_reg[12];
					PICK_IMAGE[4] <= Image3_reg[13];
					PICK_IMAGE[5] <= Image3_reg[14];
					PICK_IMAGE[6] <= Image3_reg[12];
					PICK_IMAGE[7] <= Image3_reg[13];
					PICK_IMAGE[8] <= Image3_reg[14];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			14:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[9];
					PICK_IMAGE[1] <= Image1_reg[10];
					PICK_IMAGE[2] <= Image1_reg[11];
					PICK_IMAGE[3] <= Image1_reg[13];
					PICK_IMAGE[4] <= Image1_reg[14];
					PICK_IMAGE[5] <= Image1_reg[15];
					PICK_IMAGE[6] <= Image1_reg[13];
					PICK_IMAGE[7] <= Image1_reg[14];
					PICK_IMAGE[8] <= Image1_reg[15];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[9];
					PICK_IMAGE[1] <= Image2_reg[10];
					PICK_IMAGE[2] <= Image2_reg[11];
					PICK_IMAGE[3] <= Image2_reg[13];
					PICK_IMAGE[4] <= Image2_reg[14];
					PICK_IMAGE[5] <= Image2_reg[15];
					PICK_IMAGE[6] <= Image2_reg[13];
					PICK_IMAGE[7] <= Image2_reg[14];
					PICK_IMAGE[8] <= Image2_reg[15];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[9];
					PICK_IMAGE[1] <= Image3_reg[10];
					PICK_IMAGE[2] <= Image3_reg[11];
					PICK_IMAGE[3] <= Image3_reg[13];
					PICK_IMAGE[4] <= Image3_reg[14];
					PICK_IMAGE[5] <= Image3_reg[15];
					PICK_IMAGE[6] <= Image3_reg[13];
					PICK_IMAGE[7] <= Image3_reg[14];
					PICK_IMAGE[8] <= Image3_reg[15];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			15:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[10];
					PICK_IMAGE[1] <= Image1_reg[11];
					PICK_IMAGE[2] <= Image1_reg[11];
					PICK_IMAGE[3] <= Image1_reg[14];
					PICK_IMAGE[4] <= Image1_reg[15];
					PICK_IMAGE[5] <= Image1_reg[15];
					PICK_IMAGE[6] <= Image1_reg[14];
					PICK_IMAGE[7] <= Image1_reg[15];
					PICK_IMAGE[8] <= Image1_reg[15];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[10];
					PICK_IMAGE[1] <= Image2_reg[11];
					PICK_IMAGE[2] <= Image2_reg[11];
					PICK_IMAGE[3] <= Image2_reg[14];
					PICK_IMAGE[4] <= Image2_reg[15];
					PICK_IMAGE[5] <= Image2_reg[15];
					PICK_IMAGE[6] <= Image2_reg[14];
					PICK_IMAGE[7] <= Image2_reg[15];
					PICK_IMAGE[8] <= Image2_reg[15];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[10];
					PICK_IMAGE[1] <= Image3_reg[11];
					PICK_IMAGE[2] <= Image3_reg[11];
					PICK_IMAGE[3] <= Image3_reg[14];
					PICK_IMAGE[4] <= Image3_reg[15];
					PICK_IMAGE[5] <= Image3_reg[15];
					PICK_IMAGE[6] <= Image3_reg[14];
					PICK_IMAGE[7] <= Image3_reg[15];
					PICK_IMAGE[8] <= Image3_reg[15];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			default: begin
				PICK_IMAGE[0] <= 0;
				PICK_IMAGE[1] <= 0;
				PICK_IMAGE[2] <= 0;
				PICK_IMAGE[3] <= 0;
				PICK_IMAGE[4] <= 0;
				PICK_IMAGE[5] <= 0;
				PICK_IMAGE[6] <= 0;
				PICK_IMAGE[7] <= 0;
				PICK_IMAGE[8] <= 0;
			end
		endcase
	end
	else begin
		case(counter_img)
			0:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image1_reg[0];
					PICK_IMAGE[5] <= Image1_reg[1];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image1_reg[4];
					PICK_IMAGE[8] <= Image1_reg[5];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image2_reg[0];
					PICK_IMAGE[5] <= Image2_reg[1];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image2_reg[4];
					PICK_IMAGE[8] <= Image2_reg[5];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image3_reg[0];
					PICK_IMAGE[5] <= Image3_reg[1];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image3_reg[4];
					PICK_IMAGE[8] <= Image3_reg[5];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			1:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image1_reg[0];
					PICK_IMAGE[4] <= Image1_reg[1];
					PICK_IMAGE[5] <= Image1_reg[2];
					PICK_IMAGE[6] <= Image1_reg[4];
					PICK_IMAGE[7] <= Image1_reg[5];
					PICK_IMAGE[8] <= Image1_reg[6];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image2_reg[0];
					PICK_IMAGE[4] <= Image2_reg[1];
					PICK_IMAGE[5] <= Image2_reg[2];
					PICK_IMAGE[6] <= Image2_reg[4];
					PICK_IMAGE[7] <= Image2_reg[5];
					PICK_IMAGE[8] <= Image2_reg[6];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image3_reg[0];
					PICK_IMAGE[4] <= Image3_reg[1];
					PICK_IMAGE[5] <= Image3_reg[2];
					PICK_IMAGE[6] <= Image3_reg[4];
					PICK_IMAGE[7] <= Image3_reg[5];
					PICK_IMAGE[8] <= Image3_reg[6];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			2:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image1_reg[1];
					PICK_IMAGE[4] <= Image1_reg[2];
					PICK_IMAGE[5] <= Image1_reg[3];
					PICK_IMAGE[6] <= Image1_reg[5];
					PICK_IMAGE[7] <= Image1_reg[6];
					PICK_IMAGE[8] <= Image1_reg[7];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image2_reg[1];
					PICK_IMAGE[4] <= Image2_reg[2];
					PICK_IMAGE[5] <= Image2_reg[3];
					PICK_IMAGE[6] <= Image2_reg[5];
					PICK_IMAGE[7] <= Image2_reg[6];
					PICK_IMAGE[8] <= Image2_reg[7];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image3_reg[1];
					PICK_IMAGE[4] <= Image3_reg[2];
					PICK_IMAGE[5] <= Image3_reg[3];
					PICK_IMAGE[6] <= Image3_reg[5];
					PICK_IMAGE[7] <= Image3_reg[6];
					PICK_IMAGE[8] <= Image3_reg[7];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			3:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image1_reg[2];
					PICK_IMAGE[4] <= Image1_reg[3];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image1_reg[6];
					PICK_IMAGE[7] <= Image1_reg[7];
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image2_reg[2];
					PICK_IMAGE[4] <= Image2_reg[3];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image2_reg[6];
					PICK_IMAGE[7] <= Image2_reg[7];
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image3_reg[2];
					PICK_IMAGE[4] <= Image3_reg[3];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image3_reg[6];
					PICK_IMAGE[7] <= Image3_reg[7];
					PICK_IMAGE[8] <= 0;
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			4:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image1_reg[0];
					PICK_IMAGE[2] <= Image1_reg[1];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image1_reg[4];
					PICK_IMAGE[5] <= Image1_reg[5];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image1_reg[8];
					PICK_IMAGE[8] <= Image1_reg[9];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image2_reg[0];
					PICK_IMAGE[2] <= Image2_reg[1];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image2_reg[4];
					PICK_IMAGE[5] <= Image2_reg[5];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image2_reg[8];
					PICK_IMAGE[8] <= Image2_reg[9];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image3_reg[0];
					PICK_IMAGE[2] <= Image3_reg[1];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image3_reg[4];
					PICK_IMAGE[5] <= Image3_reg[5];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image3_reg[8];
					PICK_IMAGE[8] <= Image3_reg[9];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			5:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[0];
					PICK_IMAGE[1] <= Image1_reg[1];
					PICK_IMAGE[2] <= Image1_reg[2];
					PICK_IMAGE[3] <= Image1_reg[4];
					PICK_IMAGE[4] <= Image1_reg[5];
					PICK_IMAGE[5] <= Image1_reg[6];
					PICK_IMAGE[6] <= Image1_reg[8];
					PICK_IMAGE[7] <= Image1_reg[9];
					PICK_IMAGE[8] <= Image1_reg[10];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[0];
					PICK_IMAGE[1] <= Image2_reg[1];
					PICK_IMAGE[2] <= Image2_reg[2];
					PICK_IMAGE[3] <= Image2_reg[4];
					PICK_IMAGE[4] <= Image2_reg[5];
					PICK_IMAGE[5] <= Image2_reg[6];
					PICK_IMAGE[6] <= Image2_reg[8];
					PICK_IMAGE[7] <= Image2_reg[9];
					PICK_IMAGE[8] <= Image2_reg[10];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[0];
					PICK_IMAGE[1] <= Image3_reg[1];
					PICK_IMAGE[2] <= Image3_reg[2];
					PICK_IMAGE[3] <= Image3_reg[4];
					PICK_IMAGE[4] <= Image3_reg[5];
					PICK_IMAGE[5] <= Image3_reg[6];
					PICK_IMAGE[6] <= Image3_reg[8];
					PICK_IMAGE[7] <= Image3_reg[9];
					PICK_IMAGE[8] <= Image3_reg[10];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			6:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[1];
					PICK_IMAGE[1] <= Image1_reg[2];
					PICK_IMAGE[2] <= Image1_reg[3];
					PICK_IMAGE[3] <= Image1_reg[5];
					PICK_IMAGE[4] <= Image1_reg[6];
					PICK_IMAGE[5] <= Image1_reg[7];
					PICK_IMAGE[6] <= Image1_reg[9];
					PICK_IMAGE[7] <= Image1_reg[10];
					PICK_IMAGE[8] <= Image1_reg[11];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[1];
					PICK_IMAGE[1] <= Image2_reg[2];
					PICK_IMAGE[2] <= Image2_reg[3];
					PICK_IMAGE[3] <= Image2_reg[5];
					PICK_IMAGE[4] <= Image2_reg[6];
					PICK_IMAGE[5] <= Image2_reg[7];
					PICK_IMAGE[6] <= Image2_reg[9];
					PICK_IMAGE[7] <= Image2_reg[10];
					PICK_IMAGE[8] <= Image2_reg[11];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[1];
					PICK_IMAGE[1] <= Image3_reg[2];
					PICK_IMAGE[2] <= Image3_reg[3];
					PICK_IMAGE[3] <= Image3_reg[5];
					PICK_IMAGE[4] <= Image3_reg[6];
					PICK_IMAGE[5] <= Image3_reg[7];
					PICK_IMAGE[6] <= Image3_reg[9];
					PICK_IMAGE[7] <= Image3_reg[10];
					PICK_IMAGE[8] <= Image3_reg[11];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			7:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[2];
					PICK_IMAGE[1] <= Image1_reg[3];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image1_reg[6];
					PICK_IMAGE[4] <= Image1_reg[7];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image1_reg[10];
					PICK_IMAGE[7] <= Image1_reg[11];
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[2];
					PICK_IMAGE[1] <= Image2_reg[3];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image2_reg[6];
					PICK_IMAGE[4] <= Image2_reg[7];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image2_reg[10];
					PICK_IMAGE[7] <= Image2_reg[11];
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[2];
					PICK_IMAGE[1] <= Image3_reg[3];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image3_reg[6];
					PICK_IMAGE[4] <= Image3_reg[7];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image3_reg[10];
					PICK_IMAGE[7] <= Image3_reg[11];
					PICK_IMAGE[8] <= 0;
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			8:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image1_reg[4];
					PICK_IMAGE[2] <= Image1_reg[5];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image1_reg[8];
					PICK_IMAGE[5] <= Image1_reg[9];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image1_reg[12];
					PICK_IMAGE[8] <= Image1_reg[13];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image2_reg[4];
					PICK_IMAGE[2] <= Image2_reg[5];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image2_reg[8];
					PICK_IMAGE[5] <= Image2_reg[9];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image2_reg[12];
					PICK_IMAGE[8] <= Image2_reg[13];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image3_reg[4];
					PICK_IMAGE[2] <= Image3_reg[5];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image3_reg[8];
					PICK_IMAGE[5] <= Image3_reg[9];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= Image3_reg[12];
					PICK_IMAGE[8] <= Image3_reg[13];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			9:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[4];
					PICK_IMAGE[1] <= Image1_reg[5];
					PICK_IMAGE[2] <= Image1_reg[6];
					PICK_IMAGE[3] <= Image1_reg[8];
					PICK_IMAGE[4] <= Image1_reg[9];
					PICK_IMAGE[5] <= Image1_reg[10];
					PICK_IMAGE[6] <= Image1_reg[12];
					PICK_IMAGE[7] <= Image1_reg[13];
					PICK_IMAGE[8] <= Image1_reg[14];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[4];
					PICK_IMAGE[1] <= Image2_reg[5];
					PICK_IMAGE[2] <= Image2_reg[6];
					PICK_IMAGE[3] <= Image2_reg[8];
					PICK_IMAGE[4] <= Image2_reg[9];
					PICK_IMAGE[5] <= Image2_reg[10];
					PICK_IMAGE[6] <= Image2_reg[12];
					PICK_IMAGE[7] <= Image2_reg[13];
					PICK_IMAGE[8] <= Image2_reg[14];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[4];
					PICK_IMAGE[1] <= Image3_reg[5];
					PICK_IMAGE[2] <= Image3_reg[6];
					PICK_IMAGE[3] <= Image3_reg[8];
					PICK_IMAGE[4] <= Image3_reg[9];
					PICK_IMAGE[5] <= Image3_reg[10];
					PICK_IMAGE[6] <= Image3_reg[12];
					PICK_IMAGE[7] <= Image3_reg[13];
					PICK_IMAGE[8] <= Image3_reg[14];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			10:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[5];
					PICK_IMAGE[1] <= Image1_reg[6];
					PICK_IMAGE[2] <= Image1_reg[7];
					PICK_IMAGE[3] <= Image1_reg[9];
					PICK_IMAGE[4] <= Image1_reg[10];
					PICK_IMAGE[5] <= Image1_reg[11];
					PICK_IMAGE[6] <= Image1_reg[13];
					PICK_IMAGE[7] <= Image1_reg[14];
					PICK_IMAGE[8] <= Image1_reg[15];
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[5];
					PICK_IMAGE[1] <= Image2_reg[6];
					PICK_IMAGE[2] <= Image2_reg[7];
					PICK_IMAGE[3] <= Image2_reg[9];
					PICK_IMAGE[4] <= Image2_reg[10];
					PICK_IMAGE[5] <= Image2_reg[11];
					PICK_IMAGE[6] <= Image2_reg[13];
					PICK_IMAGE[7] <= Image2_reg[14];
					PICK_IMAGE[8] <= Image2_reg[15];
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[5];
					PICK_IMAGE[1] <= Image3_reg[6];
					PICK_IMAGE[2] <= Image3_reg[7];
					PICK_IMAGE[3] <= Image3_reg[9];
					PICK_IMAGE[4] <= Image3_reg[10];
					PICK_IMAGE[5] <= Image3_reg[11];
					PICK_IMAGE[6] <= Image3_reg[13];
					PICK_IMAGE[7] <= Image3_reg[14];
					PICK_IMAGE[8] <= Image3_reg[15];
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			11:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[6];
					PICK_IMAGE[1] <= Image1_reg[7];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image1_reg[10];
					PICK_IMAGE[4] <= Image1_reg[11];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image1_reg[14];
					PICK_IMAGE[7] <= Image1_reg[15];
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[6];
					PICK_IMAGE[1] <= Image2_reg[7];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image2_reg[10];
					PICK_IMAGE[4] <= Image2_reg[11];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image2_reg[14];
					PICK_IMAGE[7] <= Image2_reg[15];
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[6];
					PICK_IMAGE[1] <= Image3_reg[7];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image3_reg[10];
					PICK_IMAGE[4] <= Image3_reg[11];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= Image3_reg[14];
					PICK_IMAGE[7] <= Image3_reg[15];
					PICK_IMAGE[8] <= 0;
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			12:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image1_reg[8];
					PICK_IMAGE[2] <= Image1_reg[9];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image1_reg[12];
					PICK_IMAGE[5] <= Image1_reg[13];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image2_reg[8];
					PICK_IMAGE[2] <= Image2_reg[9];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image2_reg[12];
					PICK_IMAGE[5] <= Image2_reg[13];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= Image3_reg[8];
					PICK_IMAGE[2] <= Image3_reg[9];
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= Image3_reg[12];
					PICK_IMAGE[5] <= Image3_reg[13];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			13:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[8];
					PICK_IMAGE[1] <= Image1_reg[9];
					PICK_IMAGE[2] <= Image1_reg[10];
					PICK_IMAGE[3] <= Image1_reg[12];
					PICK_IMAGE[4] <= Image1_reg[13];
					PICK_IMAGE[5] <= Image1_reg[14];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[8];
					PICK_IMAGE[1] <= Image2_reg[9];
					PICK_IMAGE[2] <= Image2_reg[10];
					PICK_IMAGE[3] <= Image2_reg[12];
					PICK_IMAGE[4] <= Image2_reg[13];
					PICK_IMAGE[5] <= Image2_reg[14];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[8];
					PICK_IMAGE[1] <= Image3_reg[9];
					PICK_IMAGE[2] <= Image3_reg[10];
					PICK_IMAGE[3] <= Image3_reg[12];
					PICK_IMAGE[4] <= Image3_reg[13];
					PICK_IMAGE[5] <= Image3_reg[14];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			14:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[9];
					PICK_IMAGE[1] <= Image1_reg[10];
					PICK_IMAGE[2] <= Image1_reg[11];
					PICK_IMAGE[3] <= Image1_reg[13];
					PICK_IMAGE[4] <= Image1_reg[14];
					PICK_IMAGE[5] <= Image1_reg[15];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[9];
					PICK_IMAGE[1] <= Image2_reg[10];
					PICK_IMAGE[2] <= Image2_reg[11];
					PICK_IMAGE[3] <= Image2_reg[13];
					PICK_IMAGE[4] <= Image2_reg[14];
					PICK_IMAGE[5] <= Image2_reg[15];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[9];
					PICK_IMAGE[1] <= Image3_reg[10];
					PICK_IMAGE[2] <= Image3_reg[11];
					PICK_IMAGE[3] <= Image3_reg[13];
					PICK_IMAGE[4] <= Image3_reg[14];
					PICK_IMAGE[5] <= Image3_reg[15];
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			15:begin
				if(state_ns==COMP_K1)begin
					PICK_IMAGE[0] <= Image1_reg[10];
					PICK_IMAGE[1] <= Image1_reg[11];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image1_reg[14];
					PICK_IMAGE[4] <= Image1_reg[15];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K2)begin
					PICK_IMAGE[0] <= Image2_reg[10];
					PICK_IMAGE[1] <= Image2_reg[11];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image2_reg[14];
					PICK_IMAGE[4] <= Image2_reg[15];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else if(state_ns==COMP_K3)begin
					PICK_IMAGE[0] <= Image3_reg[10];
					PICK_IMAGE[1] <= Image3_reg[11];
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= Image3_reg[14];
					PICK_IMAGE[4] <= Image3_reg[15];
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
				else begin
					PICK_IMAGE[0] <= 0;
					PICK_IMAGE[1] <= 0;
					PICK_IMAGE[2] <= 0;
					PICK_IMAGE[3] <= 0;
					PICK_IMAGE[4] <= 0;
					PICK_IMAGE[5] <= 0;
					PICK_IMAGE[6] <= 0;
					PICK_IMAGE[7] <= 0;
					PICK_IMAGE[8] <= 0;
				end
			end
			default: begin
				PICK_IMAGE[0] <= 0;
				PICK_IMAGE[1] <= 0;
				PICK_IMAGE[2] <= 0;
				PICK_IMAGE[3] <= 0;
				PICK_IMAGE[4] <= 0;
				PICK_IMAGE[5] <= 0;
				PICK_IMAGE[6] <= 0;
				PICK_IMAGE[7] <= 0;
				PICK_IMAGE[8] <= 0;
			end
		endcase
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<9;i=i+1)begin
			PICK_KERNEL[i]<= 0;
		end
	else if(state_ns==IDLE)
		for(i=0;i<9;i=i+1)begin
			PICK_KERNEL[i]<= 0;
		end
	else begin
		case(counter_ker)
			0:begin
				if(state_ns==COMP_K1)begin
					PICK_KERNEL[0]<= Kernel1_reg[0];
					PICK_KERNEL[1]<= Kernel1_reg[1];
					PICK_KERNEL[2]<= Kernel1_reg[2];
					PICK_KERNEL[3]<= Kernel1_reg[3];
					PICK_KERNEL[4]<= Kernel1_reg[4];
					PICK_KERNEL[5]<= Kernel1_reg[5];
					PICK_KERNEL[6]<= Kernel1_reg[6];
					PICK_KERNEL[7]<= Kernel1_reg[7];
					PICK_KERNEL[8]<= Kernel1_reg[8];
				end
				else if(state_ns==COMP_K2)begin
					PICK_KERNEL[0]<= Kernel2_reg[0];
					PICK_KERNEL[1]<= Kernel2_reg[1];
					PICK_KERNEL[2]<= Kernel2_reg[2];
					PICK_KERNEL[3]<= Kernel2_reg[3];
					PICK_KERNEL[4]<= Kernel2_reg[4];
					PICK_KERNEL[5]<= Kernel2_reg[5];
					PICK_KERNEL[6]<= Kernel2_reg[6];
					PICK_KERNEL[7]<= Kernel2_reg[7];
					PICK_KERNEL[8]<= Kernel2_reg[8];
				end	
				else if(state_ns==COMP_K3)begin
					PICK_KERNEL[0]<= Kernel3_reg[0];
					PICK_KERNEL[1]<= Kernel3_reg[1];
					PICK_KERNEL[2]<= Kernel3_reg[2];
					PICK_KERNEL[3]<= Kernel3_reg[3];
					PICK_KERNEL[4]<= Kernel3_reg[4];
					PICK_KERNEL[5]<= Kernel3_reg[5];
					PICK_KERNEL[6]<= Kernel3_reg[6];
					PICK_KERNEL[7]<= Kernel3_reg[7];
					PICK_KERNEL[8]<= Kernel3_reg[8];
				end
				else begin
					PICK_KERNEL[0]<= 0;
					PICK_KERNEL[1]<= 0;
					PICK_KERNEL[2]<= 0;
					PICK_KERNEL[3]<= 0;
					PICK_KERNEL[4]<= 0;
					PICK_KERNEL[5]<= 0;
					PICK_KERNEL[6]<= 0;
					PICK_KERNEL[7]<= 0;
					PICK_KERNEL[8]<= 0;
				end
			end
			1:begin
				if(state_ns==COMP_K1)begin
					PICK_KERNEL[0]<= Kernel1_reg[9];
					PICK_KERNEL[1]<= Kernel1_reg[10];
					PICK_KERNEL[2]<= Kernel1_reg[11];
					PICK_KERNEL[3]<= Kernel1_reg[12];
					PICK_KERNEL[4]<= Kernel1_reg[13];
					PICK_KERNEL[5]<= Kernel1_reg[14];
					PICK_KERNEL[6]<= Kernel1_reg[15];
					PICK_KERNEL[7]<= Kernel1_reg[16];
					PICK_KERNEL[8]<= Kernel1_reg[17];
				end
				else if(state_ns==COMP_K2)begin
					PICK_KERNEL[0]<= Kernel2_reg[9];
					PICK_KERNEL[1]<= Kernel2_reg[10];
					PICK_KERNEL[2]<= Kernel2_reg[11];
					PICK_KERNEL[3]<= Kernel2_reg[12];
					PICK_KERNEL[4]<= Kernel2_reg[13];
					PICK_KERNEL[5]<= Kernel2_reg[14];
					PICK_KERNEL[6]<= Kernel2_reg[15];
					PICK_KERNEL[7]<= Kernel2_reg[16];
					PICK_KERNEL[8]<= Kernel2_reg[17];
				end	
				else if(state_ns==COMP_K3)begin
					PICK_KERNEL[0]<= Kernel3_reg[9];
					PICK_KERNEL[1]<= Kernel3_reg[10];
					PICK_KERNEL[2]<= Kernel3_reg[11];
					PICK_KERNEL[3]<= Kernel3_reg[12];
					PICK_KERNEL[4]<= Kernel3_reg[13];
					PICK_KERNEL[5]<= Kernel3_reg[14];
					PICK_KERNEL[6]<= Kernel3_reg[15];
					PICK_KERNEL[7]<= Kernel3_reg[16];
					PICK_KERNEL[8]<= Kernel3_reg[17];
				end
				else begin
					PICK_KERNEL[0]<= 0;
					PICK_KERNEL[1]<= 0;
					PICK_KERNEL[2]<= 0;
					PICK_KERNEL[3]<= 0;
					PICK_KERNEL[4]<= 0;
					PICK_KERNEL[5]<= 0;
					PICK_KERNEL[6]<= 0;
					PICK_KERNEL[7]<= 0;
					PICK_KERNEL[8]<= 0;
				end
			end
			2:begin
				if(state_ns==COMP_K1)begin
					PICK_KERNEL[0]<= Kernel1_reg[18];
					PICK_KERNEL[1]<= Kernel1_reg[19];
					PICK_KERNEL[2]<= Kernel1_reg[20];
					PICK_KERNEL[3]<= Kernel1_reg[21];
					PICK_KERNEL[4]<= Kernel1_reg[22];
					PICK_KERNEL[5]<= Kernel1_reg[23];
					PICK_KERNEL[6]<= Kernel1_reg[24];
					PICK_KERNEL[7]<= Kernel1_reg[25];
					PICK_KERNEL[8]<= Kernel1_reg[26];
				end
				else if(state_ns==COMP_K2)begin
					PICK_KERNEL[0]<= Kernel2_reg[18];
					PICK_KERNEL[1]<= Kernel2_reg[19];
					PICK_KERNEL[2]<= Kernel2_reg[20];
					PICK_KERNEL[3]<= Kernel2_reg[21];
					PICK_KERNEL[4]<= Kernel2_reg[22];
					PICK_KERNEL[5]<= Kernel2_reg[23];
					PICK_KERNEL[6]<= Kernel2_reg[24];
					PICK_KERNEL[7]<= Kernel2_reg[25];
					PICK_KERNEL[8]<= Kernel2_reg[26];
				end	
				else if(state_ns==COMP_K3)begin
					PICK_KERNEL[0]<= Kernel3_reg[18];
					PICK_KERNEL[1]<= Kernel3_reg[19];
					PICK_KERNEL[2]<= Kernel3_reg[20];
					PICK_KERNEL[3]<= Kernel3_reg[21];
					PICK_KERNEL[4]<= Kernel3_reg[22];
					PICK_KERNEL[5]<= Kernel3_reg[23];
					PICK_KERNEL[6]<= Kernel3_reg[24];
					PICK_KERNEL[7]<= Kernel3_reg[25];
					PICK_KERNEL[8]<= Kernel3_reg[26];
				end
				else begin
					PICK_KERNEL[0]<= 0;
					PICK_KERNEL[1]<= 0;
					PICK_KERNEL[2]<= 0;
					PICK_KERNEL[3]<= 0;
					PICK_KERNEL[4]<= 0;
					PICK_KERNEL[5]<= 0;
					PICK_KERNEL[6]<= 0;
					PICK_KERNEL[7]<= 0;
					PICK_KERNEL[8]<= 0;
				end
			end
			3:begin
				if(state_ns==COMP_K1)begin
					PICK_KERNEL[0]<= Kernel1_reg[27];
					PICK_KERNEL[1]<= Kernel1_reg[28];
					PICK_KERNEL[2]<= Kernel1_reg[29];
					PICK_KERNEL[3]<= Kernel1_reg[30];
					PICK_KERNEL[4]<= Kernel1_reg[31];
					PICK_KERNEL[5]<= Kernel1_reg[32];
					PICK_KERNEL[6]<= Kernel1_reg[33];
					PICK_KERNEL[7]<= Kernel1_reg[34];
					PICK_KERNEL[8]<= Kernel1_reg[35];
				end
				else if(state_ns==COMP_K2)begin
					PICK_KERNEL[0]<= Kernel2_reg[27];
					PICK_KERNEL[1]<= Kernel2_reg[28];
					PICK_KERNEL[2]<= Kernel2_reg[29];
					PICK_KERNEL[3]<= Kernel2_reg[30];
					PICK_KERNEL[4]<= Kernel2_reg[31];
					PICK_KERNEL[5]<= Kernel2_reg[32];
					PICK_KERNEL[6]<= Kernel2_reg[33];
					PICK_KERNEL[7]<= Kernel2_reg[34];
					PICK_KERNEL[8]<= Kernel2_reg[35];
				end	
				else if(state_ns==COMP_K3)begin
					PICK_KERNEL[0]<= Kernel3_reg[27];
					PICK_KERNEL[1]<= Kernel3_reg[28];
					PICK_KERNEL[2]<= Kernel3_reg[29];
					PICK_KERNEL[3]<= Kernel3_reg[30];
					PICK_KERNEL[4]<= Kernel3_reg[31];
					PICK_KERNEL[5]<= Kernel3_reg[32];
					PICK_KERNEL[6]<= Kernel3_reg[33];
					PICK_KERNEL[7]<= Kernel3_reg[34];
					PICK_KERNEL[8]<= Kernel3_reg[35];
				end
				else begin
					PICK_KERNEL[0]<= 0;
					PICK_KERNEL[1]<= 0;
					PICK_KERNEL[2]<= 0;
					PICK_KERNEL[3]<= 0;
					PICK_KERNEL[4]<= 0;
					PICK_KERNEL[5]<= 0;
					PICK_KERNEL[6]<= 0;
					PICK_KERNEL[7]<= 0;
					PICK_KERNEL[8]<= 0;
				end
			end
			default:begin
				PICK_KERNEL[0]<= 0;
				PICK_KERNEL[1]<= 0;
				PICK_KERNEL[2]<= 0;
				PICK_KERNEL[3]<= 0;
				PICK_KERNEL[4]<= 0;
				PICK_KERNEL[5]<= 0;
				PICK_KERNEL[6]<= 0;
				PICK_KERNEL[7]<= 0;
				PICK_KERNEL[8]<= 0;
			end
		endcase
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<64;i=i+1)
			output_reg[i]<=0;
	else if(state_cs==IDLE)
		for(i=0;i<64;i=i+1)
			output_reg[i]<=0;
			/*
	else if(state_cs==IDLE6)
		case(Opt_reg)
			0:output_reg[past_counter2idx]<= (output_reg[past_counter2idx][31])?0:output_reg[past_counter2idx];
			1:output_reg[past_counter2idx]<= (output_reg[past_counter2idx][31])?Leaky_Relu_Sum:output_reg[past_counter2idx];
			2:output_reg[past_counter2idx]<= div_done_sum;
			3:output_reg[past_counter2idx]<= div_done_sum;
		endcase
		*/
	else if(state_cs==HOLD2)begin
		case(Opt_reg)
			0:output_reg[counter2idx]<= (round_add[31])?0:round_add;
			1:output_reg[counter2idx]<= (round_add[31])?Leaky_Relu_Sum:round_add;
			2:output_reg[counter2idx]<= div_done_sum;
			3:output_reg[counter2idx]<= div_done_sum;
		endcase
		//output_reg[counter2idx]<=tmp2_add[8];
	end
	else if(state_cs==COMP_K2 || state_cs==COMP_K3)begin
		//output_reg[counter2idx]<=tmp2_add[8];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		past_counter2idx<=63;
	else if(state_cs==IDLE)
		past_counter2idx<=63;
	else if(state_cs==COMP_K3)
		past_counter2idx<=counter2idx;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_add<=0;
	else if(state_cs==HOLD2)
		round_add<=0;
	else if(state_cs==COMP_K1 || state_cs==COMP_K2 || state_cs==COMP_K3)
		round_add<=tmp2_add[8];
end

//---------------------------------------------------------------------
//   Out Siganl
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out<=0;
	else if(state_ns==IDLE)
		out<=0;
	else if(state_ns==DONE)
		out<=output_reg[counter];
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