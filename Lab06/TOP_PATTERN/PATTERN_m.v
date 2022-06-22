//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL_TOP
    `define CYCLE_TIME 60.0
`endif

`ifdef GATE_TOP
    `define CYCLE_TIME 55.0
`endif

module PATTERN (
    // Output signals
    clk, rst_n, in_valid,
    in_p, in_q, in_e, in_c,
    // Input signals
    out_valid, out_m
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg clk, rst_n, in_valid;
output reg [3:0] in_p, in_q;
output reg [7:0] in_e, in_c;
input out_valid;
input [7:0] out_m;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
real CYCLE = `CYCLE_TIME;
integer in_read;
integer out_read;
integer a;
integer i;
integer counter;
integer gap;
integer patcount;
reg [20:0] curr_cycle;
//================================================================
// Wire & Reg Declaration
//================================================================
reg [7:0] in_c_reg [0:7];
reg [7:0] out_m_reg[0:7];
reg [4:0] in_p_reg;
reg [4:0] in_q_reg;
reg [7:0] in_e_reg;

//================================================================
// Clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

always@(negedge clk)begin
	if(in_valid==1)
		curr_cycle<=0;
	else
		curr_cycle<=curr_cycle+1;
end

always@(*)begin
	if(curr_cycle>5000)begin
		$display ("                           Exceed max cycle 123           						             ");
		$finish;
	end
end

//================================================================
// Initial
//================================================================
initial begin
    in_read = $fopen("../00_TESTBED/input.txt", "r");
	//out_read = $fopen("../00_TESTBED/output.txt", "r");
	curr_cycle = 0;
	in_p = 0;
	in_q = 0;
	in_c = 0;
	in_e = 0;
	in_valid = 'b0;
	force clk = 0;
	reset_task;
    for(patcount = 0;patcount<5; patcount = patcount+1)begin
		load_input;
		//load_output;
		input_task;
		check_answer;
		$display("Pass Pattern: %3d !",patcount);
	end

	$finish;
	//repeat(5) @(negedge clk);
    //YOU_PASS_task;
end

//================================================================
// TASK
//================================================================

task load_input; begin
	a = $fscanf(in_read, "%d\n", in_p_reg);
	a = $fscanf(in_read, "%d\n", in_q_reg);
	a = $fscanf(in_read, "%d\n", in_e_reg);
	for(i=0;i<8;i=i+1)begin
		a = $fscanf(in_read, "%d\n", in_c_reg[i]);
	end
	for(i=0;i<8;i=i+1)begin
		a = $fscanf(in_read, "%d\n", out_m_reg[i]);
	end
end endtask
/*
task load_output; begin
	for(i=0;i<8;i=i+1)begin
		a = $fscanf(out_read, "%d\n", out_m_reg[i]);
	end
end endtask
*/
task input_task; begin
	gap = $urandom_range(2,4);
	repeat(gap) @(negedge clk);
	in_valid = 1'b1;
	for(i=0;i<8;i=i+1)begin
		if(i==0)begin
			in_p = in_p_reg;
			in_q = in_q_reg;
			in_e = in_e_reg;
			in_c = in_c_reg[i];
		end
		else begin
			in_p = 'bx;
			in_q = 'bx;
			in_e = 'bx;
			in_c = in_c_reg[i];
		end
		@(negedge clk);
	end
	in_p = 'bx;
	in_q = 'bx;
	in_e = 'bx;
	in_c = 'bx;
	in_valid = 1'b0;
end endtask

task check_answer; begin
	while(out_valid==0)begin
		@(negedge clk);
	end
	counter = 0;
	while(out_valid==1)begin
		if(out_m_reg[counter]!=out_m)begin
			$display ("----------------------------------------------------------------------------------------------------------------------");
			$display ("                                                Your Recover Message is Wrong!             						             ");
			$display ("                                                  Your Answer is : %d       	                                     ",out_m);
			$display ("                                               Correct Answer is : %d           			                         ", out_m_reg[counter]);
			$display ("----------------------------------------------------------------------------------------------------------------------");
			repeat(1)  @(negedge clk);
			$finish;
		end
		counter=counter+1;
		@(negedge clk);
	end
end endtask

task reset_task ;  begin
	#(20); rst_n = 0;
	#(20);	
	if((out_valid!==0) || (out_m!==0))begin
		$display ("----------------------------------------------------------------------------------------------------------------------");
		$display("                                                  reset fail                                                                             ");
		$display ("----------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
	#(220);rst_n = 1;
	#(6); release clk;
end endtask



endmodule