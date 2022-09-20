`define CYCLE_TIME 12

module PATTERN(
	// Output signals
	clk,
	rst_n,
	in_valid,
	in_data,
	op,
	// Output signals
	out_valid,
	out_data
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk;
output reg rst_n;
output reg in_valid;
output reg signed [6:0] in_data;
output reg [3:0] op;

input out_valid;
input signed [6:0] out_data;

//================================================================
// parameters & integer
//================================================================
integer seed, total_cycles, cycles, PATNUM, i, j, k, input_file, output_file, gap;
//================================================================
// wire & registers 
//================================================================
reg signed [6:0] data_array [7:0][7:0];
reg        [3:0] op_array   [14:0];
reg signed [6:0] out_array  [15:0];
//================================================================
// clock
//================================================================
initial	clk = 0;
always	#(`CYCLE_TIME/2.0) clk = ~clk;
//================================================================
// PATTERN
//================================================================
initial begin
	seed = 105;
	total_cycles = 0;

	input_file   = $fopen("../00_TESTBED/input.txt","r");
	output_file  = $fopen("../00_TESTBED/output.txt","r");
	j = $fscanf (input_file, "%d", PATNUM); 
	
    rst_n      = 1;
    in_valid   = 0;
    //in_data    = 'dx;
    //op         = 'dx;
	
	reset_task;

	for (k = 0 ; k < PATNUM ; k = k + 1) begin
		cycles = 0;	
		get_data;

		gap = $urandom_range(2,5);
		repeat(gap) @(negedge clk);

		input_task;
		
		while(out_valid === 0) begin
			@(negedge clk);
			cycles = cycles + 1;
		end
		check_ans;

		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %5d\033[m", k , cycles);
		total_cycles = total_cycles + cycles;
	end

	pass_task;
end

always @(*) begin
	if (cycles >= 1000) begin
		$display("********************************************************************");
		$display("***********The execution latency is limited in 1000 cycles**********");
		$display("********************************************************************");
		repeat(10) @(negedge clk);
		$finish;
	end
end

always @(*) begin
	if (out_valid & in_valid) begin
		$display("********************************************************************");
		$display("*************The out_valid cannot overlap with in_valid.************");
		$display("********************************************************************");
		repeat(10) @(negedge clk);
		$finish;
	end
end


//======================================
//              TASKS
//======================================
task reset_task; begin
	#(12); rst_n = 0;

	#(3);
	if (out_valid | out_data) begin
		$display("********************************************************************");
		$display("******All your output register should be set zero after reset.******");
		$display("********************************************************************");
		repeat(10) @(negedge clk);
		$finish;
	end

	#(12);
	rst_n    = 1;
	in_valid = 1'b0;
	in_data  = 7'bx;
	op       = 4'bx;

	#(3); release clk;
	@(negedge clk);
end endtask

task get_data; begin
	for (i = 0; i < 64; i = i + 1) j = $fscanf (input_file,  "%d", data_array[i / 8][i % 8]); 
	for (i = 0; i < 15; i = i + 1) j = $fscanf (input_file,  "%d", op_array[i] );
	for (i = 0; i < 16; i = i + 1) j = $fscanf (output_file, "%d", out_array[i]);
end endtask

task input_task; begin

	in_valid = 1'b1;
	for (i = 0; i < 64; i = i + 1) begin
		in_data = data_array[i / 8][i % 8];
		
		if (i < 15) op = op_array[i];
		else        op = 4'bx;
		
		@(negedge clk);
	end

	in_valid = 1'b0;
	in_data  = 7'bx;
	op       = 4'bx;

end endtask

task check_ans; begin

	for (i = 0; i < 16; i = i + 1) begin
		if (out_data !== out_array[i]) begin
			$display("********************************************************************");
			$display("***********************out_data error: %2d**************************", i);
			$display("**************************  Your: %4d******************************", out_data);
			$display("**************************Goledn: %4d******************************", out_array[i]);
			$display("********************************************************************");
			repeat(10) @(negedge clk);
			$finish;
		end

		if (!out_valid) begin
			$display("********************************************************************");
			$display("**************Out_valid should be one when output state*************");
			$display("********************************************************************");
			repeat(10) @(negedge clk);
			$finish;
		end

		@(negedge clk);
	end

	if (out_valid) begin
		$display("********************************************************************");
		$display("************Out_valid should be zero after output state*************");
		$display("********************************************************************");
		repeat(10) @(negedge clk);
		$finish;
	end

end endtask

task pass_task; begin
    $display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
	$display("                    \033[0;38;5;219mTotal Cycle: %10d\033[m         ", total_cycles);
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("********************************************************************");
    $finish;
end endtask

endmodule
