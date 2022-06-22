`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
	in_account,
	in_A,
	in_T,

    //Output Port
	ready,
    out_valid,
	out_account
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------

input 				rst_n, clk1, clk2, in_valid;
input [DSIZE-1:0] 	in_account,in_A,in_T;

output reg				out_valid,ready;
output reg [DSIZE-1:0] 	out_account;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg test_winc;
wire test_rinc;
wire [7:0] test_rdata_account;
wire [7:0] test_rdata_T;
wire [7:0] test_rdata_A;
reg [7:0]account_reg2[0:4];

reg fill_in_signal;
reg empty_signal;
reg [15:0] TA[0:4];


wire [15:0] in_TA;
assign in_TA = test_rdata_T * test_rdata_A;


wire wfull,rempty;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
integer i;
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
		fill_in_signal<=0;
	else if(account_reg2[1]!=0 &&!rempty)
		fill_in_signal<=1;
end

always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
		empty_signal<=0;
	else if(rempty)
		empty_signal<=1;
	else
		empty_signal<=0;
end

always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<=4;i=i+1)
			TA[i]<=0;
	else if(!rempty)begin
		TA[0]<=TA[1];
		TA[1]<=TA[2];
		TA[2]<=TA[3];
		TA[3]<=TA[4];
		TA[4]<=in_TA;
	end
end

always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<=4;i=i+1)
			account_reg2[i]<=0;
	else if(!rempty)begin
		account_reg2[0]<=account_reg2[1];
		account_reg2[1]<=account_reg2[2];
		account_reg2[2]<=account_reg2[3];
		account_reg2[3]<=account_reg2[4];
		account_reg2[4]<=test_rdata_account;
	end
end

reg [15:0]tmp_TA1,tmp_TA2,tmp_TA3;
reg [7:0]tmp_ac1,tmp_ac2,tmp_ac3;
always@(*)begin
	if(TA[0]<TA[1])begin
		tmp_TA1 = TA[0];
		tmp_ac1 = account_reg2[0];
	end
	else begin
		tmp_TA1 = TA[1];
		tmp_ac1 = account_reg2[1];
	end
end

always@(*)begin
	if(TA[2]<TA[3])begin
		tmp_TA2 = TA[2];
		tmp_ac2 = account_reg2[2];
	end
	else begin
		tmp_TA2 = TA[3];
		tmp_ac2 = account_reg2[3];
	end
end

always@(*)begin
	if(tmp_TA1<tmp_TA2)begin
		tmp_TA3 = tmp_TA1;
		tmp_ac3 = tmp_ac1;
	end
	else begin
		tmp_TA3 = tmp_TA2;
		tmp_ac3 = tmp_ac2;
	end
end

always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
		out_account<=0;
	else if(tmp_TA3<TA[4])begin
		out_account <= tmp_ac3;
	end
	else if(tmp_TA3>=TA[4])begin
		out_account <= account_reg2[4];
	end
	
end

// output signal
always@(*)begin
	if(!rst_n)
		ready=0;
	else if(wfull)
		ready=0;
	else
		ready=1;
end

always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
		out_valid<=0;
	else if(fill_in_signal && !empty_signal)
		out_valid<=1;
	else 
		out_valid<=0;
end

always@(*)begin
	if(!in_valid)
		test_winc = 0;
	else 
		test_winc = 1;
end

assign test_rinc = 1;

// asyn fifo
//account
AFIFO u_AFIFO1(
	.rst_n(rst_n),
    .rclk(clk2),
    .rinc(test_rinc),
	.wclk(clk1),
    .winc(test_winc),
	.wdata(in_account),
    .rempty(rempty),
    .rdata(test_rdata_account),
	.wfull(wfull)
    );
// T
AFIFO u_AFIFO2(
	.rst_n(rst_n),
    .rclk(clk2),
    .rinc(test_rinc),
	.wclk(clk1),
    .winc(test_winc),
	.wdata(in_T),
    .rempty(rempty),
    .rdata(test_rdata_T),
	.wfull(wfull)
    );
// A	
AFIFO u_AFIFO3(
	.rst_n(rst_n),
    .rclk(clk2),
    .rinc(test_rinc),
	.wclk(clk1),
    .winc(test_winc),
	.wdata(in_A),
    .rempty(rempty),
    .rdata(test_rdata_A),
	.wfull(wfull)
    );
	
endmodule