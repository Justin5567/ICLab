module IDC(
	// Input signals
	clk,
	rst_n,
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
wire done_OP;
wire move_op;
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
assign curr_op = op_reg[round_counter];
assign move_op = (curr_op == 5 || curr_op == 6 || curr_op == 7 || curr_op == 8 || curr_op == 2 || curr_op == 3);
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
// control signals
always@(*)begin
	if(curr_op==4)
		done_round = counter==0;
	else
		done_round = counter==2;
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


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<64;i=i+1)
			img_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<64;i=i+1)
			img_reg[i]<=0;
	else if(state_ns==RD)
		img_reg[counter]<=in_data;
	else if(state_cs==RD && state_ns==IDLE2)begin
	
	end
	else if(state_ns==IDLE2 && curr_op==2)begin
		img_reg[window_idx0]<=img_reg[window_idx1];
		img_reg[window_idx1]<=img_reg[window_idx3];
		img_reg[window_idx2]<=img_reg[window_idx0];
		img_reg[window_idx3]<=img_reg[window_idx2];
	end
	else if(state_ns==IDLE2 && curr_op==3)begin
		img_reg[window_idx0]<=img_reg[window_idx2];
		img_reg[window_idx1]<=img_reg[window_idx0];
		img_reg[window_idx2]<=img_reg[window_idx3];
		img_reg[window_idx3]<=img_reg[window_idx1];
	end
	else if(state_cs==WR && (curr_op==4||curr_op==0 || curr_op==1))begin
		img_reg[window_idx0]<=window_reg[0];
		img_reg[window_idx1]<=window_reg[1];
		img_reg[window_idx2]<=window_reg[2];
		img_reg[window_idx3]<=window_reg[3];
	end

end

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

always@(posedge clk or negedge rst_n)begin
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


endmodule 



/*
case(curr_position)
			0:begin
				zoom[0] <= img_reg[9];
				zoom[1] <= img_reg[10];
				zoom[2] <= img_reg[11];
				zoom[3] <= img_reg[12];
				zoom[4] <= img_reg[17];
				zoom[5] <= img_reg[18];
				zoom[6] <= img_reg[19];
				zoom[7] <= img_reg[20];
				zoom[8] <= img_reg[25];
				zoom[9] <= img_reg[26];
				zoom[10] <= img_reg[27];
				zoom[11] <= img_reg[28];
				zoom[12] <= img_reg[33];
				zoom[13] <= img_reg[34];
				zoom[14] <= img_reg[35];
				zoom[15] <= img_reg[36];
			end
			1:begin
				zoom[0] <= img_reg[10];
				zoom[1] <= img_reg[11];
				zoom[2] <= img_reg[12];
				zoom[3] <= img_reg[13];
				zoom[4] <= img_reg[18];
				zoom[5] <= img_reg[19];
				zoom[6] <= img_reg[20];
				zoom[7] <= img_reg[21];
				zoom[8] <= img_reg[26];
				zoom[9] <= img_reg[27];
				zoom[10] <= img_reg[28];
				zoom[11] <= img_reg[29];
				zoom[12] <= img_reg[34];
				zoom[13] <= img_reg[35];
				zoom[14] <= img_reg[36];
				zoom[15] <= img_reg[37];
			end
			2:begin
				zoom[0] <= img_reg[11];
				zoom[1] <= img_reg[12];
				zoom[2] <= img_reg[13];
				zoom[3] <= img_reg[14];
				zoom[4] <= img_reg[19];
				zoom[5] <= img_reg[20];
				zoom[6] <= img_reg[21];
				zoom[7] <= img_reg[22];
				zoom[8] <= img_reg[27];
				zoom[9] <= img_reg[28];
				zoom[10] <= img_reg[29];
				zoom[11] <= img_reg[30];
				zoom[12] <= img_reg[35];
				zoom[13] <= img_reg[36];
				zoom[14] <= img_reg[37];
				zoom[15] <= img_reg[38];
			end
			3:	begin
				zoom[0] <= img_reg[12];
				zoom[1] <= img_reg[13];
				zoom[2] <= img_reg[14];
				zoom[3] <= img_reg[15];
				zoom[4] <= img_reg[20];
				zoom[5] <= img_reg[21];
				zoom[6] <= img_reg[22];
				zoom[7] <= img_reg[23];
				zoom[8] <= img_reg[28];
				zoom[9] <= img_reg[29];
				zoom[10] <= img_reg[30];
				zoom[11] <= img_reg[31];
				zoom[12] <= img_reg[36];
				zoom[13] <= img_reg[37];
				zoom[14] <= img_reg[38];
				zoom[15] <= img_reg[39];
			end
			8:begin
				zoom[0] <= img_reg[17];
				zoom[1] <= img_reg[18];
				zoom[2] <= img_reg[19];
				zoom[3] <= img_reg[20];
				zoom[4] <= img_reg[25];
				zoom[5] <= img_reg[26];
				zoom[6] <= img_reg[27];
				zoom[7] <= img_reg[28];
				zoom[8] <= img_reg[33];
				zoom[9] <= img_reg[34];
				zoom[10] <= img_reg[35];
				zoom[11] <= img_reg[36];
				zoom[12] <= img_reg[41];
				zoom[13] <= img_reg[42];
				zoom[14] <= img_reg[43];
				zoom[15] <= img_reg[44];
			end
			9:begin
				zoom[0] <= img_reg[18];
				zoom[1] <= img_reg[19];
				zoom[2] <= img_reg[20];
				zoom[3] <= img_reg[21];
				zoom[4] <= img_reg[26];
				zoom[5] <= img_reg[27];
				zoom[6] <= img_reg[28];
				zoom[7] <= img_reg[29];
				zoom[8] <= img_reg[34];
				zoom[9] <= img_reg[35];
				zoom[10] <= img_reg[36];
				zoom[11] <= img_reg[37];
				zoom[12] <= img_reg[42];
				zoom[13] <= img_reg[43];
				zoom[14] <= img_reg[44];
				zoom[15] <= img_reg[45];
			end
			10:begin
				zoom[0] <= img_reg[19];
				zoom[1] <= img_reg[20];
				zoom[2] <= img_reg[21];
				zoom[3] <= img_reg[22];
				zoom[4] <= img_reg[27];
				zoom[5] <= img_reg[28];
				zoom[6] <= img_reg[29];
				zoom[7] <= img_reg[30];
				zoom[8] <= img_reg[35];
				zoom[9] <= img_reg[36];
				zoom[10] <= img_reg[37];
				zoom[11] <= img_reg[38];
				zoom[12] <= img_reg[43];
				zoom[13] <= img_reg[44];
				zoom[14] <= img_reg[45];
				zoom[15] <= img_reg[46];
			end
			11:begin
				zoom[0] <= img_reg[20];
				zoom[1] <= img_reg[21];
				zoom[2] <= img_reg[22];
				zoom[3] <= img_reg[23];
				zoom[4] <= img_reg[28];
				zoom[5] <= img_reg[29];
				zoom[6] <= img_reg[30];
				zoom[7] <= img_reg[31];
				zoom[8] <= img_reg[36];
				zoom[9] <= img_reg[37];
				zoom[10] <= img_reg[38];
				zoom[11] <= img_reg[39];
				zoom[12] <= img_reg[44];
				zoom[13] <= img_reg[45];
				zoom[14] <= img_reg[46];
				zoom[15] <= img_reg[47];
			end
			16:begin
				zoom[0] <= img_reg[25];
				zoom[1] <= img_reg[26];
				zoom[2] <= img_reg[27];
				zoom[3] <= img_reg[28];
				zoom[4] <= img_reg[33];
				zoom[5] <= img_reg[34];
				zoom[6] <= img_reg[35];
				zoom[7] <= img_reg[36];
				zoom[8] <= img_reg[41];
				zoom[9] <= img_reg[42];
				zoom[10] <= img_reg[43];
				zoom[11] <= img_reg[44];
				zoom[12] <= img_reg[49];
				zoom[13] <= img_reg[50];
				zoom[14] <= img_reg[51];
				zoom[15] <= img_reg[52];
			end
			17:begin
				zoom[0] <= img_reg[26];
				zoom[1] <= img_reg[27];
				zoom[2] <= img_reg[28];
				zoom[3] <= img_reg[29];
				zoom[4] <= img_reg[34];
				zoom[5] <= img_reg[35];
				zoom[6] <= img_reg[36];
				zoom[7] <= img_reg[37];
				zoom[8] <= img_reg[42];
				zoom[9] <= img_reg[43];
				zoom[10] <= img_reg[44];
				zoom[11] <= img_reg[45];
				zoom[12] <= img_reg[50];
				zoom[13] <= img_reg[51];
				zoom[14] <= img_reg[52];
				zoom[15] <= img_reg[53];
			end
			18:begin
				zoom[0] <= img_reg[27];
				zoom[1] <= img_reg[28];
				zoom[2] <= img_reg[29];
				zoom[3] <= img_reg[30];
				zoom[4] <= img_reg[35];
				zoom[5] <= img_reg[36];
				zoom[6] <= img_reg[37];
				zoom[7] <= img_reg[38];
				zoom[8] <= img_reg[43];
				zoom[9] <= img_reg[44];
				zoom[10] <= img_reg[45];
				zoom[11] <= img_reg[46];
				zoom[12] <= img_reg[51];
				zoom[13] <= img_reg[52];
				zoom[14] <= img_reg[53];
				zoom[15] <= img_reg[54];
			end
			19:begin
				zoom[0] <= img_reg[28];
				zoom[1] <= img_reg[29];
				zoom[2] <= img_reg[30];
				zoom[3] <= img_reg[31];
				zoom[4] <= img_reg[36];
				zoom[5] <= img_reg[37];
				zoom[6] <= img_reg[38];
				zoom[7] <= img_reg[39];
				zoom[8] <= img_reg[44];
				zoom[9] <= img_reg[45];
				zoom[10] <= img_reg[46];
				zoom[11] <= img_reg[47];
				zoom[12] <= img_reg[52];
				zoom[13] <= img_reg[53];
				zoom[14] <= img_reg[54];
				zoom[15] <= img_reg[55];
			end
			24:begin
				zoom[0] <= img_reg[33];
				zoom[1] <= img_reg[34];
				zoom[2] <= img_reg[35];
				zoom[3] <= img_reg[36];
				zoom[4] <= img_reg[41];
				zoom[5] <= img_reg[42];
				zoom[6] <= img_reg[43];
				zoom[7] <= img_reg[44];
				zoom[8] <= img_reg[49];
				zoom[9] <= img_reg[50];
				zoom[10] <= img_reg[51];
				zoom[11] <= img_reg[52];
				zoom[12] <= img_reg[57];
				zoom[13] <= img_reg[58];
				zoom[14] <= img_reg[59];
				zoom[15] <= img_reg[60];
			end
			25:begin
				zoom[0] <= img_reg[34];
				zoom[1] <= img_reg[35];
				zoom[2] <= img_reg[36];
				zoom[3] <= img_reg[37];
				zoom[4] <= img_reg[42];
				zoom[5] <= img_reg[43];
				zoom[6] <= img_reg[44];
				zoom[7] <= img_reg[45];
				zoom[8] <= img_reg[50];
				zoom[9] <= img_reg[51];
				zoom[10] <= img_reg[52];
				zoom[11] <= img_reg[53];
				zoom[12] <= img_reg[58];
				zoom[13] <= img_reg[59];
				zoom[14] <= img_reg[60];
				zoom[15] <= img_reg[61];
			end
			26:begin
				zoom[0] <= img_reg[35];
				zoom[1] <= img_reg[36];
				zoom[2] <= img_reg[37];
				zoom[3] <= img_reg[38];
				zoom[4] <= img_reg[43];
				zoom[5] <= img_reg[44];
				zoom[6] <= img_reg[45];
				zoom[7] <= img_reg[46];
				zoom[8] <= img_reg[51];
				zoom[9] <= img_reg[52];
				zoom[10] <= img_reg[53];
				zoom[11] <= img_reg[54];
				zoom[12] <= img_reg[59];
				zoom[13] <= img_reg[60];
				zoom[14] <= img_reg[61];
				zoom[15] <= img_reg[62];
			end
			27:begin
				zoom[0] <= img_reg[36];
				zoom[1] <= img_reg[37];
				zoom[2] <= img_reg[38];
				zoom[3] <= img_reg[39];
				zoom[4] <= img_reg[44];
				zoom[5] <= img_reg[45];
				zoom[6] <= img_reg[46];
				zoom[7] <= img_reg[47];
				zoom[8] <= img_reg[52];
				zoom[9] <= img_reg[53];
				zoom[10] <= img_reg[54];
				zoom[11] <= img_reg[55];
				zoom[12] <= img_reg[60];
				zoom[13] <= img_reg[61];
				zoom[14] <= img_reg[62];
				zoom[15] <= img_reg[63];
			end
		endcase

*/