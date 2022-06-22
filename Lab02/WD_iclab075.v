//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : WD.v
//   Module Name : WD
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module WD(
    // Input signals
    clk,
    rst_n,
    in_valid,
    keyboard,
    answer,
    weight,
    match_target,
    // Output signals
    out_valid,
    result,
    out_value
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [4:0] keyboard, answer;
input [3:0] weight;
input [2:0] match_target;
output reg out_valid;
output reg [4:0]  result;
output reg [10:0] out_value;

// ===============================================================
// Parameters & Integer Declaration
// ===============================================================
parameter IDLE = 4'd0;
parameter RD = 4'd1;
parameter IDLE2 = 4'd2;
parameter SP_AC = 4'd3;
parameter IDLE3 = 4'd4;
parameter PICK = 4'd5;
parameter SORT = 4'd6;
parameter IDLE4 = 4'd7;
parameter WR = 4'd8;

integer i;
// ===============================================================
// Wire & Reg Declaration
// ===============================================================
reg [3:0]state_cs,state_ns;
reg [3:0] counter;
reg [2:0] counterAB;
reg [1:0] counterC;


reg [4:0] keyboard_reg [0:7]; //cant reuse
reg [4:0] answer_reg [0:7]; // cant reuse
reg [4:0] weight_reg [0:7]; // cant reuse
reg [4:0] sort_keyboard [0:7];


reg [4:0] curr_answer	[0:4];
reg [4:0] output_answer [0:4];

reg [2:0] matchA,matchB;
wire [1:0] matchC;

wire isAB;

reg [3:0] pick_num,pick_count;
reg [6:0] sort_num,sort_count;

reg [14:0] pick_idx;
wire[4:0] pick_arr[0:4];

reg [14:0] sort_idx;
wire[4:0] sort_arr [0:4];

wire [2:0] C0,C1,C2;
wire [2:0] order_C0,order_C1,order_C2;

reg [10:0] curr_value;
wire findBigger;
wire findEqual;
wire check_valid;

// ===============================================================
// Finite State Machine
// ===============================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE:	state_ns = (in_valid)?RD:IDLE; //0
		RD	:	state_ns = (counter==7)?IDLE2:RD;//1
		IDLE2:	state_ns = SP_AC;//2
		SP_AC: 	state_ns = (counter==7)?IDLE3:SP_AC;//3
		IDLE3: 	state_ns = PICK;//4
		PICK:	state_ns = (pick_count == pick_num)?IDLE4:SORT;
		SORT:	state_ns = (sort_count == sort_num)?PICK:SORT;//5
		IDLE4: 	state_ns = WR;//6
		WR : 	state_ns = (counter==5)?IDLE:WR;//7
		default:state_ns = state_cs;
	endcase
end

// ===============================================================
// DESIGN
// ===============================================================

assign isAB = Check_isAB(answer_reg[0],answer_reg[1],answer_reg[2],answer_reg[3],answer_reg[4],keyboard_reg[counter]);
assign matchC = 5-(matchA+matchB);
assign pick_arr[0] = sort_keyboard[pick_idx[2:0]];
assign pick_arr[1] = sort_keyboard[pick_idx[5:3]];
assign pick_arr[2] = sort_keyboard[pick_idx[8:6]];
assign pick_arr[3]= sort_keyboard[pick_idx[11:9]];
assign pick_arr[4] = sort_keyboard[pick_idx[14:12]];
assign sort_arr[4] = sort_idx[2:0];
assign sort_arr[3] = sort_idx[5:3];
assign sort_arr[2] = sort_idx[8:6];
assign sort_arr[1] = sort_idx[11:9];
assign sort_arr[0] = sort_idx[14:12];
assign {C0,C1,C2} = remainC(sort_arr[0],sort_arr[1],sort_arr[2],sort_arr[3],sort_arr[4]);
assign {order_C0,order_C1,order_C2} = sortC(weight_reg[C0],weight_reg[C1],weight_reg[C2],C0,C1,C2);
assign findBigger = (curr_value>out_value);
assign check_valid = validation(answer_reg[0],answer_reg[1],answer_reg[2],answer_reg[3],answer_reg[4],
								curr_answer[0],curr_answer[1],curr_answer[2],curr_answer[3],curr_answer[4],
								matchA);
assign findEqual = (curr_value==out_value);


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_cs==IDLE2 || state_ns==IDLE)
		counter<=0;
	else if(state_cs==SP_AC && state_ns==IDLE3)
		counter<=0;
	else if(state_ns==RD || state_ns==SP_AC || state_ns==WR)
		counter<=counter+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counterAB<=4;
	else if(state_ns==IDLE)
		counterAB<=4;
	else if(state_cs==SP_AC && isAB)
		counterAB<=counterAB-1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counterC<=2;
	else if(state_ns == IDLE)
		counterC<=2;
	else if(state_cs==SP_AC && !isAB)
		counterC<=counterC-1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		pick_count<=0;
	else if(state_cs==IDLE)
		pick_count<=0;
	else if(state_cs == SORT && state_ns==PICK)
		pick_count<=pick_count+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		sort_count<=0;
	else if(state_cs==IDLE || state_ns==PICK)
		sort_count<=0;
	else if(state_ns==SORT)
		sort_count<=sort_count+1;
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<8;i=i+1)
			keyboard_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<8;i=i+1)
			keyboard_reg[i]<=0;
	else if(state_ns==RD || state_cs==RD)
		keyboard_reg[counter] <= keyboard;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<5;i=i+1)
			answer_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<5;i=i+1)
			answer_reg[i]<=0;
	else if(state_ns == RD || state_cs==RD)
		answer_reg[counter] <= answer;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<5;i=i+1)
			weight_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<5;i=i+1)
			weight_reg[i]<=0;
	else if(state_ns == RD || state_cs==RD)
		weight_reg[counter] <= weight;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		matchA<=0;
	else if(state_ns == IDLE)
		matchA<=0;
	else if(state_ns==RD && counter==0)
		matchA<=match_target;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		matchB<=0;
	else if(state_ns == IDLE)
		matchB<=0;
	else if(state_ns==RD && counter==1)
		matchB<=match_target;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_valid<=0;
	else if(state_ns == IDLE)
		out_valid<=0;
	else if(state_ns == WR)
		out_valid<=1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_value<=0;
	else if(state_cs==IDLE)
		out_value<=0;
	else if(findBigger && check_valid)
		out_value<=curr_value;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		result<=0;
	else if(state_ns==IDLE)
		result<=0;
	else if(state_ns==WR)
		result<=output_answer[counter];
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<8;i=i+1)	
			sort_keyboard[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<8;i=i+1)
			sort_keyboard[i]<=0;
	else if(state_cs==SP_AC)begin
		if(isAB)
			sort_keyboard[counterAB]<=keyboard_reg[counter];
		else 
			sort_keyboard[counterC+5]<=keyboard_reg[counter];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<5;i=i+1)
			curr_answer[i]<=0;
	else if(state_cs==IDLE)
		for(i=0;i<5;i=i+1)
			curr_answer[i]<=0;
	else if(state_ns==SORT)begin
		if(matchC==0)begin
			for(i=0;i<5;i=i+1)begin
				if(sort_arr[i]==1)
					curr_answer[i]<=pick_arr[0];
				else if(sort_arr[i]==2)
					curr_answer[i]<=pick_arr[1];
				else if(sort_arr[i]==3)
					curr_answer[i]<=pick_arr[2];
				else if(sort_arr[i]==4)
					curr_answer[i]<=pick_arr[3];
				else if(sort_arr[i]==5)
					curr_answer[i]<=pick_arr[4];
			end
		end
		else if(matchC==1)begin
			for(i=0;i<5;i=i+1)begin
				if(sort_arr[i]==1)
					curr_answer[i]<=pick_arr[0];
				else if(sort_arr[i]==2)
					curr_answer[i]<=pick_arr[1];
				else if(sort_arr[i]==3)
					curr_answer[i]<=pick_arr[2];
				else if(sort_arr[i]==4)
					curr_answer[i]<=pick_arr[3];
			end
			curr_answer[order_C0]<=sort_keyboard[5];
		end
		else if(matchC==2)begin
			for(i=0;i<5;i=i+1)begin
				if(sort_arr[i]==1)
					curr_answer[i]<=pick_arr[0];
				else if(sort_arr[i]==2)
					curr_answer[i]<=pick_arr[1];
				else if(sort_arr[i]==3)
					curr_answer[i]<=pick_arr[2];
			end
			curr_answer[order_C0]<=sort_keyboard[5];
			curr_answer[order_C1]<=sort_keyboard[6];
		end
		else if(matchC==3)begin
			for(i=0;i<5;i=i+1)begin
				if(sort_arr[i]==1)
					curr_answer[i]<=pick_arr[0];
				if(sort_arr[i]==2)
					curr_answer[i]<=pick_arr[1];
			end
			curr_answer[order_C0]<=sort_keyboard[5];
			curr_answer[order_C1]<=sort_keyboard[6];
			curr_answer[order_C2]<=sort_keyboard[7];
		end
	end
	else if(state_ns==PICK)begin
		if(matchC==0)begin
			curr_answer[0]<=pick_arr[0];
			curr_answer[1]<=pick_arr[1];
			curr_answer[2]<=pick_arr[2];
			curr_answer[3]<=pick_arr[3];
			curr_answer[4]<=pick_arr[4];
		end
		else if(matchC==1)begin
			curr_answer[0]<=pick_arr[0];
			curr_answer[1]<=pick_arr[1];
			curr_answer[2]<=pick_arr[2];
			curr_answer[3]<=pick_arr[3];
			curr_answer[4]<=0;
		end
		else if(matchC==2)begin
			curr_answer[0]<=pick_arr[0];
			curr_answer[1]<=pick_arr[1];
			curr_answer[2]<=pick_arr[2];
			curr_answer[3]<=0;
			curr_answer[4]<=0;
		end
		else if(matchC==3)begin
			curr_answer[0]<=pick_arr[0];
			curr_answer[1]<=pick_arr[1];
			curr_answer[2]<=0;
			curr_answer[3]<=0;
			curr_answer[4]<=0;
		end
	end
end

always@(*)begin
	curr_value<=(curr_answer[0]*weight_reg[0]+
				curr_answer[1]*weight_reg[1]+
				curr_answer[2]*weight_reg[2]+
				curr_answer[3]*weight_reg[3]+
				curr_answer[4]*weight_reg[4]);
	
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<5;i=i+1)
			output_answer[i]<=0;
	else if(state_cs==IDLE)
		for(i=0;i<5;i=i+1)
			output_answer[i]<=0;
	else if(state_cs==SORT && check_valid && findBigger)
		for(i=0;i<5;i=i+1)
			output_answer[i]<=curr_answer[i];
	else if(state_cs==SORT && check_valid && findEqual)begin
		if((output_answer[0]*16+output_answer[1]*8+output_answer[2]*4+output_answer[3]*2+output_answer[4]*1)<(curr_answer[0]*16+curr_answer[1]*8+curr_answer[2]*4+curr_answer[3]*2+curr_answer[4]*1))
			for(i=0;i<5;i=i+1)
				output_answer[i]<=curr_answer[i];
		else if((output_answer[0]*16+output_answer[1]*8+output_answer[2]*4+output_answer[3]*2+output_answer[4]*1)==(curr_answer[0]*16+curr_answer[1]*8+curr_answer[2]*4+curr_answer[3]*2+curr_answer[4]*1))begin
			if(output_answer[0]>curr_answer[0] ||
				(output_answer[0]==curr_answer[0] && output_answer[1]>curr_answer[1]) ||
				(output_answer[0]==curr_answer[0] && output_answer[1]==curr_answer[1] && output_answer[2]>curr_answer[2])||
				(output_answer[0]==curr_answer[0] && output_answer[1]==curr_answer[1] && output_answer[2]==curr_answer[2] && output_answer[3]>curr_answer[3])||
				(output_answer[0]==curr_answer[0] && output_answer[1]==curr_answer[1] && output_answer[2]==curr_answer[2] && output_answer[3]==curr_answer[3] && output_answer[4]>curr_answer[4]))
				for(i=0;i<5;i=i+1)
					output_answer[i]<=curr_answer[i];
		end
	end
end


always@(*)begin
	if(matchC==0)begin
		pick_idx={3'd4,3'd3,3'd2,3'd1,3'd0};
		
	end
	else if(matchC==1)begin
		case(pick_count)
			0:pick_idx={3'd5,3'd3,3'd2,3'd1,3'd0};
			1:pick_idx={3'd5,3'd4,3'd2,3'd1,3'd0};
			2:pick_idx={3'd5,3'd4,3'd3,3'd1,3'd0};
			3:pick_idx={3'd5,3'd4,3'd3,3'd2,3'd0};
			4:pick_idx={3'd5,3'd4,3'd3,3'd2,3'd1};
			default:pick_idx=0;
		endcase
	end
	else if(matchC==2)begin
		case(pick_count)
			0:pick_idx={3'd5,3'd5,3'd2,3'd1,3'd0};
			1:pick_idx={3'd5,3'd5,3'd3,3'd1,3'd0};
			2:pick_idx={3'd5,3'd5,3'd4,3'd1,3'd0};
			3:pick_idx={3'd5,3'd5,3'd3,3'd2,3'd0};
			4:pick_idx={3'd5,3'd5,3'd4,3'd2,3'd0};
			5:pick_idx={3'd5,3'd5,3'd4,3'd3,3'd0};
			6:pick_idx={3'd5,3'd5,3'd3,3'd2,3'd1};
			7:pick_idx={3'd5,3'd5,3'd4,3'd2,3'd1};
			8:pick_idx={3'd5,3'd5,3'd4,3'd3,3'd1};
			9:pick_idx={3'd5,3'd5,3'd4,3'd3,3'd2};
			default:pick_idx=0;
		endcase
	end
	else if(matchC==3)begin
		case(pick_count)
			0:pick_idx={3'd5,3'd5,3'd5,3'd1,3'd0};
			1:pick_idx={3'd5,3'd5,3'd5,3'd2,3'd0};
			2:pick_idx={3'd5,3'd5,3'd5,3'd3,3'd0};
			3:pick_idx={3'd5,3'd5,3'd5,3'd4,3'd0};
			4:pick_idx={3'd5,3'd5,3'd5,3'd2,3'd1};
			5:pick_idx={3'd5,3'd5,3'd5,3'd3,3'd1};
			6:pick_idx={3'd5,3'd5,3'd5,3'd4,3'd1};
			7:pick_idx={3'd5,3'd5,3'd5,3'd3,3'd2};
			8:pick_idx={3'd5,3'd5,3'd5,3'd4,3'd2};
			9:pick_idx={3'd5,3'd5,3'd5,3'd4,3'd3};
			default:pick_idx=0;
		endcase
	end
	else
		pick_idx=0;
end

always@(*)begin
	if(matchC==0)begin
		case(sort_count)
			0:sort_idx =  {3'd1,3'd2,3'd3,3'd4,3'd5};
			1:sort_idx =  {3'd1,3'd2,3'd3,3'd5,3'd4};
			2:sort_idx =  {3'd1,3'd2,3'd5,3'd3,3'd4};
			3:sort_idx =  {3'd1,3'd5,3'd2,3'd3,3'd4};
			4:sort_idx =  {3'd5,3'd1,3'd2,3'd3,3'd4};
			5:sort_idx =  {3'd1,3'd2,3'd4,3'd3,3'd5};
			6:sort_idx =  {3'd1,3'd2,3'd4,3'd5,3'd3};
			7:sort_idx =  {3'd1,3'd2,3'd5,3'd4,3'd3};
			8:sort_idx =  {3'd1,3'd5,3'd2,3'd4,3'd3};
			9:sort_idx =  {3'd5,3'd1,3'd2,3'd4,3'd3};
			10:sort_idx =  {3'd1,3'd3,3'd2,3'd4,3'd5};
			11:sort_idx =  {3'd1,3'd3,3'd2,3'd5,3'd4};
			12:sort_idx =  {3'd1,3'd3,3'd5,3'd2,3'd4};
			13:sort_idx =  {3'd1,3'd5,3'd3,3'd2,3'd4};
			14:sort_idx =  {3'd5,3'd1,3'd3,3'd2,3'd4};
			15:sort_idx =  {3'd1,3'd3,3'd4,3'd2,3'd5};
			16:sort_idx =  {3'd1,3'd3,3'd4,3'd5,3'd2};
			17:sort_idx =  {3'd1,3'd3,3'd5,3'd4,3'd2};
			18:sort_idx =  {3'd1,3'd5,3'd3,3'd4,3'd2};
			19:sort_idx =  {3'd5,3'd1,3'd3,3'd4,3'd2};
			20:sort_idx =  {3'd1,3'd4,3'd2,3'd3,3'd5};
			21:sort_idx =  {3'd1,3'd4,3'd2,3'd5,3'd3};
			22:sort_idx =  {3'd1,3'd4,3'd5,3'd2,3'd3};
			23:sort_idx =  {3'd1,3'd5,3'd4,3'd2,3'd3};
			24:sort_idx =  {3'd5,3'd1,3'd4,3'd2,3'd3};
			25:sort_idx =  {3'd1,3'd4,3'd3,3'd2,3'd5};
			26:sort_idx =  {3'd1,3'd4,3'd3,3'd5,3'd2};
			27:sort_idx =  {3'd1,3'd4,3'd5,3'd3,3'd2};
			28:sort_idx =  {3'd1,3'd5,3'd4,3'd3,3'd2};
			29:sort_idx =  {3'd5,3'd1,3'd4,3'd3,3'd2};
			30:sort_idx =  {3'd2,3'd1,3'd3,3'd4,3'd5};
			31:sort_idx =  {3'd2,3'd1,3'd3,3'd5,3'd4};
			32:sort_idx =  {3'd2,3'd1,3'd5,3'd3,3'd4};
			33:sort_idx =  {3'd2,3'd5,3'd1,3'd3,3'd4};
			34:sort_idx =  {3'd5,3'd2,3'd1,3'd3,3'd4};
			35:sort_idx =  {3'd2,3'd1,3'd4,3'd3,3'd5};
			36:sort_idx =  {3'd2,3'd1,3'd4,3'd5,3'd3};
			37:sort_idx =  {3'd2,3'd1,3'd5,3'd4,3'd3};
			38:sort_idx =  {3'd2,3'd5,3'd1,3'd4,3'd3};
			39:sort_idx =  {3'd5,3'd2,3'd1,3'd4,3'd3};
			40:sort_idx =  {3'd2,3'd3,3'd1,3'd4,3'd5};
			41:sort_idx =  {3'd2,3'd3,3'd1,3'd5,3'd4};
			42:sort_idx =  {3'd2,3'd3,3'd5,3'd1,3'd4};
			43:sort_idx =  {3'd2,3'd5,3'd3,3'd1,3'd4};
			44:sort_idx =  {3'd5,3'd2,3'd3,3'd1,3'd4};
			45:sort_idx =  {3'd2,3'd3,3'd4,3'd1,3'd5};
			46:sort_idx =  {3'd2,3'd3,3'd4,3'd5,3'd1};
			47:sort_idx =  {3'd2,3'd3,3'd5,3'd4,3'd1};
			48:sort_idx =  {3'd2,3'd5,3'd3,3'd4,3'd1};
			49:sort_idx =  {3'd5,3'd2,3'd3,3'd4,3'd1};
			50:sort_idx =  {3'd2,3'd4,3'd1,3'd3,3'd5};
			51:sort_idx =  {3'd2,3'd4,3'd1,3'd5,3'd3};
			52:sort_idx =  {3'd2,3'd4,3'd5,3'd1,3'd3};
			53:sort_idx =  {3'd2,3'd5,3'd4,3'd1,3'd3};
			54:sort_idx =  {3'd5,3'd2,3'd4,3'd1,3'd3};
			55:sort_idx =  {3'd2,3'd4,3'd3,3'd1,3'd5};
			56:sort_idx =  {3'd2,3'd4,3'd3,3'd5,3'd1};
			57:sort_idx =  {3'd2,3'd4,3'd5,3'd3,3'd1};
			58:sort_idx =  {3'd2,3'd5,3'd4,3'd3,3'd1};
			59:sort_idx =  {3'd5,3'd2,3'd4,3'd3,3'd1};
			60:sort_idx =  {3'd3,3'd1,3'd2,3'd4,3'd5};
			61:sort_idx =  {3'd3,3'd1,3'd2,3'd5,3'd4};
			62:sort_idx =  {3'd3,3'd1,3'd5,3'd2,3'd4};
			63:sort_idx =  {3'd3,3'd5,3'd1,3'd2,3'd4};
			64:sort_idx =  {3'd5,3'd3,3'd1,3'd2,3'd4};
			65:sort_idx =  {3'd3,3'd1,3'd4,3'd2,3'd5};
			66:sort_idx =  {3'd3,3'd1,3'd4,3'd5,3'd2};
			67:sort_idx =  {3'd3,3'd1,3'd5,3'd4,3'd2};
			68:sort_idx =  {3'd3,3'd5,3'd1,3'd4,3'd2};
			69:sort_idx =  {3'd5,3'd3,3'd1,3'd4,3'd2};
			70:sort_idx =  {3'd3,3'd2,3'd1,3'd4,3'd5};
			71:sort_idx =  {3'd3,3'd2,3'd1,3'd5,3'd4};
			72:sort_idx =  {3'd3,3'd2,3'd5,3'd1,3'd4};
			73:sort_idx =  {3'd3,3'd5,3'd2,3'd1,3'd4};
			74:sort_idx =  {3'd5,3'd3,3'd2,3'd1,3'd4};
			75:sort_idx =  {3'd3,3'd2,3'd4,3'd1,3'd5};
			76:sort_idx =  {3'd3,3'd2,3'd4,3'd5,3'd1};
			77:sort_idx =  {3'd3,3'd2,3'd5,3'd4,3'd1};
			78:sort_idx =  {3'd3,3'd5,3'd2,3'd4,3'd1};
			79:sort_idx =  {3'd5,3'd3,3'd2,3'd4,3'd1};
			80:sort_idx =  {3'd3,3'd4,3'd1,3'd2,3'd5};
			81:sort_idx =  {3'd3,3'd4,3'd1,3'd5,3'd2};
			82:sort_idx =  {3'd3,3'd4,3'd5,3'd1,3'd2};
			83:sort_idx =  {3'd3,3'd5,3'd4,3'd1,3'd2};
			84:sort_idx =  {3'd5,3'd3,3'd4,3'd1,3'd2};
			85:sort_idx =  {3'd3,3'd4,3'd2,3'd1,3'd5};
			86:sort_idx =  {3'd3,3'd4,3'd2,3'd5,3'd1};
			87:sort_idx =  {3'd3,3'd4,3'd5,3'd2,3'd1};
			88:sort_idx =  {3'd3,3'd5,3'd4,3'd2,3'd1};
			89:sort_idx =  {3'd5,3'd3,3'd4,3'd2,3'd1};
			90:sort_idx =  {3'd4,3'd1,3'd2,3'd3,3'd5};
			91:sort_idx =  {3'd4,3'd1,3'd2,3'd5,3'd3};
			92:sort_idx =  {3'd4,3'd1,3'd5,3'd2,3'd3};
			93:sort_idx =  {3'd4,3'd5,3'd1,3'd2,3'd3};
			94:sort_idx =  {3'd5,3'd4,3'd1,3'd2,3'd3};
			95:sort_idx =  {3'd4,3'd1,3'd3,3'd2,3'd5};
			96:sort_idx =  {3'd4,3'd1,3'd3,3'd5,3'd2};
			97:sort_idx =  {3'd4,3'd1,3'd5,3'd3,3'd2};
			98:sort_idx =  {3'd4,3'd5,3'd1,3'd3,3'd2};
			99:sort_idx =  {3'd5,3'd4,3'd1,3'd3,3'd2};
			100:sort_idx =  {3'd4,3'd2,3'd1,3'd3,3'd5};
			101:sort_idx =  {3'd4,3'd2,3'd1,3'd5,3'd3};
			102:sort_idx =  {3'd4,3'd2,3'd5,3'd1,3'd3};
			103:sort_idx =  {3'd4,3'd5,3'd2,3'd1,3'd3};
			104:sort_idx =  {3'd5,3'd4,3'd2,3'd1,3'd3};
			105:sort_idx =  {3'd4,3'd2,3'd3,3'd1,3'd5};
			106:sort_idx =  {3'd4,3'd2,3'd3,3'd5,3'd1};
			107:sort_idx =  {3'd4,3'd2,3'd5,3'd3,3'd1};
			108:sort_idx =  {3'd4,3'd5,3'd2,3'd3,3'd1};
			109:sort_idx =  {3'd5,3'd4,3'd2,3'd3,3'd1};
			110:sort_idx =  {3'd4,3'd3,3'd1,3'd2,3'd5};
			111:sort_idx =  {3'd4,3'd3,3'd1,3'd5,3'd2};
			112:sort_idx =  {3'd4,3'd3,3'd5,3'd1,3'd2};
			113:sort_idx =  {3'd4,3'd5,3'd3,3'd1,3'd2};
			114:sort_idx =  {3'd5,3'd4,3'd3,3'd1,3'd2};
			115:sort_idx =  {3'd4,3'd3,3'd2,3'd1,3'd5};
			116:sort_idx =  {3'd4,3'd3,3'd2,3'd5,3'd1};
			117:sort_idx =  {3'd4,3'd3,3'd5,3'd2,3'd1};
			118:sort_idx =  {3'd4,3'd5,3'd3,3'd2,3'd1};
			119:sort_idx =  {3'd5,3'd4,3'd3,3'd2,3'd1};
			default:sort_idx = 0;
		endcase
	end
	else if(matchC==1)begin
		case(sort_count)
			0:sort_idx =  {3'd1,3'd2,3'd3,3'd4,3'd0};
			1:sort_idx =  {3'd1,3'd2,3'd3,3'd0,3'd4};
			2:sort_idx =  {3'd1,3'd2,3'd0,3'd3,3'd4};
			3:sort_idx =  {3'd1,3'd0,3'd2,3'd3,3'd4};
			4:sort_idx =  {3'd0,3'd1,3'd2,3'd3,3'd4};
			5:sort_idx =  {3'd1,3'd2,3'd4,3'd3,3'd0};
			6:sort_idx =  {3'd1,3'd2,3'd4,3'd0,3'd3};
			7:sort_idx =  {3'd1,3'd2,3'd0,3'd4,3'd3};
			8:sort_idx =  {3'd1,3'd0,3'd2,3'd4,3'd3};
			9:sort_idx =  {3'd0,3'd1,3'd2,3'd4,3'd3};
			10:sort_idx =  {3'd1,3'd3,3'd2,3'd4,3'd0};
			11:sort_idx =  {3'd1,3'd3,3'd2,3'd0,3'd4};
			12:sort_idx =  {3'd1,3'd3,3'd0,3'd2,3'd4};
			13:sort_idx =  {3'd1,3'd0,3'd3,3'd2,3'd4};
			14:sort_idx =  {3'd0,3'd1,3'd3,3'd2,3'd4};
			15:sort_idx =  {3'd1,3'd3,3'd4,3'd2,3'd0};
			16:sort_idx =  {3'd1,3'd3,3'd4,3'd0,3'd2};
			17:sort_idx =  {3'd1,3'd3,3'd0,3'd4,3'd2};
			18:sort_idx =  {3'd1,3'd0,3'd3,3'd4,3'd2};
			19:sort_idx =  {3'd0,3'd1,3'd3,3'd4,3'd2};
			20:sort_idx =  {3'd1,3'd4,3'd2,3'd3,3'd0};
			21:sort_idx =  {3'd1,3'd4,3'd2,3'd0,3'd3};
			22:sort_idx =  {3'd1,3'd4,3'd0,3'd2,3'd3};
			23:sort_idx =  {3'd1,3'd0,3'd4,3'd2,3'd3};
			24:sort_idx =  {3'd0,3'd1,3'd4,3'd2,3'd3};
			25:sort_idx =  {3'd1,3'd4,3'd3,3'd2,3'd0};
			26:sort_idx =  {3'd1,3'd4,3'd3,3'd0,3'd2};
			27:sort_idx =  {3'd1,3'd4,3'd0,3'd3,3'd2};
			28:sort_idx =  {3'd1,3'd0,3'd4,3'd3,3'd2};
			29:sort_idx =  {3'd0,3'd1,3'd4,3'd3,3'd2};
			30:sort_idx =  {3'd2,3'd1,3'd3,3'd4,3'd0};
			31:sort_idx =  {3'd2,3'd1,3'd3,3'd0,3'd4};
			32:sort_idx =  {3'd2,3'd1,3'd0,3'd3,3'd4};
			33:sort_idx =  {3'd2,3'd0,3'd1,3'd3,3'd4};
			34:sort_idx =  {3'd0,3'd2,3'd1,3'd3,3'd4};
			35:sort_idx =  {3'd2,3'd1,3'd4,3'd3,3'd0};
			36:sort_idx =  {3'd2,3'd1,3'd4,3'd0,3'd3};
			37:sort_idx =  {3'd2,3'd1,3'd0,3'd4,3'd3};
			38:sort_idx =  {3'd2,3'd0,3'd1,3'd4,3'd3};
			39:sort_idx =  {3'd0,3'd2,3'd1,3'd4,3'd3};
			40:sort_idx =  {3'd2,3'd3,3'd1,3'd4,3'd0};
			41:sort_idx =  {3'd2,3'd3,3'd1,3'd0,3'd4};
			42:sort_idx =  {3'd2,3'd3,3'd0,3'd1,3'd4};
			43:sort_idx =  {3'd2,3'd0,3'd3,3'd1,3'd4};
			44:sort_idx =  {3'd0,3'd2,3'd3,3'd1,3'd4};
			45:sort_idx =  {3'd2,3'd3,3'd4,3'd1,3'd0};
			46:sort_idx =  {3'd2,3'd3,3'd4,3'd0,3'd1};
			47:sort_idx =  {3'd2,3'd3,3'd0,3'd4,3'd1};
			48:sort_idx =  {3'd2,3'd0,3'd3,3'd4,3'd1};
			49:sort_idx =  {3'd0,3'd2,3'd3,3'd4,3'd1};
			50:sort_idx =  {3'd2,3'd4,3'd1,3'd3,3'd0};
			51:sort_idx =  {3'd2,3'd4,3'd1,3'd0,3'd3};
			52:sort_idx =  {3'd2,3'd4,3'd0,3'd1,3'd3};
			53:sort_idx =  {3'd2,3'd0,3'd4,3'd1,3'd3};
			54:sort_idx =  {3'd0,3'd2,3'd4,3'd1,3'd3};
			55:sort_idx =  {3'd2,3'd4,3'd3,3'd1,3'd0};
			56:sort_idx =  {3'd2,3'd4,3'd3,3'd0,3'd1};
			57:sort_idx =  {3'd2,3'd4,3'd0,3'd3,3'd1};
			58:sort_idx =  {3'd2,3'd0,3'd4,3'd3,3'd1};
			59:sort_idx =  {3'd0,3'd2,3'd4,3'd3,3'd1};
			60:sort_idx =  {3'd3,3'd1,3'd2,3'd4,3'd0};
			61:sort_idx =  {3'd3,3'd1,3'd2,3'd0,3'd4};
			62:sort_idx =  {3'd3,3'd1,3'd0,3'd2,3'd4};
			63:sort_idx =  {3'd3,3'd0,3'd1,3'd2,3'd4};
			64:sort_idx =  {3'd0,3'd3,3'd1,3'd2,3'd4};
			65:sort_idx =  {3'd3,3'd1,3'd4,3'd2,3'd0};
			66:sort_idx =  {3'd3,3'd1,3'd4,3'd0,3'd2};
			67:sort_idx =  {3'd3,3'd1,3'd0,3'd4,3'd2};
			68:sort_idx =  {3'd3,3'd0,3'd1,3'd4,3'd2};
			69:sort_idx =  {3'd0,3'd3,3'd1,3'd4,3'd2};
			70:sort_idx =  {3'd3,3'd2,3'd1,3'd4,3'd0};
			71:sort_idx =  {3'd3,3'd2,3'd1,3'd0,3'd4};
			72:sort_idx =  {3'd3,3'd2,3'd0,3'd1,3'd4};
			73:sort_idx =  {3'd3,3'd0,3'd2,3'd1,3'd4};
			74:sort_idx =  {3'd0,3'd3,3'd2,3'd1,3'd4};
			75:sort_idx =  {3'd3,3'd2,3'd4,3'd1,3'd0};
			76:sort_idx =  {3'd3,3'd2,3'd4,3'd0,3'd1};
			77:sort_idx =  {3'd3,3'd2,3'd0,3'd4,3'd1};
			78:sort_idx =  {3'd3,3'd0,3'd2,3'd4,3'd1};
			79:sort_idx =  {3'd0,3'd3,3'd2,3'd4,3'd1};
			80:sort_idx =  {3'd3,3'd4,3'd1,3'd2,3'd0};
			81:sort_idx =  {3'd3,3'd4,3'd1,3'd0,3'd2};
			82:sort_idx =  {3'd3,3'd4,3'd0,3'd1,3'd2};
			83:sort_idx =  {3'd3,3'd0,3'd4,3'd1,3'd2};
			84:sort_idx =  {3'd0,3'd3,3'd4,3'd1,3'd2};
			85:sort_idx =  {3'd3,3'd4,3'd2,3'd1,3'd0};
			86:sort_idx =  {3'd3,3'd4,3'd2,3'd0,3'd1};
			87:sort_idx =  {3'd3,3'd4,3'd0,3'd2,3'd1};
			88:sort_idx =  {3'd3,3'd0,3'd4,3'd2,3'd1};
			89:sort_idx =  {3'd0,3'd3,3'd4,3'd2,3'd1};
			90:sort_idx =  {3'd4,3'd1,3'd2,3'd3,3'd0};
			91:sort_idx =  {3'd4,3'd1,3'd2,3'd0,3'd3};
			92:sort_idx =  {3'd4,3'd1,3'd0,3'd2,3'd3};
			93:sort_idx =  {3'd4,3'd0,3'd1,3'd2,3'd3};
			94:sort_idx =  {3'd0,3'd4,3'd1,3'd2,3'd3};
			95:sort_idx =  {3'd4,3'd1,3'd3,3'd2,3'd0};
			96:sort_idx =  {3'd4,3'd1,3'd3,3'd0,3'd2};
			97:sort_idx =  {3'd4,3'd1,3'd0,3'd3,3'd2};
			98:sort_idx =  {3'd4,3'd0,3'd1,3'd3,3'd2};
			99:sort_idx =  {3'd0,3'd4,3'd1,3'd3,3'd2};
			100:sort_idx =  {3'd4,3'd2,3'd1,3'd3,3'd0};
			101:sort_idx =  {3'd4,3'd2,3'd1,3'd0,3'd3};
			102:sort_idx =  {3'd4,3'd2,3'd0,3'd1,3'd3};
			103:sort_idx =  {3'd4,3'd0,3'd2,3'd1,3'd3};
			104:sort_idx =  {3'd0,3'd4,3'd2,3'd1,3'd3};
			105:sort_idx =  {3'd4,3'd2,3'd3,3'd1,3'd0};
			106:sort_idx =  {3'd4,3'd2,3'd3,3'd0,3'd1};
			107:sort_idx =  {3'd4,3'd2,3'd0,3'd3,3'd1};
			108:sort_idx =  {3'd4,3'd0,3'd2,3'd3,3'd1};
			109:sort_idx =  {3'd0,3'd4,3'd2,3'd3,3'd1};
			110:sort_idx =  {3'd4,3'd3,3'd1,3'd2,3'd0};
			111:sort_idx =  {3'd4,3'd3,3'd1,3'd0,3'd2};
			112:sort_idx =  {3'd4,3'd3,3'd0,3'd1,3'd2};
			113:sort_idx =  {3'd4,3'd0,3'd3,3'd1,3'd2};
			114:sort_idx =  {3'd0,3'd4,3'd3,3'd1,3'd2};
			115:sort_idx =  {3'd4,3'd3,3'd2,3'd1,3'd0};
			116:sort_idx =  {3'd4,3'd3,3'd2,3'd0,3'd1};
			117:sort_idx =  {3'd4,3'd3,3'd0,3'd2,3'd1};
			118:sort_idx =  {3'd4,3'd0,3'd3,3'd2,3'd1};
			119:sort_idx =  {3'd0,3'd4,3'd3,3'd2,3'd1};
			default: sort_idx = 0;
		endcase
	end
	else if(matchC==2)begin
		case(sort_count)
			0:sort_idx =  {3'd1,3'd2,3'd3,3'd0,3'd0};
			1:sort_idx =  {3'd1,3'd2,3'd0,3'd3,3'd0};
			2:sort_idx =  {3'd1,3'd2,3'd0,3'd0,3'd3};
			3:sort_idx =  {3'd1,3'd0,3'd2,3'd3,3'd0};
			4:sort_idx =  {3'd1,3'd0,3'd2,3'd0,3'd3};
			5:sort_idx =  {3'd1,3'd0,3'd0,3'd2,3'd3};
			6:sort_idx =  {3'd0,3'd1,3'd2,3'd3,3'd0};
			7:sort_idx =  {3'd0,3'd1,3'd2,3'd0,3'd3};
			8:sort_idx =  {3'd0,3'd1,3'd0,3'd2,3'd3};
			9:sort_idx =  {3'd0,3'd0,3'd1,3'd2,3'd3};
			10:sort_idx = {3'd1,3'd3,3'd2,3'd0,3'd0};
			11:sort_idx = {3'd1,3'd3,3'd0,3'd2,3'd0};
			12:sort_idx = {3'd1,3'd3,3'd0,3'd0,3'd2};
			13:sort_idx = {3'd1,3'd0,3'd3,3'd2,3'd0};
			14:sort_idx = {3'd1,3'd0,3'd3,3'd0,3'd2};
			15:sort_idx = {3'd1,3'd0,3'd0,3'd3,3'd2};
			16:sort_idx = {3'd0,3'd1,3'd3,3'd2,3'd0};
			17:sort_idx = {3'd0,3'd1,3'd3,3'd0,3'd2};
			18:sort_idx = {3'd0,3'd1,3'd0,3'd3,3'd2};
			19:sort_idx = {3'd0,3'd0,3'd1,3'd3,3'd2};
			20:sort_idx = {3'd2,3'd1,3'd3,3'd0,3'd0};
			21:sort_idx = {3'd2,3'd1,3'd0,3'd3,3'd0};
			22:sort_idx = {3'd2,3'd1,3'd0,3'd0,3'd3};
			23:sort_idx = {3'd2,3'd0,3'd1,3'd3,3'd0};
			24:sort_idx = {3'd2,3'd0,3'd1,3'd0,3'd3};
			25:sort_idx = {3'd2,3'd0,3'd0,3'd1,3'd3};
			26:sort_idx = {3'd0,3'd2,3'd1,3'd3,3'd0};
			27:sort_idx = {3'd0,3'd2,3'd1,3'd0,3'd3};
			28:sort_idx = {3'd0,3'd2,3'd0,3'd1,3'd3};
			29:sort_idx = {3'd0,3'd0,3'd2,3'd1,3'd3};
			30:sort_idx = {3'd2,3'd3,3'd1,3'd0,3'd0};
			31:sort_idx = {3'd2,3'd3,3'd0,3'd1,3'd0};
			32:sort_idx = {3'd2,3'd3,3'd0,3'd0,3'd1};
			33:sort_idx = {3'd2,3'd0,3'd3,3'd1,3'd0};
			34:sort_idx = {3'd2,3'd0,3'd3,3'd0,3'd1};
			35:sort_idx = {3'd2,3'd0,3'd0,3'd3,3'd1};
			36:sort_idx = {3'd0,3'd2,3'd3,3'd1,3'd0};
			37:sort_idx = {3'd0,3'd2,3'd3,3'd0,3'd1};
			38:sort_idx = {3'd0,3'd2,3'd0,3'd3,3'd1};
			39:sort_idx = {3'd0,3'd0,3'd2,3'd3,3'd1};
			40:sort_idx = {3'd3,3'd1,3'd2,3'd0,3'd0};
			41:sort_idx = {3'd3,3'd1,3'd0,3'd2,3'd0};
			42:sort_idx = {3'd3,3'd1,3'd0,3'd0,3'd2};
			43:sort_idx = {3'd3,3'd0,3'd1,3'd2,3'd0};
			44:sort_idx = {3'd3,3'd0,3'd1,3'd0,3'd2};
			45:sort_idx = {3'd3,3'd0,3'd0,3'd1,3'd2};
			46:sort_idx = {3'd0,3'd3,3'd1,3'd2,3'd0};
			47:sort_idx = {3'd0,3'd3,3'd1,3'd0,3'd2};
			48:sort_idx = {3'd0,3'd3,3'd0,3'd1,3'd2};
			49:sort_idx = {3'd0,3'd0,3'd3,3'd1,3'd2};
			50:sort_idx = {3'd3,3'd2,3'd1,3'd0,3'd0};
			51:sort_idx = {3'd3,3'd2,3'd0,3'd1,3'd0};
			52:sort_idx = {3'd3,3'd2,3'd0,3'd0,3'd1};
			53:sort_idx = {3'd3,3'd0,3'd2,3'd1,3'd0};
			54:sort_idx = {3'd3,3'd0,3'd2,3'd0,3'd1};
			55:sort_idx = {3'd3,3'd0,3'd0,3'd2,3'd1};
			56:sort_idx = {3'd0,3'd3,3'd2,3'd1,3'd0};
			57:sort_idx = {3'd0,3'd3,3'd2,3'd0,3'd1};
			58:sort_idx = {3'd0,3'd3,3'd0,3'd2,3'd1};
			59:sort_idx = {3'd0,3'd0,3'd3,3'd2,3'd1};
			default: sort_idx = 0;
		endcase
	end
	else if(matchC==3)begin
		case(sort_count)
			0:sort_idx =  {3'd1,3'd2,3'd0,3'd0,3'd0};
			1:sort_idx =  {3'd1,3'd0,3'd2,3'd0,3'd0};
			2:sort_idx =  {3'd1,3'd0,3'd0,3'd2,3'd0};
			3:sort_idx =  {3'd1,3'd0,3'd0,3'd0,3'd2};
			4:sort_idx =  {3'd0,3'd1,3'd2,3'd0,3'd0};
			5:sort_idx =  {3'd0,3'd1,3'd0,3'd2,3'd0};
			6:sort_idx =  {3'd0,3'd1,3'd0,3'd0,3'd2};
			7:sort_idx =  {3'd0,3'd0,3'd1,3'd2,3'd0};
			8:sort_idx =  {3'd0,3'd0,3'd1,3'd0,3'd2};
			9:sort_idx =  {3'd0,3'd0,3'd0,3'd1,3'd2};
			10:sort_idx = {3'd2,3'd1,3'd0,3'd0,3'd0};
			11:sort_idx = {3'd2,3'd0,3'd1,3'd0,3'd0};
			12:sort_idx = {3'd2,3'd0,3'd0,3'd1,3'd0};
			13:sort_idx = {3'd2,3'd0,3'd0,3'd0,3'd1};
			14:sort_idx = {3'd0,3'd2,3'd1,3'd0,3'd0};
			15:sort_idx = {3'd0,3'd2,3'd0,3'd1,3'd0};
			16:sort_idx = {3'd0,3'd2,3'd0,3'd0,3'd1};
			17:sort_idx = {3'd0,3'd0,3'd2,3'd1,3'd0};
			18:sort_idx = {3'd0,3'd0,3'd2,3'd0,3'd1};
			19:sort_idx = {3'd0,3'd0,3'd0,3'd2,3'd1};
			default:sort_idx = 0;
		endcase
	end
	else
		sort_idx = 0;
end

/*
C   pick_times  sort_times	total
0	1			120			120
1	5			120			600
2	10			60			600
3 	10			20			200
*/

always@(*)begin
	if(matchC==0)
		pick_num = 1;
	else if(matchC==1)
		pick_num = 5;
	else if(matchC==2)
		pick_num = 10;
	else 
		pick_num = 10;
end

always@(*)begin
	if(matchC==0)
		sort_num = 120;
	else if(matchC==1)
		sort_num = 120;
	else if(matchC==2)
		sort_num = 60;
	else
		sort_num = 20;
end


function Check_isAB;
	input [4:0]answer_in0,answer_in1,answer_in2,answer_in3,answer_in4,curr_keyboard;
	begin
		if(curr_keyboard==answer_in0)
			Check_isAB=1;
		else if(curr_keyboard==answer_in1)
			Check_isAB=1;
		else if(curr_keyboard==answer_in2)
			Check_isAB=1;
		else if(curr_keyboard==answer_in3)
			Check_isAB=1;
		else if(curr_keyboard==answer_in4)
			Check_isAB=1;
		else
			Check_isAB=0;
	end
endfunction

function [8:0]remainC;
	input [2:0]in0,in1,in2,in3,in4;
	reg [2:0]id [0:2];
	
	reg [2:0]counter;
	begin
		// init the variable
		id[0] = 5;
		id[1] = 5;
		id[2] = 5;
		counter=0;
		// find C idx
		if(in0==0)begin
			id[counter] = 0;
			counter = counter+1;
		end
		if(in1==0)begin
			id[counter] = 1;
			counter = counter+1;
		end
		if(in2==0)begin
			id[counter] = 2;
			counter = counter+1;
		end
		if(in3==0)begin
			id[counter] = 3;
			counter = counter+1;
		end
		if(in4==0)begin
			id[counter] = 4;
			counter = counter+1;
		end
		remainC = {id[0],id[1],id[2]};
	end
endfunction

function [8:0]sortC;
	input [4:0] w0,w1,w2,id0,id1,id2;
	reg comp0,comp1,comp2;
	begin
		w0=(id0==5)?0:w0;
		w1=(id1==5)?0:w1;
		w2=(id2==5)?0:w2;
		if(w0>w1)
			comp0=1;
		else 
			comp0=0;
		if(w0>w2)
			comp1=1;
		else
			comp1=0;
		if(w1>w2)
			comp2=1;
		else
			comp2=0;
		if(comp0 && comp1 && comp2) //012
			sortC={id0[2:0],id1[2:0],id2[2:0]};
		else if(comp0 &&comp1 && !comp2)	//021
			sortC={id0[2:0],id2[2:0],id1[2:0]};
		else if(!comp0 && comp1 && comp2)	//102
			sortC={id1[2:0],id0[2:0],id2[2:0]};
		else if(!comp0 && !comp1 && comp2)	//120
			sortC={id1[2:0],id2[2:0],id0[2:0]};
		else if(comp0 && !comp1 && !comp2)	//201
			sortC={id2[2:0],id0[2:0],id1[2:0]};
		else //210
			sortC={id2[2:0],id1[2:0],id0[2:0]};
	end
endfunction

function validation;
	input [4:0] ans0,ans1,ans2,ans3,ans4,in0,in1,in2,in3,in4,A;
	reg [2:0]currA;
	begin
		currA=0;
		if(ans0==in0)
			currA=currA+1;
		if(ans1==in1)
			currA=currA+1;
		if(ans2==in2)
			currA=currA+1;
		if(ans3==in3)
			currA=currA+1;
		if(ans4==in4)
			currA=currA+1;
		if(currA!=A)
			validation=0;
		else
			validation=1;
	end
endfunction


endmodule
