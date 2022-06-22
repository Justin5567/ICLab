
`ifdef RTL
    `define CYCLE_TIME 15.0
`endif
`ifdef GATE
    `define CYCLE_TIME 15.0
`endif

module PATTERN(
    // Output signals
	clk,
    rst_n,
	in_valid1,
	in_valid2,
	in,
	in_data,
    // Input signals
    out_valid1,
	out_valid2,
    out,
	out_data
);

output reg clk, rst_n, in_valid1, in_valid2;
output reg [1:0] in;
output reg [8:0] in_data;
input out_valid1, out_valid2;
input [2:0] out;
input [8:0] out_data;

// ===============================================================
// Parameters & Integer Declaration
// ===============================================================
integer PATNUM = 500;
integer max_cycle;
parameter LEN = 289;

integer patcount;
integer i,j,x,y;
integer in_read,in_hold,out_read,out_hold;
integer a;
integer gap;
integer SEED = 122;
integer hostage_num;
//integer gen_signed,gen_partA,gen_partB;

integer curr_ans;
integer tmp_subtract;
integer out_valid1_cycle_count;
integer counter;

// ===============================================================
// Wire & Reg Declaration
// ===============================================================
reg [1:0] maze_reg [0:16][0:16];
reg [8:0] out_reg [0:16][0:16];
reg [9:0]answer_pos[0:16][0:16];
reg signed [8:0] answer_reg[0:3];
reg signed [8:0] tmp_reg;
integer max_val,min_val;
reg gen_signed;
reg [3:0]gen_partA,gen_partB;
reg [3:0]out_partA,out_partB;
reg [3:0] er_mode;
reg past_outvalid2;
reg [12:0]cycle;
reg term;
reg [9:0]curr_x,curr_y;
reg start_count_cycle;
reg past_in_valid1;
integer reset_done = 0;
// ===============================================================
// Clock
// ===============================================================
always	#(`CYCLE_TIME/2.0) clk = ~clk;
initial	clk = 0;

always@(*)begin
	if((in_valid1==1 && (out_valid1 || out_valid2)) ||　(in_valid2==1 && (out_valid1 || out_valid2)) || (out_valid1 && out_valid2))
		spec5_fail;
end

always@(negedge clk or negedge rst_n)begin
	if(!rst_n)
		past_outvalid2<=0;
	else 
		past_outvalid2<=out_valid2;

end

always@(negedge clk or negedge rst_n)begin
	if(!rst_n)
		past_in_valid1<=0;
	else 
		past_in_valid1<=in_valid1;
end

always@(negedge clk or negedge rst_n)begin
	if(!rst_n)
		start_count_cycle<=0;
	else if(out_valid1)
		start_count_cycle<=0;
	else if(past_in_valid1==1 && in_valid1==0)
		start_count_cycle<=1;
		
end

always@(negedge clk or negedge rst_n)begin
	if(!rst_n)
		cycle<=1;
	else if(past_in_valid1==1 && in_valid1==0)
		cycle<=cycle+1;
	else if(in_valid2)
		cycle<=cycle;
	else if(start_count_cycle)
		cycle<=cycle+1;
	else
		cycle<=1;
end

always@(*)begin
	if(cycle>3000 && start_count_cycle)begin
		spec6_fail;
		end
end

always@(*)begin
	if(out_data!=0 && out_valid2)
		spec7_fail;
end

// ===============================================================
// Initial
// ===============================================================
initial begin

	//+++++++++++++++++++++++++++++++++++++++++++++++++++
	// Read file here (two statements)
	in_read = $fopen("../00_TESTBED/input.txt", "r");
	//in_read = $fopen("input.txt", "r");
	//out_read = $fopen("../00_TESTBED/out.txt", "r");
	//+++++++++++++++++++++++++++++++++++++++++++++++++++
	rst_n = 1'b1;
	in_valid1 = 1'b0;
	in_valid2 = 1'b0;
	in = 'bx;
	in_data = 'bx;
	curr_x = 0;
	curr_y = 0;
	er_mode = 0;
	force clk = 0;
	reset_task;
	reset_done=1;
	//a = $fscanf(in_read, "%d", PATNUM);
	for(patcount=0; patcount<PATNUM; patcount=patcount+1)
	begin
		init_reg;
		input_task;
		generate_answer;
		move_task;
		check_answer;
	end
	YOU_PASS_task;
	$finish;
end
// ===============================================================
// TASK
// ===============================================================


task init_reg;begin
	for(y=0;y<17;y=y+1)begin
		for(x=0;x<17;x=x+1)begin
			maze_reg[y][x]=0;
			//answer_reg[y][x]=0;
		end
	end
	for(i=0;i<4;i=i+1)
		answer_reg[i]<=-256;
	curr_x = 0;
	curr_y = 0;
	counter=0;
	
	@(negedge clk);
end endtask

task input_task;
begin
	$display ("start Pattern No.%1d",patcount);
	gap = $urandom_range(2,4);
	repeat(gap) @(negedge clk);
	in_valid1 = 1'b1;
	hostage_num = 0;
	for(y=0;y<17;y=y+1)begin
		for(x=0;x<17;x=x+1)begin
			in_hold = $fscanf (in_read, "%d",maze_reg[y][x]);
			
		end
	end
	
	for(y=0;y<17;y=y+1)begin
		for(x=0;x<17;x=x+1)begin
			in = maze_reg[y][x];
			if(maze_reg[y][x]==3) begin
				hostage_num = hostage_num + 1;
			end
			@(negedge clk);
		end
	end
	in_valid1 = 1'b0;
	in = 2'bx;
	@(negedge clk);
	
end endtask

task generate_answer;begin
	curr_ans = 0;
	for(y=0;y<17;y=y+1)begin
		for(x=0;x<17;x=x+1)begin
			if(maze_reg[y][x]==3)begin
				if(hostage_num%2==0)begin
					gen_signed = $random(SEED);
					gen_partA = $random(SEED);
					gen_partB = $random(SEED);
					gen_signed = gen_signed %2;
					gen_partA = gen_partA % 10;
					gen_partB = gen_partB % 10;
					out_partA = gen_partA + 3;
					out_partB = gen_partB + 3;
					out_reg[y][x] = {gen_signed,out_partA,out_partB};
					//answer_reg[curr_ans] = (-1**gen_signed)*((10*gen_partA)+(1*gen_partB));
					answer_reg[curr_ans] = out_reg[y][x];
					/*
					$display("-----------------");
					$display("signed : %1d",gen_signed);
					$display("gen_partA : %3d",gen_partA);
					$display("gen_partB : %3d",gen_partB);
					$display("Out : %9b",out_reg[y][x]);
					$display("Ans : %3d",answer_reg[curr_ans]);
					$display("-----------------");
					*/
				end
				else begin
					gen_signed = $random(SEED);
					gen_partA = $random(SEED);
					gen_partB = $random(SEED);
					
					gen_signed = gen_signed %2;
					gen_partA = gen_partA % 17;
					gen_partB = gen_partB % 17;
					out_reg[y][x] = {gen_signed,gen_partA,gen_partB};
					answer_reg[curr_ans] = out_reg[y][x];
					/*
					answer_reg[curr_ans] = {gen_signed,gen_partA,gen_partB};
					$display("-----------------");
					$display("signed : %1d",gen_signed);
					$display("gen_partA : %3d",gen_partA);
					$display("gen_partB : %3d",gen_partB);
					$display("Out : %9b",out_reg[y][x]);
					$display("Ans : %3d",answer_reg[curr_ans]);
					$display("-----------------");
					*/
				end
				//$display ("Hostage %1d is at x=%2d, y=%2d,binary = %9b, value = %3d",curr_ans,x,y,answer_reg[curr_ans],answer_reg[curr_ans]);
				curr_ans = curr_ans+1;
			end
		end
	end
	//stage1
	// Sort from large to small
	for(i=0;i<curr_ans;i=i+1)begin
		for(j=i+1; j<curr_ans;j=j+1)begin
			if(answer_reg[i]<answer_reg[j])begin
				tmp_reg = answer_reg[i];
				answer_reg[i] = answer_reg[j];
				answer_reg[j] = tmp_reg;
			end
		end
	end
	//$display("Sort from large to small");
	for(i=0;i<curr_ans;i=i+1)begin
		//$display("Ans : %6d",answer_reg[i]);
	end
	// stage2
	// Excess-3
	if(hostage_num%2==0)begin
		for(i=0;i<hostage_num;i=i+1)begin
			answer_reg[i] = (-1**answer_reg[i][8])*((10*(answer_reg[i][7:4]-3))+(answer_reg[i][3:0]-3));
		end
	end
	//$display("after excess-3");
	for(i=0;i<curr_ans;i=i+1)begin
		//$display("Ans : %6d",answer_reg[i]);
	end
	// stage3
	// if hostage>1 subtract
	if(hostage_num>1)begin
		max_val = -256;
		min_val = 255;
		for(i=0;i<curr_ans;i=i+1)begin
			if(answer_reg[i]>max_val)
				max_val=answer_reg[i];
			if(answer_reg[i]<min_val)
				min_val=answer_reg[i];
		end
		tmp_subtract = (max_val+min_val)/2;
		//$display("tmp_subtract : %d",tmp_subtract);
		for(i=0;i<curr_ans;i=i+1)begin
			answer_reg[i] = answer_reg[i] - tmp_subtract;
		end
		//$display ("-----------Subtract--------------");
		for(i=0;i<curr_ans;i=i+1)begin
			//$display("Ans : %d",answer_reg[i]);
		end
	end
	// stage4
	// if hostage >2 Cumulation
	if(hostage_num>2)begin
		for(i=1;i<curr_ans;i=i+1)begin
			answer_reg[i] = (answer_reg[i-1]*2+answer_reg[i]*1)/3;
		end
		//$display ("------------Cumulation----------");
		for(i=0;i<curr_ans;i=i+1)begin
			//$display("Ans : %d",answer_reg[i]);
		end
	end
	if(hostage_num==0)
		answer_reg[0]=0;
	for(i=0;i<curr_ans;i=i+1)begin
		//$display("Ans : %d",answer_reg[i]);
	end
end endtask
// out_valid1 for arrive finish maze
// out_valid2 for out is valid
// in_valid1 for in is valid
// in_valid2 for hostage is rescue and represent that in_data is valid
task move_task;begin
	while(out_valid2==0)begin
		@(negedge clk);
	end
	while(!out_valid1)begin
		in_valid2 = 0;
		in_data = 'bx;
		if(out_valid2==1)begin
			if(maze_reg[curr_y][curr_x]==4 && out!=4)
				spec7_fail;
			if(out==0)begin
				curr_x = curr_x+1;
			end
			else if(out==1)begin
				curr_y = curr_y+1;
			end
			else if(out==2)begin
				curr_x = curr_x-1;
			end
			else if(out==3)begin
				curr_y = curr_y-1;
			end
			else if(out==4)begin
				curr_x = curr_x;
				curr_y = curr_y;
			end
			else begin
				spec7_fail;
			end
			if(maze_reg[curr_y][curr_x]==0)
				spec7_fail;
		end
		else if(curr_x==16 && curr_y==16)begin
			if(out!=0)
				spec4_fail;
		end
		else if(past_outvalid2==1 && out_valid2==0)
			give_indata;
		/*
		if(maze_reg[curr_y][curr_x]==3)begin
			in_valid2 = 1;
			in_data = out_reg[curr_y][curr_x];
		end
		*/
		@(negedge clk);	
		
	end
	
	
end endtask

task spec3_fail; begin 
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 3 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask

task spec4_fail; begin 
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 4 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask

task spec5_fail; begin 
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 5 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask

task spec6_fail; begin 
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 6 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask

task spec7_fail; begin
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 7 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask

task spec8_fail; begin
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 8 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask

task spec9_fail; begin
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 9 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask

//have to handle if the outputvalid raise in the weird time
task spec10_fail; begin 
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 10 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask

task spec11_fail; begin 
		$display ("********************************************************************************************************************************************");
		$display ("*                                                                       SPEC 11 IS FAIL!                                                    *");
		$display ("********************************************************************************************************************************************");
		@(negedge clk);
		$finish;
end endtask



task give_indata;begin
	if(maze_reg[curr_y][curr_x]!=3)
		spec8_fail;
	gap = $urandom_range(2,4);
	repeat(gap) @(negedge clk);
	if(maze_reg[curr_y][curr_x]==3)begin
			in_valid2 = 1;
			in_data = out_reg[curr_y][curr_x];
	end
	else
		spec8_fail;
	@(negedge clk);	
	in_valid2 = 0;
	in_data = 'bx;
end endtask


task check_answer; begin
	out_valid1_cycle_count = 0;
	while(out_valid1)begin
		if(out_data!=answer_reg[out_valid1_cycle_count])begin
			spec10_fail;
		end
		
		@(negedge clk);
		out_valid1_cycle_count = out_valid1_cycle_count+1;
	end
	
	if(curr_ans==0)begin
		if(out_valid1_cycle_count!=1)
			spec9_fail;
	end
	else if(out_valid1_cycle_count!=curr_ans)
		spec9_fail;
	if(out_data!=0)
		spec11_fail;
end endtask


task reset_task ; begin
	#(20); rst_n = 0;
	#(20);
	if((out !== 0) || (out_data !== 0) || (out_valid1!==0 ) || (out_valid2!==0)) begin
		spec3_fail;
	end
	#(20); rst_n = 1 ;
	#(6.0); release clk;
end endtask


task YOU_PASS_task; begin
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						             ");
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;
end endtask

endmodule