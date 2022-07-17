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
integer in_read,out_read;
integer patcount;
integer i;
integer cycle;
integer a;
integer golden_num;

parameter PATNUM = 100;

reg signed [6:0] golden_img [0:15];
reg [3:0]input_op [0:14];
reg signed [6:0] input_img [0:63];

//================================================================
// pattern
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		cycle<=0;
	else if(in_valid)
		cycle<=0;
	else
		cycle<=cycle+1;
end

always@(*)begin
	if(cycle>500)begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                            Exceed maximun cycle!!!                                                         ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
end

always	#(`CYCLE_TIME/2.0) clk = ~clk;
initial	clk = 0;


initial begin
	in_read = $fopen("../00_TESTBED/input.txt", "r");
	out_read = $fopen("../00_TESTBED/output.txt", "r");
	signal_init_task;
	
	force clk = 0;
	reset_task;
	repeat(5) @(negedge clk);
	for(patcount = 0; patcount<PATNUM;patcount = patcount+1)begin
		load_input;
		load_output;
		input_task;
		check_golden;
		$display(" No.%2d pass",patcount);
	end
	
	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	$display ("                                                 		PASS ALL PATTERN!!!																			   ");
	$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	$finish;
end

task check_golden; begin
	golden_num = 0;
	while(out_valid==0)begin
		@(negedge clk);
	end
	//golden_num = 0;
	while(out_valid==1)begin
		if(golden_img[golden_num]!==out_data)begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                 		No.%2d  Failed!						   									   ",patcount);
			$display ("                                                        GOLDEN %3d  Your Answer  %3d                           			    			",golden_img[golden_num],out_data);
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$finish;
		end
		golden_num = golden_num + 1;
		@(negedge clk);
	end
	if(golden_num!==16)begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                 		No.%2d Failed!     in_valid should raise 16 cycle						   ",patcount);
		$display ("                                                            	    YOUR output cycle %2d                              			    			",golden_num);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
end endtask

task load_input; begin
	for(i=0;i<15;i=i+1)begin
		a = $fscanf(in_read, "%d\n", input_op[i]);
	end
	for(i=0;i<64;i=i+1)begin
		a = $fscanf(in_read, "%d\n", input_img[i]);
	end
end endtask

task load_output; begin
	for(i=0;i<16;i=i+1)begin
		a = $fscanf(out_read, "%d\n", golden_img[i]);
	end
end endtask

task input_task; begin
	in_valid = 'b1;
	for(i=0;i<64;i=i+1)begin
		if(i<15)begin
			op = input_op[i];
		end
		else begin
			op = 'bx;
		end
		in_data = input_img[i];
		@(negedge clk);
	end
	signal_init_task;
end endtask

task signal_init_task; begin
	rst_n 		= 1;
	in_valid 	= 'b0;
	in_data 	= 'bx;
	op 			= 'bx;
end endtask

task reset_task ;  begin
	#(20); rst_n = 0;
	#(20);
	if((out_valid!==0) || (out_data!==0))begin
		$display ("----------------------------------------------------------------------------------------------------------------------");
		$display ("                                                  Oops! Reset is Wrong                						             ");
		$display ("----------------------------------------------------------------------------------------------------------------------");
		$finish;
	end
	#(20);rst_n = 1;
	#(6); release clk;
end endtask


endmodule
