module TMIP(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid_2,
    image,
	img_size,
    template, 
    action,
	
// output signals
    out_valid,
    out_x,
    out_y,
    out_img_pos,
    out_value
);

input        clk, rst_n, in_valid, in_valid_2;
input [15:0] image, template;
input [4:0]  img_size;
input [2:0]  action;

output reg        out_valid;
output reg [3:0]  out_x, out_y; 
output reg [7:0]  out_img_pos;
output reg signed[39:0] out_value;

// integer
integer i;
// parameter
parameter IDLE = 4'd0;
parameter RD	=4'd1;
parameter IDLE2 =4'd2;
parameter RD_ACT = 4'd3;
parameter IDLE5 =4'd14;
parameter SEL_ACT =4'd4;
parameter RD_REG1 =4'd8;
parameter RD_REG2 =4'd9;
parameter WR_REG1 =4'd10;
parameter WR_REG2 =4'd11;
parameter IDLE4 =4'd13;
parameter OP	=4'd5;
parameter OP_WR =4'd12;
parameter IDLE3 =4'd7;
parameter DONE	=4'd6;

// reg
reg [3:0]state_cs,state_ns;
reg [8:0]counter;
reg [4:0]ACT_num;
reg [4:0]counter_act;
reg [4:0]img_size_reg;
reg [2:0]act_reg [0:15];
reg signed[15:0] template_reg[0:8];
reg signed[15:0] image_reg[0:63];
reg mode_sel;
//addr1
reg [3:0]addr_x;
reg [3:0]addr_y;
reg [7:0]addr2counter;
//addr2
reg [3:0]addr_x2;
reg [3:0]addr_y2;
reg [7:0]addr2counter2;

reg signed[39:0] tmp_read_reg1;
reg signed[39:0] tmp_read_reg2;
// wire
wire doneACT;
reg doneSwitch;
wire doneOUTPUT;
reg doneOP;
reg [3:0]OP_RD_cycle;
reg [2:0]OP_WR_cycle;
reg [3:0]counter_OP_RD;
reg [3:0]counter_OP_WR;
wire doneOP_RD;
wire doneOP_WR;
wire [2:0]curr_act;
wire signed [39:0] trans_input;
wire signed [15:0] trans_img;
reg passSIT;



// sram reg wire
wire signed[39:0]Q_mem_out;
wire mem_cen;
reg mem_wen;
reg [7:0]mem_address;
reg signed[39:0]D_mem_in;
wire mem_oen;
assign mem_cen=0;
assign mem_oen=0;

// sram2 reg wire
wire signed[39:0]Q_mem_out2;
wire mem_cen2;
reg mem_wen2;
reg [7:0]mem_address2;
reg signed[39:0]D_mem_in2;
wire mem_oen2;
assign mem_cen2=0;
assign mem_oen2=0;


// assign 
assign doneOP_RD = counter_OP_RD==OP_RD_cycle;
assign doneOP_WR = counter_OP_WR==OP_WR_cycle;
assign doneACT = (counter_act==ACT_num);
//assign doneSwitch = counter==(img_size_reg*img_size_reg/2-1);
assign doneOUTPUT = counter==(img_size_reg*img_size_reg)+2;
assign curr_act = act_reg[counter_act];
//assign doneOP = counter==10;


//FSM
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE : state_ns=(in_valid)?RD:IDLE;
		RD	:state_ns=(!in_valid)?IDLE2:RD;
		IDLE2 : state_ns=(in_valid_2)?RD_ACT:IDLE2;
		RD_ACT: state_ns=(!in_valid_2)?SEL_ACT:RD_ACT;
		IDLE5: state_ns = SEL_ACT;
		SEL_ACT:state_ns=(doneACT)?IDLE3:((mode_sel)?RD_REG1:((passSIT)?SEL_ACT:IDLE4));
		RD_REG1:state_ns=RD_REG2;
		RD_REG2:state_ns=WR_REG1;
		WR_REG1:state_ns=WR_REG2;
		WR_REG2:state_ns=(doneSwitch)?IDLE5:RD_REG1;
		IDLE4: state_ns = OP;
		OP	:state_ns=((doneOP_RD)?OP_WR:OP);
		OP_WR:state_ns=(doneOP)?IDLE5:(doneOP_WR?IDLE4:OP_WR);
		IDLE3: state_ns=DONE;
		DONE:state_ns=(doneOUTPUT)?IDLE:DONE;
		default:state_ns=state_cs;
	endcase
end
//counter
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_ns==SEL_ACT || state_ns==IDLE || state_ns==IDLE2 || state_ns==IDLE5)
		counter<=0;
	else if(state_cs==WR_REG2 || state_ns==DONE || state_ns==RD || state_ns==RD_ACT|| (state_cs==OP_WR && state_ns==IDLE4) || state_ns==IDLE3)
		counter<=counter+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter_act<=0;
	else if(state_ns==IDLE)
		counter_act<=0;
	else if((state_cs==IDLE5 || state_cs==SEL_ACT)&& state_ns==SEL_ACT)
		counter_act<=counter_act+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter_OP_RD<=0;
	else if(state_cs==OP_WR)
		counter_OP_RD<=0;
	else if(state_cs==OP)
		counter_OP_RD<=counter_OP_RD+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter_OP_WR<=0;
	else if(state_cs==IDLE4)
		counter_OP_WR<=0;
	else if(state_ns==OP_WR)
		counter_OP_WR<=counter_OP_WR+1;
end

always@(*)begin
	if(curr_act==6)
		OP_WR_cycle = 4;
	else
		OP_WR_cycle = 1;
end

always@(*)begin
	if(curr_act==0)
		OP_RD_cycle = 5;
	else if(curr_act==1)
		OP_RD_cycle = 4;
	else if(curr_act==6)
		OP_RD_cycle = 1;
	else if(curr_act==7)
		OP_RD_cycle = 1;
	else 
		OP_RD_cycle = 0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		ACT_num<=0;
	else if(state_ns==IDLE)
		ACT_num<=0;
	else if(state_ns==RD_ACT)
		ACT_num<=ACT_num+1;
end

// logic
always@(*)begin
	if(act_reg[counter_act]==2 || act_reg[counter_act]==3 || act_reg[counter_act]==4 || act_reg[counter_act]==5)
		mode_sel=1;
	else
		mode_sel=0;
end

always@(*)begin
	if(state_cs==SEL_ACT)begin
		if(curr_act==1 && img_size_reg==4)
			passSIT=1;
		else if(curr_act==6 && img_size_reg==16)
			passSIT=1;
			/*
		else if(curr_act==7 && img_size_reg==4)
			passSIT=1;
			*/
		else
			passSIT=0;
	end
	else 
		passSIT=0;
end

// save reg
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		img_size_reg<=0;
	else if(state_ns==IDLE)
		img_size_reg<=0;
	else if(state_ns==RD && counter==0)
		img_size_reg<=img_size;
	else if(state_cs==OP_WR && state_ns==IDLE5)begin
		if(curr_act==1 || (curr_act==7)&&img_size_reg!=4)
			img_size_reg<=img_size_reg>>1;
	end
	else if((state_cs==SEL_ACT&&state_ns==IDLE4) && curr_act==6)
		img_size_reg<=img_size_reg<<1;
end

reg [3:0]temp_num;

always@(*)begin
	case(counter)
		0:temp_num=1;
		1:temp_num=2;
		2:temp_num=3;
		3:temp_num=4;
		4:temp_num=0;
		5:temp_num=5;
		6:temp_num=6;
		7:temp_num=7;
		8:temp_num=8;
		default:temp_num=0;
	endcase
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<9;i=i+1)
			template_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<9;i=i+1)
			template_reg[i]<=0;
	else if(state_ns==RD && counter<=8)
		template_reg[temp_num]<=template;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<16;i=i+1)
			act_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<16;i=i+1)
			act_reg[i]<=0;
	else if(state_ns==RD_ACT)
		act_reg[counter]<=action;
end

reg isUP,isDown,isLeft,isRight;
reg signed[39:0]choose_val;
reg signed[39:0]choose_val2;
always@(*)begin
	case(counter_OP_RD)
		1:choose_val= template_reg[0];
		2:choose_val= (isUP || isLeft)?0:template_reg[1];
		3:choose_val= (isUP )?0:template_reg[2];
		4:choose_val= (isUP || isRight)?0:template_reg[3];
		5:choose_val= (isLeft)?0:template_reg[4];
		default:choose_val = 0;
	endcase
end

always@(*)begin
	case(counter_OP_RD)
		1:choose_val2= 0;
		2:choose_val2= (isRight)?0:template_reg[5];
		3:choose_val2= (isDown || isLeft)?0:template_reg[6];
		4:choose_val2= (isDown)?0:template_reg[7];
		5:choose_val2= (isDown || isRight)?0:template_reg[8];
		default:choose_val2 = 0;
	endcase
end

always@(*)begin
	if(img_size_reg==4 && counter[3:2]==0)
		isUP = 1;
	else if(img_size_reg==8 && counter[5:3]==0)
		isUP = 1;
	else if(img_size_reg==16 && counter[7:4]==0)
		isUP = 1;
	else
		isUP = 0;
end

always@(*)begin
	if(img_size_reg==4 && counter[3:2]==2'b11)
		isDown = 1;
	else if(img_size_reg==8 && counter[5:3]==3'b111)
		isDown = 1;
	else if(img_size_reg==16 && counter[7:4]==4'b1111)
		isDown = 1;
	else
		isDown = 0;
end

always@(*)begin
	if(img_size_reg==4 && counter[1:0]==0)
		isLeft = 1;
	else if(img_size_reg==8 && counter[2:0]==0)
		isLeft = 1;
	else if(img_size_reg==16 && counter[3:0]==0)
		isLeft = 1;
	else
		isLeft = 0;
end

always@(*)begin
	if(img_size_reg==4 && counter[1:0]==2'b11)
		isRight = 1;
	else if(img_size_reg==8 && counter[2:0]==3'b111)
		isRight = 1;
	else if(img_size_reg==16 && counter[3:0]==4'b1111)
		isRight = 1;
	else
		isRight = 0;
end

reg signed[39:0] choose_val4;
reg signed[5:0] choose_val3;

always@(*)begin
	if(counter_OP_WR==1)
		choose_val4 = tmp_read_reg2;
	else
		choose_val4 = tmp_read_reg2<<1;
end

always@(*)begin
	if(counter_OP_WR==1)
		choose_val3 = 0;
	else
		choose_val3 = 20;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		tmp_read_reg1<=0;
	else if(state_cs==OP && curr_act==0)begin
		if(counter_OP_RD==0)
			tmp_read_reg1<=0;
		else if(counter_OP_RD<=9)
			tmp_read_reg1<=mult(tmp_read_reg1,Q_mem_out2,Q_mem_out,choose_val,choose_val2);
	end
	else if(state_cs==OP && curr_act==1)begin
		if(counter_OP_RD==1)
			tmp_read_reg1<=Q_mem_out;
		else if((counter_OP_RD==2 || counter_OP_RD==3 || counter_OP_RD==4) && tmp_read_reg1<Q_mem_out)
			tmp_read_reg1<=Q_mem_out;
	end
	else if(state_cs==OP && curr_act==7)begin
		if(counter_OP_RD==1)
			tmp_read_reg1<={Q_mem_out[39],Q_mem_out[39:1]}+50;
	end
	else if(state_ns==OP_WR && curr_act==6)begin
		if(counter_OP_WR==1 || counter_OP_WR==2)begin
			tmp_read_reg1<=choose_val4/3+choose_val3;
		end
		else if(counter_OP_WR==3)
			tmp_read_reg1<={tmp_read_reg2[39],tmp_read_reg2[39:1]};
		else if(counter_OP_WR==0)
			tmp_read_reg1<=Q_mem_out;
	/*
		case(counter_OP_WR)
			0:tmp_read_reg1<=Q_mem_out;
			1:tmp_read_reg1<=choose_val4/3;
			2:tmp_read_reg1<=(choose_val4)/3+20;
			3:tmp_read_reg1<={tmp_read_reg2[39],tmp_read_reg2[39:1]};
		endcase
		*/
	end
	else if(state_cs==RD_REG1)
		tmp_read_reg1<=Q_mem_out;
end



function signed[39:0]mult; //not really reusing why
input signed[39:0] old_reg,Q_mem_out2,Q_mem_out;
input signed[15:0]template_reg,template_reg2;
begin
	mult = old_reg+Q_mem_out2*template_reg+Q_mem_out*template_reg2;
end endfunction

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		tmp_read_reg2<=0;
	else if(state_cs==RD_REG2)
		tmp_read_reg2<=Q_mem_out;
	
	else if(state_cs==OP && curr_act==0)begin
		if(counter_OP_RD==1)
			tmp_read_reg2<=Q_mem_out;
	end
	else if(state_cs==OP && curr_act==6)begin
		if(counter_OP_RD==1)
			tmp_read_reg2<=Q_mem_out;
	end
end
///

always@(*)begin
	if(curr_act==2 || curr_act==3)
		doneSwitch = counter==(img_size_reg*img_size_reg/2-1);
	else if( curr_act==5)
		doneSwitch = counter==((img_size_reg*(img_size_reg-1))/2);
	else if(curr_act==4)
		doneSwitch = counter==((img_size_reg*(img_size_reg-1))/2-1);
	else
		doneSwitch=0;
end

always@(*)begin
	if(curr_act==0)
		doneOP = counter==img_size_reg*img_size_reg-1;
	else if(curr_act==7 && img_size_reg==4)
		doneOP = counter==15;
	else if(curr_act==1 || curr_act==7)
		doneOP = counter==((img_size_reg>>1)*(img_size_reg>>1)-1);
	else if(curr_act==6)
		doneOP = (counter==((img_size_reg>>1)*(img_size_reg>>1)-1) && counter_OP_WR==OP_WR_cycle);
	else
		doneOP = 0;
end

reg doneCol;
reg doneRow;
reg addr_equ;
always@(*)begin
	if(img_size_reg==4 && (&addr_y[1:0]))
		doneCol = 1;
	else if(img_size_reg==8 && (&addr_y[2:0]))
		doneCol = 1;
	else if(img_size_reg==16 && (&addr_y))
		doneCol = 1;
	else
		doneCol = 0;
end

always@(*)begin
	if(img_size_reg==4 && (&addr_x[1:0]))
		doneRow = 1;
	else if(img_size_reg==8 && (&addr_x[2:0]))
		doneRow = 1;
	else if(img_size_reg==16 && (&addr_x))
		doneRow = 1;
	else
		doneRow = 0;
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		addr_equ<=0;
	else if(state_cs==RD_REG1)begin
		//addr_equ<=addr2counter==addr2counter2;
		if(curr_act==4)begin
			if(img_size_reg==4)
				addr_equ<= (addr_x[1:0]+1)==addr_x2[1:0];
			else if(img_size_reg==8)
				addr_equ<= (addr_x[2:0]+1)==addr_x2[2:0];
			else if(img_size_reg==16)
				addr_equ<= (addr_x[3:0]+1)==addr_x2[3:0];
		end

	end
		
end


//counter1
always@(*)begin
	if(img_size_reg==4)
		addr2counter={4'b0000,addr_y[1:0],addr_x[1:0]};
	else if(img_size_reg==8)
		addr2counter={2'b00,addr_y[2:0],addr_x[2:0]};
	else if(img_size_reg==16)
		addr2counter={addr_y[3:0],addr_x[3:0]};
	else
		addr2counter=0;
end
//X_addr1
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		addr_x<=0;
	else if(state_ns==IDLE || state_ns==IDLE5)
		addr_x<=0;
	else if(curr_act==0)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==4)
				addr_x<=counter[1:0];
			else if(img_size_reg==8)
				addr_x<=counter[2:0];
			else if(img_size_reg==16)
				addr_x<=counter[3:0];
		end
			
		else if(state_ns==OP)
			case(counter_OP_RD)
				0:addr_x<=addr_x+1;
				1:addr_x<=addr_x-2;
				2:addr_x<=addr_x+1;
				3:addr_x<=addr_x+1;
				//4:addr_x<=addr_x+2;
				//5:addr_x<=addr_x-2;
				//6:addr_x<=addr_x+1;
				//7:addr_x<=addr_x+1;
			endcase
	end
	else if(curr_act==1)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==8)
				addr_x<=counter[2:0]<<1;
			else if(img_size_reg==16)
				addr_x<=counter[3:0]<<1;
		end
		else if(state_ns==OP)begin
			case(counter_OP_RD)
				0:addr_x<=addr_x+1;
				1:addr_x<=addr_x-1;
				2:addr_x<=addr_x+1;
			endcase
		end
	end
	else if(curr_act==2)begin
		if(doneCol && state_ns==WR_REG2)
			addr_x<=addr_x+1;
	end
	else if(curr_act==3)begin
		if(state_ns==WR_REG2 && (doneRow))
			addr_x<=0;
		else if(state_ns==WR_REG2)
			addr_x<=addr_x+1;
	end
	else if(curr_act==4)begin
		if(addr_equ && state_ns==WR_REG2)
			addr_x<=0;
		else if(state_ns==WR_REG2)
			addr_x<=addr_x+1;
	end
	else if(curr_act==5)begin
		if(doneRow && state_ns==WR_REG2)
			addr_x<=addr_y+2;
		else if(state_ns==WR_REG2)
			addr_x<=addr_x+1;
	end
	else if(curr_act==6)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==8)
				addr_x<=(~counter[1:0])<<1;
			else if(img_size_reg==16)
				addr_x<=(~counter[2:0])<<1;
		end
		else if(state_ns==OP_WR)begin
			case(counter_OP_WR)
				1:addr_x<=addr_x+1;
				2:addr_x<=addr_x-1;
				3:addr_x<=addr_x+1;
			endcase
		end
		
	end
	else if(curr_act==7)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==4)
				addr_x<=counter[1:0];
			else if(img_size_reg==8)
				addr_x<={1'b0,counter[1:0]}+3'b010;
			else if(img_size_reg==16)
				addr_x<={1'b0,counter[2:0]}+4'b0100;
		end
	end
end
//Y_addr1
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		addr_y<=0;
	else if(state_ns==IDLE || state_ns==IDLE5)
		addr_y<=0;
	else if(curr_act==0)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==4)
				addr_y<=counter[3:2];
			else if(img_size_reg==8)
				addr_y<=counter[5:3];
			else if(img_size_reg==16)
				addr_y<=counter[7:4];
		end
		else if(state_ns==OP)
			case(counter_OP_RD)
				0:addr_y<=addr_y;
				1:addr_y<=addr_y+1;
				2:addr_y<=addr_y;
				3:addr_y<=addr_y;
				//4:addr_y<=addr_y;
				//5:addr_y<=addr_y+1;
				//6:addr_y<=addr_y;
				//7:addr_y<=addr_y;
			endcase
	end
	else if(curr_act==1)begin
		if(state_cs!=OP && state_ns==OP)begin
			if(img_size_reg==8)
				addr_y<=counter[3:2]<<1;
			else if(img_size_reg==16)
				addr_y<=counter[5:3]<<1;
		end
		else if(state_ns==OP)begin
			case(counter_OP_RD)
				0:addr_y<=addr_y;
				1:addr_y<=addr_y+1;
				2:addr_y<=addr_y;
			endcase
		end
	end
	else if(curr_act==2)begin
		if(state_ns==WR_REG2 && (doneCol))
			addr_y<=0;
		else if(state_ns==WR_REG2)
			addr_y<=addr_y+1;
	end
	else if(curr_act==3)begin
		if(doneRow && state_ns==WR_REG2)
			addr_y<=addr_y+1;
	end
	else if(curr_act==4)begin
		if(addr_equ && state_ns==WR_REG2)
			addr_y<=addr_y+1;
	end
	else if(curr_act==5)begin
		if(doneRow && state_ns==WR_REG2)
			addr_y<=addr_y+1;
	end
	else if(curr_act==6)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==8)
				addr_y<=(~counter[3:2])<<1;
			else if(img_size_reg==16)
				addr_y<=(~counter[5:3])<<1;
		end
		else if(state_ns==OP_WR)begin
			case(counter_OP_WR)
				1:addr_y<=addr_y;
				2:addr_y<=addr_y+1;
				3:addr_y<=addr_y;
			endcase
		end
	end
	else if(curr_act==7)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==4)
				addr_y<=counter[3:2];
			else if(img_size_reg==8)
				addr_y<={1'b0,counter[3:2]}+3'b010;
			else if(img_size_reg==16)
				addr_y<={1'b0,counter[5:3]}+4'b0100;
		end
	end
end

//counter2
always@(*)begin
	if(img_size_reg==4)
		addr2counter2={4'b0000,addr_y2[1:0],addr_x2[1:0]};
	else if(img_size_reg==8)
		addr2counter2={2'b00,addr_y2[2:0],addr_x2[2:0]};
	else if(img_size_reg==16)
		addr2counter2={addr_y2[3:0],addr_x2[3:0]};
	else
		addr2counter2=0;
end
//X_addr2
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		addr_x2<=0;
	else if(state_ns==IDLE || state_ns==IDLE5)
		addr_x2<=0;
		
	else if(curr_act==0)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==4)
				addr_x2<=counter[1:0];
			else if(img_size_reg==8)
				addr_x2<=counter[2:0];
			else if(img_size_reg==16)
				addr_x2<=counter[3:0];
		end
			
		else if(state_ns==OP)
			case(counter_OP_RD)
				0:addr_x2<=addr_x2-1;
				1:addr_x2<=addr_x2+1;
				2:addr_x2<=addr_x2+1;
				3:addr_x2<=addr_x2-2;
			endcase
	end
		
	else if(curr_act==2)begin
		if(state_ns==RD_REG1)
			addr_x2<=~addr_x;
	end
	else if(curr_act==3)begin
		if(state_ns==WR_REG2 && (doneRow))
			addr_x2<=0;
		else if(state_ns==WR_REG2)
			addr_x2<=addr_x2+1;
	end
	else if(curr_act==4)begin
		if(state_ns==RD_REG1 && (state_cs==SEL_ACT))
			addr_x2<=~addr_x;
		else if(state_ns==RD_REG1 && addr_equ)
			addr_x2<=addr_x2-1;
	end
	else if(curr_act==5)begin
		if(doneRow && state_ns==WR_REG2)
			addr_x2<=addr_x2+1;
	end
	else if(curr_act==6)begin
	
	end
end
//Y_addr2
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		addr_y2<=0;
	else if(state_ns==IDLE ||state_ns==IDLE5)
		addr_y2<=0;
		
	else if((curr_act==0 || curr_act==1 || curr_act==6 || curr_act==7) && state_ns==SEL_ACT)
		addr_y2<=0;
	
	else if(curr_act==0)begin
		if(state_cs==IDLE4)begin
			if(img_size_reg==4)
				addr_y2<=counter[3:2];
			else if(img_size_reg==8)
				addr_y2<=counter[5:3];
			else if(img_size_reg==16)
				addr_y2<=counter[7:4];
		end
		else if(state_ns==OP)
			case(counter_OP_RD)
				0:addr_y2<=addr_y2-1;
				1:addr_y2<=addr_y2;
				2:addr_y2<=addr_y2;
				3:addr_y2<=addr_y2+1;
			endcase
	end
	
	else if(curr_act==2)begin
		if(state_ns==WR_REG2 && (doneCol))
			addr_y2<=0;
		else if(state_ns==WR_REG2)
			addr_y2<=addr_y2+1;
	end
	else if(curr_act==3)begin
		if(state_ns==RD_REG1)
			addr_y2<=~addr_y;
	end
	else if(curr_act==4)begin
		if(state_ns==RD_REG1)
			addr_y2<=~addr_x;
	end
	else if(curr_act==5)begin
		if(doneRow && state_ns==WR_REG2)
			addr_y2<=addr_x2+2;
		else if(state_ns==WR_REG2)
			addr_y2<=addr_y2+1;
	end
end
assign trans_img = image;
// sram
SRAM testmem(.Q(Q_mem_out),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen),.A(mem_address),.D(D_mem_in),.OEN(mem_oen));
always@(*)begin
	if(state_ns==RD)
		D_mem_in = trans_img;
	else if(state_cs==OP_WR)
		D_mem_in = tmp_read_reg1;
	else if(state_ns==WR_REG1)
		D_mem_in = tmp_read_reg1;
	else if(state_ns==WR_REG2)
		D_mem_in = tmp_read_reg2;
	else
		D_mem_in = 0;
end

wire [8:0] re_counter;
assign re_counter = ~counter;

always@(*)begin
	if(state_ns==RD || state_ns==DONE)
		mem_address = counter;
	else if(curr_act==6)begin
		if(state_cs==OP)begin
			if(img_size_reg==8)
				mem_address = re_counter[3:0];
			else if(img_size_reg==16)
				mem_address = re_counter[5:0];
			else 
				mem_address = 0;
		end
		else if(state_cs==OP_WR)
			mem_address = addr2counter;
		else 
			mem_address = 0;
	end
	else if(state_cs==OP_WR)
		mem_address = counter;
	else if(state_cs==OP || state_ns==RD_REG1 || state_ns==WR_REG2 )
		mem_address = addr2counter;
	else if(state_ns==RD_REG2 || state_ns==WR_REG1)
		mem_address = addr2counter2;
		/*
	else if(state_ns==RD_REG1 || state_ns==WR_REG2 )
		mem_address = addr2counter;
		*/
	else
		mem_address = 0;
end

always@(*)begin
	if(state_ns==RD)
		mem_wen = 0;
	else if(state_ns==WR_REG1 || state_ns==WR_REG2 || state_cs==OP_WR)
		mem_wen = 0;
	else
		mem_wen = 1;
end

SRAM2 testmem2(.Q(Q_mem_out2),.CLK(clk),.CEN(mem_cen2),.WEN(mem_wen2),.A(mem_address2),.D(D_mem_in2),.OEN(mem_oen2));
always@(*)begin
	if(state_ns==RD)
		D_mem_in2 = trans_img;
	else if(curr_act!=0)begin
		if(state_cs==OP_WR)
			D_mem_in2 = tmp_read_reg1;
		else if(state_ns==WR_REG1)
			D_mem_in2 = tmp_read_reg1;
		else if(state_ns==WR_REG2)
			D_mem_in2 = tmp_read_reg2;
		else
			D_mem_in2 = 0;
	end
	else
		D_mem_in2 = 0;
end

always@(*)begin
	if(state_ns==RD || state_ns==DONE)
		mem_address2 = counter;
	else if(curr_act==6)begin
		if(state_cs==OP)begin
			if(img_size_reg==8)
				mem_address2 = re_counter[3:0];
			else if(img_size_reg==16)
				mem_address2 = re_counter[5:0];
			else 
				mem_address2 = 0;
		end
		else if(state_cs==OP_WR)
			mem_address2 = addr2counter;
		else 
			mem_address2 = 0;
	end
	else if(curr_act==0 && state_cs==OP)begin
		mem_address2 = addr2counter2;
	end
	else if(state_cs==OP_WR)
		mem_address2 = counter;
	else if(state_ns==RD_REG1 || state_ns==WR_REG2 || state_cs==OP)
		mem_address2 = addr2counter;
	else if(state_ns==RD_REG2 || state_ns==WR_REG1)
		mem_address2 = addr2counter2;
		/*
	else if(state_ns==RD_REG1 || state_ns==WR_REG2 )
		mem_address2 = addr2counter;
		*/
	else
		mem_address2 = 0;
end

always@(*)begin
	if(state_ns==RD)
		mem_wen2 = 0;
	else if((state_ns==WR_REG1 || state_ns==WR_REG2 || state_cs==OP_WR) && curr_act!=0)
		mem_wen2 = 0;
	else
		mem_wen2 = 1;
end


reg signed [39:0]max_value;
reg [3:0]out_x_reg;
reg [3:0]out_y_reg;

reg isUp2,isDown2,isLeft2,isRight2;
reg [7:0]pos_reg[0:8];
reg [3:0]pos_counter;
reg [3:0]pos_num;
reg [7:0]addr2counter3;

always@(*)begin
	if(out_x_reg==0)
		isLeft2 = 1;
	else 
		isLeft2 = 0;
end

always@(*)begin
	if(out_x_reg==img_size_reg-1)
		isRight2 = 1;
	else 
		isRight2 = 0;
end

always@(*)begin
	if(out_y_reg==0)
		isUp2 = 1;
	else 
		isUp2 = 0;
end

always@(*)begin
	if(out_y_reg==img_size_reg-1)
		isDown2 = 1;
	else 
		isDown2 = 0;
end

always@(*)begin
	if((isUp2 && isLeft2) || (isUp2 && isRight2) || (isDown2 && isLeft2) || (isDown2 && isRight2))
		pos_num = 6;
	else if(isUp2 || isDown2 || isLeft2 || isRight2)
		pos_num = 8;
	else 
		pos_num = 11;
end

always@(*)begin
	if(img_size_reg==4)
		addr2counter3 = {4'b0000,out_y_reg[1:0],out_x_reg[1:0]};
	else if(img_size_reg==8)
		addr2counter3 = {2'b00,out_y_reg[2:0],out_x_reg[2:0]};
	else if(img_size_reg==16)
		addr2counter3 = {out_y_reg[3:0],out_x_reg[3:0]};
	else
		addr2counter3 = 0;
end

always@(*)begin
	if(isUp2 && isLeft2)begin
		pos_reg[0] = addr2counter3;
		pos_reg[1] = addr2counter3+1;
		pos_reg[2] = addr2counter3+img_size_reg;
		pos_reg[3] = addr2counter3+img_size_reg+1;
		pos_reg[4] = 0;
		pos_reg[5] = 0;
		pos_reg[6] = 0;
		pos_reg[7] = 0;
		pos_reg[8] = 0;
	end
	else if(isUp2 && isRight2)begin
		pos_reg[0] = addr2counter3-1;
		pos_reg[1] = addr2counter3;
		pos_reg[2] = addr2counter3+img_size_reg-1;
		pos_reg[3] = addr2counter3+img_size_reg;
		pos_reg[4] = 0;
		pos_reg[5] = 0;
		pos_reg[6] = 0;
		pos_reg[7] = 0;
		pos_reg[8] = 0;
	end
	else if(isDown2 && isLeft2)begin
		pos_reg[0] = addr2counter3-img_size_reg;
		pos_reg[1] = addr2counter3-img_size_reg+1;
		pos_reg[2] = addr2counter3;
		pos_reg[3] = addr2counter3+1;
		pos_reg[4] = 0;
		pos_reg[5] = 0;
		pos_reg[6] = 0;
		pos_reg[7] = 0;
		pos_reg[8] = 0;
	end
	else if(isDown2 && isRight2)begin
		pos_reg[0] = addr2counter3-img_size_reg-1;
		pos_reg[1] = addr2counter3-img_size_reg;
		pos_reg[2] = addr2counter3-1;
		pos_reg[3] = addr2counter3;
		pos_reg[4] = 0;
		pos_reg[5] = 0;
		pos_reg[6] = 0;
		pos_reg[7] = 0;
		pos_reg[8] = 0;
	end
	else if(isUp2)begin
		pos_reg[0] = addr2counter3-1;
		pos_reg[1] = addr2counter3;
		pos_reg[2] = addr2counter3+1;
		pos_reg[3] = addr2counter3+img_size_reg-1;
		pos_reg[4] = addr2counter3+img_size_reg;
		pos_reg[5] = addr2counter3+img_size_reg+1;
		pos_reg[6] = 0;
		pos_reg[7] = 0;
		pos_reg[8] = 0;
	end
	else if(isDown2)begin
		pos_reg[0] = addr2counter3-img_size_reg-1;
		pos_reg[1] = addr2counter3-img_size_reg;
		pos_reg[2] = addr2counter3-img_size_reg+1;
		pos_reg[3] = addr2counter3-1;
		pos_reg[4] = addr2counter3;
		pos_reg[5] = addr2counter3+1;
		pos_reg[6] = 0;
		pos_reg[7] = 0;
		pos_reg[8] = 0;
	end
	else if(isLeft2)begin
		pos_reg[0] = addr2counter3-img_size_reg;
		pos_reg[1] = addr2counter3-img_size_reg+1;
		pos_reg[2] = addr2counter3;
		pos_reg[3] = addr2counter3+1;
		pos_reg[4] = addr2counter3+img_size_reg;
		pos_reg[5] = addr2counter3+img_size_reg+1;
		pos_reg[6] = 0;
		pos_reg[7] = 0;
		pos_reg[8] = 0;
	end
	else if(isRight2)begin
		pos_reg[0] = addr2counter3-img_size_reg-1;
		pos_reg[1] = addr2counter3-img_size_reg;
		pos_reg[2] = addr2counter3-1;
		pos_reg[3] = addr2counter3;
		pos_reg[4] = addr2counter3+img_size_reg-1;
		pos_reg[5] = addr2counter3+img_size_reg;
		pos_reg[6] = 0;
		pos_reg[7] = 0;
		pos_reg[8] = 0;
	end
	else begin
		pos_reg[0] = addr2counter3-img_size_reg-1;
		pos_reg[1] = addr2counter3-img_size_reg;
		pos_reg[2] = addr2counter3-img_size_reg+1;
		pos_reg[3] = addr2counter3-1;
		pos_reg[4] = addr2counter3;
		pos_reg[5] = addr2counter3+1;
		pos_reg[6] = addr2counter3+img_size_reg-1;
		pos_reg[7] = addr2counter3+img_size_reg;
		pos_reg[8] = addr2counter3+img_size_reg+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_x_reg<=0;
	else if(state_cs==OP_WR && curr_act==0)begin
		if(D_mem_in>max_value)begin
			if(img_size_reg==4)
				out_x_reg<=counter[1:0];
			else if(img_size_reg==8)
				out_x_reg<=counter[2:0];
			else if(img_size_reg==16)
				out_x_reg<=counter[3:0];
		end
	end		
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_y_reg<=0;
	else if(state_cs==OP_WR && curr_act==0)begin
		if(D_mem_in>max_value)begin
			if(img_size_reg==4)
				out_y_reg<=counter[3:2];
			else if(img_size_reg==8)
				out_y_reg<=counter[5:3];
			else if(img_size_reg==16)
				out_y_reg<=counter[7:4];
		end
	end		
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		max_value<=40'b1000000000000000000000000000000000000000;
	else if(state_ns==IDLE)
		max_value<=40'b1000000000000000000000000000000000000000;
	else if(state_cs==OP_WR && curr_act==0)
		if(D_mem_in>max_value)
			max_value<=D_mem_in;
end
//output
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_valid<=0;
	else if(state_ns==IDLE)
		out_valid<=0;
	else if(state_ns==DONE && counter>1)
		out_valid<=1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_x<=0;
	else if(state_ns==IDLE)
		out_x<=0;
	else if(state_ns==DONE &&  counter>1)
		out_x<=out_y_reg;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_y<=0;
	else if(state_ns==IDLE)
		out_y<=0;
	else if(state_ns==DONE &&  counter>1)
		out_y<=out_x_reg;
	
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_img_pos<=0;
	else if(state_ns==IDLE)
		out_img_pos<=0;
	else if(state_ns==DONE && counter>1)begin
		if(counter>=pos_num)
			out_img_pos<=0;
		else 
			out_img_pos<=pos_reg[counter-2];
	end
end

reg signed[39:0] output_save_reg;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		output_save_reg<=0;
	else if(state_ns==DONE)
		output_save_reg<=Q_mem_out;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_value<=0;
	else if(state_ns==IDLE)
		out_value<=0;
	else if(state_ns == DONE && counter>1)
		out_value<=output_save_reg;
end

endmodule
