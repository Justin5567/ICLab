`timescale 1ns/10ps
module ESCAPE(
    //Input Port
    clk,
    rst_n,
    in_valid1,
    in_valid2,
    in,
    in_data,
    //Output Port
    out_valid1,
    out_valid2,
    out,
    out_data
);

//==================INPUT OUTPUT==================//
input clk, rst_n, in_valid1, in_valid2;
input [1:0] in;
input [8:0] in_data;    
output reg	out_valid1, out_valid2;
output reg [2:0] out;
output reg [8:0] out_data;

//==================Parameter and Integer==================//
parameter IDLE = 4'd1;
parameter RD = 4'd2;
parameter IDLE2 = 4'd3;
parameter SETUP_TAR = 4'd4;
parameter CLEAN_MAP = 4'd5;
parameter WALK = 4'd6;
parameter COMPUTE = 4'd7;
parameter IDLE3 = 4'd8;
parameter DONE = 4'd9;
parameter WAIT_DATA = 4'd10;

integer i,x,y;
//==================Register and Wire==================//
reg [3:0]state_cs,state_ns;
reg [8:0]counter;
reg [4:0]counter_x, counter_y;
reg [2:0]target_counter;
reg [2:0]curr_tar_counter;
reg [1:0]map_reg[0:16][0:16];
reg [2:0]walk_reg[0:16][0:16];
reg [9:0]dest_reg[0:5];
reg [3:0]wallcount[0:16][0:16];
reg [2:0]dir;
reg [2:0]past_dir;
reg doneClean2;
reg signed [8:0]answer_reg[0:3];
reg signed [8:0]max_val,min_val;
wire doneRead;
wire doneRESCUE;
wire doneWALK;
wire doneARRIVE;
wire [2:0]output_cycle_count;
wire isUp, isDown, isLeft, isRight,isTrap,isHostage;
wire [9:0]curr_start,curr_end;
wire signed[9:0]tmp_sub;
//==================FSM==================//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else 
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE:state_ns = (in_valid1)?RD:IDLE;
		RD: state_ns = (doneRead)?IDLE2:RD;
		IDLE2: state_ns = SETUP_TAR;
		SETUP_TAR: state_ns = CLEAN_MAP;
		CLEAN_MAP: state_ns = (doneClean2)?WALK:CLEAN_MAP;
		WALK: state_ns = (doneARRIVE)?((doneRESCUE)?COMPUTE:WAIT_DATA):WALK;
		WAIT_DATA:state_ns = (in_valid2)?IDLE2:WAIT_DATA;
		COMPUTE: state_ns = (counter==14)?IDLE3:COMPUTE;
		IDLE3: state_ns = DONE;
		DONE:state_ns = (counter==output_cycle_count)?IDLE:DONE;
		default:state_ns = state_cs;
	endcase
end


//==============Design====================//

assign doneRead = (counter_x==16 && counter_y==16);
assign doneRESCUE = (curr_tar_counter==(target_counter));
assign doneARRIVE = (counter_y == curr_end[9:5] && counter_x == curr_end[4:0]);
assign output_cycle_count = (target_counter!=0)?target_counter:1;
assign isTrap = walk_reg[counter_y][counter_x]==2;
assign isUp = (counter_y==0);
assign isDown = (counter_y == 16);
assign isLeft = (counter_x ==0);
assign isRight = (counter_x==16);
assign isHostage = walk_reg[counter_y][counter_x]==3;
assign curr_start = dest_reg[curr_tar_counter];
assign curr_end = dest_reg[curr_tar_counter+1];
assign tmp_sub = (max_val+min_val)/2;

always@(*)begin
	doneClean2=1;
	for(y=0;y<17;y=y+1)
		for(x=0;x<17;x=x+1)
			begin
				if((walk_reg[y][x]==1 || walk_reg[y][x]==2) && (wallcount[y][x]==4'b1110||wallcount[y][x]==4'b1101||wallcount[y][x]==4'b1011||wallcount[y][x]==4'b0111))
					doneClean2=0;
			end					
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_cs==WALK && state_ns== COMPUTE)
		counter<=0;
	else if(state_ns==IDLE || state_ns==IDLE2 || state_ns==IDLE3)
		counter<=0;
	else if(state_ns==DONE)
		counter<=counter+1;
	else if(state_ns==RD)
		counter<=counter+1;
	else if(state_ns==CLEAN_MAP)
		counter<=counter+1;
	else if(state_cs==COMPUTE)
		counter<=counter+1;
		
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter_x<=0;
	else if(state_ns==IDLE || state_ns==IDLE2)
		counter_x<=0;
	else if(state_ns==RD)begin
		if(counter_x==16)
			counter_x<=0;
		else
			counter_x<=counter_x+1;
	end
	else if(state_cs==IDLE2)
		counter_x<=curr_start[4:0];
	else if(state_cs==WALK)begin
		if(dir==0)
			counter_x <= counter_x+1;
		else if(dir==2)
			counter_x <= counter_x-1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter_y<=0;
	else if(state_ns==IDLE || state_ns==IDLE2)
		counter_y<=0;
	else if(state_ns==RD)begin
		if(counter_x==16)
			counter_y<=counter_y+1;
	end
	else if(state_cs==IDLE2)
		counter_y<=curr_start[9:5];
	else if(state_cs==WALK)begin
		if(dir==1)
			counter_y <= counter_y+1;
		else if(dir==3)
			counter_y <= counter_y-1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		target_counter<=0;
	else if(state_cs==IDLE)
		target_counter<=0;
	else if(state_ns==RD && in==3)
		target_counter<=target_counter+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		curr_tar_counter<=0;
	else if(state_cs==IDLE)
		curr_tar_counter<=0;
	else if(state_cs==WAIT_DATA && state_ns==IDLE2)
		curr_tar_counter<=curr_tar_counter+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(y=0;y<17;y=y+1)
			for(x=0;x<17;x=x+1)
				map_reg[y][x]<=0;
	else if(in_valid1 && (state_cs==RD || state_ns==RD))begin
		map_reg[counter_y][counter_x]<=in;			
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(y=0;y<17;y=y+1)
			for(x=0;x<17;x=x+1)
				walk_reg[y][x]<=0;
	else if(state_cs==SETUP_TAR)
		for(y=0;y<17;y=y+1)begin
			for(x=0;x<17;x=x+1)begin
				if(y==curr_start[9:5] && x==curr_start[4:0])
					walk_reg[y][x]<=4;
				else if(y==curr_end[9:5] && x==curr_end[4:0])
					walk_reg[y][x]<=3;
				else if(map_reg[y][x]==3)
					walk_reg[y][x]<=0;
				else
					walk_reg[y][x]<=map_reg[y][x];
			end
		end
	else if(state_cs==CLEAN_MAP)
		for(y=0;y<17;y=y+1)begin
			for(x=0;x<17;x=x+1)begin
				//if((walk_reg[y][x]==1 || walk_reg[y][x]==2) && wallcount[y][x]==3)
				if((walk_reg[y][x]==1 || walk_reg[y][x]==2) && (wallcount[y][x]==4'b1110||wallcount[y][x]==4'b1101||wallcount[y][x]==4'b1011||wallcount[y][x]==4'b0111))
					walk_reg[y][x] <= 0;
			end
		end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<6;i=i+1)
			dest_reg[i]<=0;
	else if(state_cs==IDLE)
		for(i=0;i<6;i=i+1)
			dest_reg[i]<=0;
	else if(state_ns==RD)
		dest_reg[target_counter+1]<={counter_y,counter_x};
	else if(state_cs==RD && state_ns==IDLE2)begin
		dest_reg[0]<={5'b0,5'b0};
		dest_reg[target_counter+1]<={5'd16,5'd16};
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		max_val<=0;
	else if(state_cs==IDLE)
		max_val<=0;
	else if(state_cs==COMPUTE && target_counter>1)begin
		if(counter==7)
			max_val <= answer_reg[0];
		else if(counter==8 && answer_reg[1]>max_val)
			max_val	<= answer_reg[1];
		else if(counter==9 && answer_reg[2]>max_val && target_counter>2)
			max_val	<= answer_reg[2];
		else if(counter==10 && answer_reg[3]>max_val && target_counter>3)
			max_val	<= answer_reg[3];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		min_val<=0;
	else if(state_cs==IDLE)
		min_val<=0;
	else if(state_cs==COMPUTE && target_counter>1)begin
		if(counter==7)
			min_val <= answer_reg[0];
		else if(counter==8 && answer_reg[1]<min_val)
			min_val	<= answer_reg[1];
		else if(counter==9 && answer_reg[2]<min_val && target_counter>2)
			min_val	<= answer_reg[2];
		else if(counter==10 && answer_reg[3]<min_val && target_counter>3)
			min_val	<= answer_reg[3];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			answer_reg[i]<=9'b100000000;
	else if(state_cs==IDLE)
		for(i=0;i<4;i=i+1)
			answer_reg[i]<=9'b100000000;
	else if(state_cs==WAIT_DATA && state_ns==IDLE2 && in_valid2)begin
		answer_reg[curr_tar_counter]<=in_data;
	end
	else if(state_cs==COMPUTE)begin
		case(counter)
			0:begin
				if(answer_reg[0]<answer_reg[1])begin
					answer_reg[1]<=answer_reg[0];
					answer_reg[0]<=answer_reg[1];
				end
			end
			1:begin
				if(answer_reg[0]<answer_reg[2])begin
					answer_reg[2]<=answer_reg[0];
					answer_reg[0]<=answer_reg[2];
				end
			end
			2:begin
				if(answer_reg[0]<answer_reg[3])begin
					answer_reg[3]<=answer_reg[0];
					answer_reg[0]<=answer_reg[3];
				end
			end
			3:begin
				if(answer_reg[1]<answer_reg[2])begin
					answer_reg[1]<=answer_reg[2];
					answer_reg[2]<=answer_reg[1];
				end
			end
			4:begin
				if(answer_reg[1]<answer_reg[3])begin
					answer_reg[1]<=answer_reg[3];
					answer_reg[3]<=answer_reg[1];
				end
			end
			5:begin
				if(answer_reg[2]<answer_reg[3])begin
					answer_reg[2]<=answer_reg[3];
					answer_reg[3]<=answer_reg[2];
				end
			end
			6:begin // excess-3
				if(target_counter==0)
					answer_reg[0]<=0;
				else if(target_counter[0]==0)begin
					for(i=0;i<target_counter;i=i+1)begin
						if(answer_reg[i][8]==1)begin
							answer_reg[i]<=(-1)*((10*(answer_reg[i][7:4]-3))+answer_reg[i][3:0]-3); //***
						end
						else begin
							answer_reg[i]<=((10*(answer_reg[i][7:4]-3))+answer_reg[i][3:0]-3);
						end
					end
				end	
				else begin
					//answer_reg remain
				end
			end
			11:begin
				if(target_counter>1)begin
					for(i=0;i<target_counter;i=i+1)
						answer_reg[i]<=answer_reg[i]-tmp_sub;
				end
			end
			12:begin
				if(target_counter>2)begin
					answer_reg[1] <= ((answer_reg[0]<<<1)+answer_reg[1])/3;
				end
			end
			13:
			begin
				if(target_counter>2)begin
					answer_reg[2] <= ((answer_reg[1]<<<1)+answer_reg[2])/3;
				end
			end
			14:
			begin
				if(target_counter>2)begin
					answer_reg[3] <= ((answer_reg[2]<<<1)+answer_reg[3])/3;
				end
			end
			
		endcase
	end
end
/*
always@(*)begin
	for(y=0;y<17;y=y+1)begin
		for(x=0;x<17;x=x+1)begin
			wallcount[y][x] = 0;
			if(x==16 || walk_reg[y][x+1]==0)
				wallcount[y][x] = wallcount[y][x]+1;
			if(x==0 || walk_reg[y][x-1]==0)
				wallcount[y][x] = wallcount[y][x]+1;
			if(y==16 || walk_reg[y+1][x]==0)
				wallcount[y][x] = wallcount[y][x]+1;
			if(y==0 || walk_reg[y-1][x]==0)
				wallcount[y][x] = wallcount[y][x]+1;
		end
	end
end
*/

always@(*)begin
	for(y=0;y<17;y=y+1)begin
		for(x=0;x<17;x=x+1)begin
			if(x==16 || walk_reg[y][x+1]==0)
				wallcount[y][x][0] =1;
			else
				wallcount[y][x][0] =0;
			if(x==0 || walk_reg[y][x-1]==0)
				wallcount[y][x][1] =1;
			else
				wallcount[y][x][1] =0;
			if(y==16 || walk_reg[y+1][x]==0)
				wallcount[y][x][2] =1;
			else
				wallcount[y][x][2] =0;
			if(y==0 || walk_reg[y-1][x]==0)
				wallcount[y][x][3] =1;
			else
				wallcount[y][x][3] =0;
		end
	end
end

always@(*)begin
	if(isTrap && out!=4)
		dir = 4;
	else if(walk_reg[counter_y][counter_x+1] && !isRight && past_dir!=2)
		dir = 0;
	else if(walk_reg[counter_y+1][counter_x] && !isDown && past_dir!=3)
		dir = 1;
	else if(walk_reg[counter_y][counter_x-1] && !isLeft && past_dir!=0)
		dir = 2;
	else if(walk_reg[counter_y-1][counter_x] && !isUp && past_dir!=1)
		dir = 3;
	else
		dir = 5;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		past_dir<=0;
	else if(dir!=4)
		past_dir<=dir;
end
//==============OUTPUT SIGNAL====================//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_valid1<=0;
	else if(state_ns==IDLE)
		out_valid1<=0;
	else if(state_ns==DONE)
		out_valid1<=1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_valid2<=0;
	else if(state_ns==COMPUTE)
		out_valid2<=0;
	else if(state_cs==IDLE || state_cs==DONE || (state_cs==WALK && state_ns==WAIT_DATA))
		out_valid2<=0;
	else if(state_cs==WALK)
		out_valid2<=1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out<=0;
	else if(state_ns!=WALK)
		out<=0;
	else if(state_cs==WALK)
		out<=dir;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_data<=0;
	else if(state_ns!=DONE)
		out_data<=0;
	else if(state_ns==DONE)
		out_data<=answer_reg[counter];
end




endmodule



