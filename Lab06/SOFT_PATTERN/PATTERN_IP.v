//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN_IP.v
//   Module Name : PATTERN_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
    `define CYCLE_TIME 60.0
`endif

`ifdef GATE
    `define CYCLE_TIME 60.0
`endif

module PATTERN_IP #(parameter WIDTH = 3) (
    // Input signals
    IN_P, IN_Q, IN_E,
    // Output signals
    OUT_N, OUT_D
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg [WIDTH-1:0]   IN_P, IN_Q;
output reg [WIDTH*2-1:0] IN_E;
input      [WIDTH*2-1:0] OUT_N, OUT_D;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
real CYCLE = `CYCLE_TIME;

integer in_read,out_read;
integer i,j,a,gap;
integer patcount;
//================================================================
// Wire & Reg Declaration
//================================================================
reg clk;

reg [WIDTH*2-1:0]N_reg,D_reg;
//================================================================
// Clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// Initial
//================================================================
initial begin
    in_read = $fopen("../00_TESTBED/input.txt", "r");
	out_read = $fopen("../00_TESTBED/output.txt", "r");
    IN_P = 'bx;
	IN_Q = 'bx;
	IN_E = 'bx;

	force clk = 0;
	#(5)release clk;
	//@(negedge clk)
    for(patcount = 0;patcount<2; patcount = patcount+1)begin
		
		load_input;
		load_output;
		@(negedge clk);
		check_answer;
		//$display ("PASS Pattern No.%1d, CYCLE =%5d ",patcount,cycles);
		
	end
	IN_P = 'bx;
	IN_Q = 'bx;
	IN_E = 'bx;
	@(negedge clk);
	$finish;
	//repeat(5) @(negedge clk);
    //YOU_PASS_task;
end

//================================================================
// TASK
//================================================================
task load_input;begin
	a = $fscanf(in_read, "%d\n", IN_P);
	a = $fscanf(in_read, "%d\n", IN_Q);
	a = $fscanf(in_read, "%d\n", IN_E);

end endtask

task load_output;begin
	a = $fscanf(out_read, "%d\n", N_reg);
	a = $fscanf(out_read, "%d\n", D_reg);
end endtask

task check_answer;begin
	//$display ("Curr ans: %3d, Your ans: %3d",N_reg,OUT_N);
	//if(OUT_N==N_reg && OUT_D==D_reg)
	if(OUT_N==N_reg && OUT_D==D_reg)
		$display ("PASS");
	else
		$display ("FAIL");
end endtask


endmodule