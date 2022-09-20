//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2022 SPRING
//   Final Proejct              : TOF  
//   Author                     : Wen-Yue, Lin
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TOF.v
//   Module Name : TOF
//   Release version : V1.0 (Release Date: 2022-5)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module TOF(
    // CHIP IO
    clk,
    rst_n,
    in_valid,
    start,
    stop,
    inputtype,
    frame_id,
    busy,

    // AXI4 IO
    arid_m_inf,
    araddr_m_inf,
    arlen_m_inf,
    arsize_m_inf,
    arburst_m_inf,
    arvalid_m_inf,
    arready_m_inf,
    
    rid_m_inf,
    rdata_m_inf,
    rresp_m_inf,
    rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf,

    awid_m_inf,
    awaddr_m_inf,
    awsize_m_inf,
    awburst_m_inf,
    awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,

    wdata_m_inf,
    wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,
    
    bid_m_inf,
    bresp_m_inf,
    bvalid_m_inf,
    bready_m_inf 
);
// ===============================================================
//                      Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter


// ===============================================================
//                      Input / Output 
// ===============================================================

// << CHIP io port with system >>
input           clk, rst_n;
input           in_valid;
input           start;
input [15:0]    stop;     
input [1:0]     inputtype; 
input [4:0]     frame_id;
output reg      busy;       

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
    Your AXI-4 interface could be designed as a bridge in submodule,
    therefore I declared output of AXI as wire.  
    Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)    axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)    axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1)     axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)    axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)    axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------


// ===============================================================
// axi general assign
// ===============================================================
assign arid_m_inf = 0;
assign arburst_m_inf = 1;
assign arsize_m_inf = 3'b100;
assign awid_m_inf = 0;
assign awburst_m_inf = 1;
assign awsize_m_inf = 3'b100;
// ===============================================================
// Finite State Machine Parameter and Integer
// ===============================================================
integer i;
// FSM
parameter IDLE 			= 5'd0;
// type0                  
parameter SET_RD_VALID 	= 5'd1;
parameter RD_DRAM 		= 5'd2;
parameter IDLE2			= 5'd3;
parameter TYPE0_OP		= 5'd4;
parameter WAIT_IDLE0	= 5'd5;
parameter WR_DRAM 		= 5'd6;
// type123 get data to sram         
parameter WAIT_START	= 5'd7;
parameter RD_HIST		= 5'd8;
//type1 
parameter IDLE3			= 5'd9;
parameter TYPE1_OP		= 5'd10;
parameter WAIT_IDLE1	= 5'd11;
//type23                  
parameter IDLE5			= 5'd14;
parameter FIND_RANGE	= 5'd15;
//////
//type3 only
parameter IDLE6			= 5'd16;
parameter FIND_CAVE		= 5'd17;
parameter IDLE_FIND_CAVE= 5'd18;
//////
parameter IDLE7			= 5'd19;
parameter FIND_VEX		= 5'd20;
parameter IDLE_FIND_VEX = 5'd21;
parameter IDLE8			= 5'd22;
// type 123 histogram write
parameter IDLE4			= 5'd12;
parameter WR_DRAM_HIST  = 5'd13;

//================================================================
//  Reg and Wire                   
//================================================================
reg [4:0] state_cs,state_ns;
reg [4:0]frame_id_reg;
reg [1:0]mode_reg;

reg [7:0]counter;
reg [7:0]counter2;
reg [7:0]counter3;
reg [7:0]counter4;
reg [7:0]round_counter;


//read submodule signal
reg read_in_valid;
wire read_out_valid;
wire [7:0] read_counter;
wire [31:0] dram_read_addr = {frame_id_reg+8'h10,12'b0000_0000_0000}; 
//write submodule signal
wire write_in_valid;
wire write_out_valid;
reg [31:0]dram_write_addr;
reg [127:0]dram_write_val;
wire [31:0]idx_sel = frame_id_reg+8'h10;
reg data_ready ;
//window5 method signal
reg win5_in_valid;
wire win5_out_valid[0:3];
reg [15:0] win5_in_data[0:3];
wire [7:0] win5_large_dist[0:3];
reg [7:0] win5_large_dist_reg [0:3];
//window10
reg [13:0] win10_curr_val;
reg [13:0] win10_max_val;
reg [7:0] win10_max_dist;


//type23 peak
reg [1:0]type23_coeff[0:15];
reg [6:0] type23_peak_type;
reg [7:0]round_max_dist;
//================================================================
//  SRAM                 
//================================================================
wire [63:0] Q_mem_out[0:3];
reg [5:0] mem_address[0:3];
reg [63:0] D_mem_in	 [0:3];
reg mem_wen[0:3];
wire mem_cen;
wire mem_oen;
assign mem_cen = 0;
assign mem_oen = 0;
SRAM_64_64 sram0(.Q(Q_mem_out[0]),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen[0]),.A(mem_address[0]),.D(D_mem_in[0]),.OEN(mem_oen));
SRAM_64_64 sram1(.Q(Q_mem_out[1]),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen[1]),.A(mem_address[1]),.D(D_mem_in[1]),.OEN(mem_oen));
SRAM_64_64 sram2(.Q(Q_mem_out[2]),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen[2]),.A(mem_address[2]),.D(D_mem_in[2]),.OEN(mem_oen));
SRAM_64_64 sram3(.Q(Q_mem_out[3]),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen[3]),.A(mem_address[3]),.D(D_mem_in[3]),.OEN(mem_oen));
//================================================================
//  SUBMODULE  and submodule signal                
//================================================================
DRAM_read test_read(
	// global signals 
	   clk, rst_n,
	// axi read address channel 
		araddr_m_inf,	
		arlen_m_inf,	
		arvalid_m_inf,  
		arready_m_inf, 	
	// axi read data channel 
		rdata_m_inf, 	
		rlast_m_inf,	
		rvalid_m_inf,	
		rready_m_inf,	
	// input signals
		read_in_valid,
		dram_read_addr,
	// output signals
		read_out_valid,
		read_counter
);

DRAM_write test_write(
	// global signals 
       clk, rst_n,
	// axi write address channel 
		awaddr_m_inf,
		awvalid_m_inf,
		awready_m_inf,
		awlen_m_inf,
	// axi write data channel 
		wdata_m_inf,
		wlast_m_inf,
		wvalid_m_inf,
		wready_m_inf,
	// axi write response channel
		bvalid_m_inf,
		bready_m_inf,
	// input
		write_in_valid, // in_valid
		4'b0001,
		dram_write_addr,
		dram_write_val,
		mode_reg,
		data_ready,
	// output
		write_out_valid
);

WINDOW_MET_5 win_5_1(.clk(clk),.rst_n(rst_n),.in_valid(win5_in_valid),
					.in_data(win5_in_data[0]),.out_valid(win5_out_valid[0]),.out_dist(win5_large_dist[0]),.curr_mode(mode_reg));
WINDOW_MET_5 win_5_2(.clk(clk),.rst_n(rst_n),.in_valid(win5_in_valid),
					.in_data(win5_in_data[1]),.out_valid(win5_out_valid[1]),.out_dist(win5_large_dist[1]),.curr_mode(mode_reg));
WINDOW_MET_5 win_5_3(.clk(clk),.rst_n(rst_n),.in_valid(win5_in_valid),
					.in_data(win5_in_data[2]),.out_valid(win5_out_valid[2]),.out_dist(win5_large_dist[2]),.curr_mode(mode_reg));
WINDOW_MET_5 win_5_4(.clk(clk),.rst_n(rst_n),.in_valid(win5_in_valid),
					.in_data(win5_in_data[3]),.out_valid(win5_out_valid[3]),.out_dist(win5_large_dist[3]),.curr_mode(mode_reg));
//================================================================
//  Dram Write Signal                
//================================================================
assign write_in_valid = state_ns==WR_DRAM || (state_cs==WAIT_START && state_ns==RD_HIST);

reg [7:0]Q_out_sel[0:3];
always@(*)begin
	if(state_ns==WR_DRAM_HIST || state_ns==IDLE4)
		case(round_counter[3:0])
			0:begin
				Q_out_sel[0] = Q_mem_out[0][3:0];
				Q_out_sel[1] = Q_mem_out[1][3:0];
				Q_out_sel[2] = Q_mem_out[2][3:0];
				Q_out_sel[3] = Q_mem_out[3][3:0];
			end
			1:begin
				Q_out_sel[0] = Q_mem_out[0][7:4];
				Q_out_sel[1] = Q_mem_out[1][7:4];
				Q_out_sel[2] = Q_mem_out[2][7:4];
				Q_out_sel[3] = Q_mem_out[3][7:4];
				
			end
			2:begin
				Q_out_sel[0] = Q_mem_out[0][11:8];
				Q_out_sel[1] = Q_mem_out[1][11:8];
				Q_out_sel[2] = Q_mem_out[2][11:8];
				Q_out_sel[3] = Q_mem_out[3][11:8];
			end
			3:begin
				Q_out_sel[0] = Q_mem_out[0][15:12];
				Q_out_sel[1] = Q_mem_out[1][15:12];
				Q_out_sel[2] = Q_mem_out[2][15:12];
				Q_out_sel[3] = Q_mem_out[3][15:12];
			end
			4:begin
				Q_out_sel[0] = Q_mem_out[0][19:16];
				Q_out_sel[1] = Q_mem_out[1][19:16];
				Q_out_sel[2] = Q_mem_out[2][19:16];
				Q_out_sel[3] = Q_mem_out[3][19:16];
			end
			5:begin
				Q_out_sel[0] = Q_mem_out[0][23:20];
				Q_out_sel[1] = Q_mem_out[1][23:20];
				Q_out_sel[2] = Q_mem_out[2][23:20];
				Q_out_sel[3] = Q_mem_out[3][23:20];
			end
			6:begin
				Q_out_sel[0] = Q_mem_out[0][27:24];
				Q_out_sel[1] = Q_mem_out[1][27:24];
				Q_out_sel[2] = Q_mem_out[2][27:24];
				Q_out_sel[3] = Q_mem_out[3][27:24];
			end
			7:begin
				Q_out_sel[0] = Q_mem_out[0][31:28];
				Q_out_sel[1] = Q_mem_out[1][31:28];
				Q_out_sel[2] = Q_mem_out[2][31:28];
				Q_out_sel[3] = Q_mem_out[3][31:28];
			end
			8:begin
				Q_out_sel[0] = Q_mem_out[0][35:32];
				Q_out_sel[1] = Q_mem_out[1][35:32];
				Q_out_sel[2] = Q_mem_out[2][35:32];
				Q_out_sel[3] = Q_mem_out[3][35:32];
			end
			9:begin
				Q_out_sel[0] = Q_mem_out[0][39:36];
				Q_out_sel[1] = Q_mem_out[1][39:36];
				Q_out_sel[2] = Q_mem_out[2][39:36];
				Q_out_sel[3] = Q_mem_out[3][39:36];
			end
			10:begin
				Q_out_sel[0] = Q_mem_out[0][43:40];
				Q_out_sel[1] = Q_mem_out[1][43:40];
				Q_out_sel[2] = Q_mem_out[2][43:40];
				Q_out_sel[3] = Q_mem_out[3][43:40];
			end	
			11:begin
				Q_out_sel[0] = Q_mem_out[0][47:44];
				Q_out_sel[1] = Q_mem_out[1][47:44];
				Q_out_sel[2] = Q_mem_out[2][47:44];
				Q_out_sel[3] = Q_mem_out[3][47:44];
			end
			12:begin
				Q_out_sel[0] = Q_mem_out[0][51:48];
				Q_out_sel[1] = Q_mem_out[1][51:48];
				Q_out_sel[2] = Q_mem_out[2][51:48];
				Q_out_sel[3] = Q_mem_out[3][51:48];
			end
			13:begin
				Q_out_sel[0] = Q_mem_out[0][55:52];
				Q_out_sel[1] = Q_mem_out[1][55:52];
				Q_out_sel[2] = Q_mem_out[2][55:52];
				Q_out_sel[3] = Q_mem_out[3][55:52];
			end
			14:begin
				Q_out_sel[0] = Q_mem_out[0][59:56];
				Q_out_sel[1] = Q_mem_out[1][59:56];
				Q_out_sel[2] = Q_mem_out[2][59:56];
				Q_out_sel[3] = Q_mem_out[3][59:56];
			end
			15:begin
				Q_out_sel[0] = Q_mem_out[0][63:60];
				Q_out_sel[1] = Q_mem_out[1][63:60];
				Q_out_sel[2] = Q_mem_out[2][63:60];
				Q_out_sel[3] = Q_mem_out[3][63:60];
			end
			default:begin
				Q_out_sel[0] = 0;
				Q_out_sel[1] = 0;
				Q_out_sel[2] = 0;
				Q_out_sel[3] = 0;
			end
		endcase
	else begin
		Q_out_sel[0] = 0;
		Q_out_sel[1] = 0;
		Q_out_sel[2] = 0;
		Q_out_sel[3] = 0;
	end
end

reg [7:0] type1_dist_sel;

always@(*)begin
	if(round_counter==0 || round_counter==1 || round_counter==4 || round_counter==5)
		type1_dist_sel = win5_large_dist_reg[0];
	else if(round_counter==2 || round_counter==3 || round_counter==6 || round_counter==7)
		type1_dist_sel = win5_large_dist_reg[1];
	else if(round_counter==8 || round_counter==9 || round_counter==12 || round_counter==13)
		type1_dist_sel = win5_large_dist_reg[2];
	else
		type1_dist_sel = win5_large_dist_reg[3];
end

reg [1:0]type_sel;
always@(*)begin
	if(type23_peak_type[1:0]==0)
		type_sel = 2;
	else if(type23_peak_type[1:0]==1)
		type_sel = 1;
	else
		type_sel = 0;
end

// dram_write_addr
always@(*)begin
	if(state_ns==WR_DRAM)
		dram_write_addr = {12'b0000_0000_0000,idx_sel,counter2[3:0],8'hf0};
	else if(state_ns==RD_HIST)
		dram_write_addr = {12'b0000_0000_0000,idx_sel,8'b0000_0000,4'h0};
	else
		dram_write_addr = 0;
end
// dram_write_val

reg [7:0] ans_val;
reg [7:0] ans_val2;
always@(*)begin
	if(state_ns==IDLE4)begin
		if(mode_reg==1)
			ans_val = type1_dist_sel;
		else if(type23_peak_type[6]==0)
			ans_val = win10_max_dist+(-5)*type_sel+5*type23_coeff[round_counter];
		else
			ans_val = win10_max_dist+15+(-5)*type_sel-5*type23_coeff[round_counter];
	end
	else
		ans_val=1;
end

always@(*)begin
	if(state_ns==IDLE4)begin
		if(ans_val==0)
			ans_val2 = 1;
		else
			ans_val2 = ans_val;
	end
	else 
		ans_val2 = 1;
end

//assign ans_val2 = (ans_val==0)?1:ans_val;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		dram_write_val<=0;
	else if(state_ns==WR_DRAM)
		dram_write_val<={win5_large_dist_reg[counter2[1:0]],
						4'b0000,Q_mem_out[counter2[1:0]][59:56],
						4'b0000,Q_mem_out[counter2[1:0]][55:52],
						4'b0000,Q_mem_out[counter2[1:0]][51:48],
						4'b0000,Q_mem_out[counter2[1:0]][47:44],
						4'b0000,Q_mem_out[counter2[1:0]][43:40],
						4'b0000,Q_mem_out[counter2[1:0]][39:36],
						4'b0000,Q_mem_out[counter2[1:0]][35:32],
						4'b0000,Q_mem_out[counter2[1:0]][31:28],
						4'b0000,Q_mem_out[counter2[1:0]][27:24],
						4'b0000,Q_mem_out[counter2[1:0]][23:20],
						4'b0000,Q_mem_out[counter2[1:0]][19:16],
						4'b0000,Q_mem_out[counter2[1:0]][15:12],
						4'b0000,Q_mem_out[counter2[1:0]][11:8],
						4'b0000,Q_mem_out[counter2[1:0]][7:4],
						4'b0000,Q_mem_out[counter2[1:0]][3:0]};
	else if(state_ns==WR_DRAM_HIST)begin
		case(counter[1:0])
			0:dram_write_val <={96'h0,Q_out_sel[3],Q_out_sel[2],Q_out_sel[1],Q_out_sel[0]};
			1:dram_write_val <={64'h0,Q_out_sel[3],Q_out_sel[2],Q_out_sel[1],Q_out_sel[0],dram_write_val[31:0]};
			2:dram_write_val <={32'h0,Q_out_sel[3],Q_out_sel[2],Q_out_sel[1],Q_out_sel[0],dram_write_val[63:0]};
			3:dram_write_val <={Q_out_sel[3],Q_out_sel[2],Q_out_sel[1],Q_out_sel[0],dram_write_val[95:0]};
			default:dram_write_val <=0;
		endcase
	end
	else if(state_ns==IDLE4)begin
		dram_write_val <={ans_val2,Q_out_sel[2],Q_out_sel[1],Q_out_sel[0],dram_write_val[95:0]};
	end
	else
		dram_write_val <= 0;
end

// data_ready
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		data_ready<=0;
	else if(state_ns==WR_DRAM)
		data_ready<=1;
	else if(state_ns==WR_DRAM_HIST)begin
		if (counter2==2 && round_counter==0)
			data_ready<=1;
		else if(counter2==5)
			data_ready<=0;
		else if(counter[1:0]==3)
			data_ready<=1;
		else if(counter2>5)
			data_ready<=0;
	end
	else if(state_cs==WR_DRAM_HIST && state_ns==IDLE4)
		data_ready<=1;
	else
		data_ready<=0;
end

//================================================================
//  Design                  
//================================================================
reg wait_idle;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		wait_idle<=0;
	else if(state_cs==IDLE2 || state_cs==IDLE3 || state_cs==IDLE4 || state_cs==IDLE5 ||  state_cs==WAIT_IDLE0 || state_cs==WAIT_IDLE1 || state_cs==IDLE6 || state_cs==IDLE7 || state_cs==IDLE_FIND_CAVE || state_cs==IDLE_FIND_VEX)
		wait_idle<=1;
	else
		wait_idle<=0;
end

// type0 control signal
wire type0_done;
wire type0_round_done;
assign type0_done = round_counter==4;
assign type0_round_done = counter==255;

// type1 control signal
wire type1_op_done;
wire type1_op_round_done;
assign type1_op_done = round_counter==1;
assign type1_op_round_done = counter==255;

// type2 control signal
wire find_range_done;
assign find_range_done = counter==255;

// find cave control signal
wire find_cave_done;
wire find_cave_round_done;
wire find_cave_candidate_done;
assign find_cave_done = round_counter==16;
assign find_cave_round_done = counter4==20;
assign find_cave_candidate_done = counter3==3;
// find vex control signal
wire find_vex_done;
wire find_vex_round_done;
wire find_vex_candidate_done;
assign find_vex_done = round_counter==16;
assign find_vex_round_done = counter4==20;
assign find_vex_candidate_done = counter3==3;
// write histogram to dram doneDONE
wire type_wr_done;
wire type_wr_round_done;
assign type_wr_done = round_counter==16;
assign type_wr_round_done = counter==63;

// FSM
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE: begin
			if(in_valid)begin
				if(inputtype==0)
					state_ns = SET_RD_VALID;
				else
					state_ns = WAIT_START;
			end
			else
				state_ns = state_cs;
		end
		// type 0 
		SET_RD_VALID:	state_ns = (read_out_valid)?RD_DRAM:SET_RD_VALID;
		RD_DRAM: 		state_ns = (~read_out_valid)?IDLE2:RD_DRAM;
		IDLE2:			state_ns = (type0_done)?IDLE:((wait_idle)?TYPE0_OP:IDLE2);
		TYPE0_OP: 		state_ns = (type0_round_done)?WAIT_IDLE0:TYPE0_OP;
		WAIT_IDLE0:		state_ns = (wait_idle)?WR_DRAM:WAIT_IDLE0;
		WR_DRAM:		state_ns = (write_out_valid && counter2[1:0]==3)?IDLE2:WR_DRAM;
		// type 123
		WAIT_START: 	state_ns = (start)?RD_HIST:WAIT_START;
		RD_HIST:begin
			if(~in_valid)begin
				if(mode_reg==1)
					state_ns = IDLE3;
				else
					state_ns = IDLE5;
			end
			else begin
				if(~start)
					state_ns = WAIT_START;
				else
					state_ns = RD_HIST;
			end
		end
		// type1
		IDLE3:			state_ns = (type1_op_done)?((mode_reg==1)?IDLE4:IDLE5):wait_idle?TYPE1_OP:IDLE3; // type23 should use type 1 ans need to be consider
		TYPE1_OP:		state_ns = (type1_op_round_done)?WAIT_IDLE1:TYPE1_OP;
		WAIT_IDLE1:		state_ns = wait_idle?IDLE3:WAIT_IDLE1;
		// type23
		IDLE5:			state_ns = (wait_idle)?FIND_RANGE:IDLE5;
		FIND_RANGE:		state_ns = (find_range_done)?(mode_reg==3)?IDLE6:IDLE7:FIND_RANGE;
		//find cave
		IDLE6:			state_ns = (find_cave_done)?IDLE7:(wait_idle)?FIND_CAVE:IDLE6;
		FIND_CAVE:		state_ns = (find_cave_round_done)?IDLE_FIND_CAVE:FIND_CAVE;
		IDLE_FIND_CAVE:	state_ns = (find_cave_candidate_done)?IDLE6:wait_idle?FIND_CAVE:IDLE_FIND_CAVE;
		// find vex
		IDLE7:			state_ns = (find_vex_done)?IDLE8:(wait_idle)?FIND_VEX:IDLE7;
		FIND_VEX:		state_ns = (find_vex_round_done)?IDLE_FIND_VEX:FIND_VEX;
		IDLE_FIND_VEX:	state_ns = (find_vex_candidate_done)?IDLE7:wait_idle?FIND_VEX:IDLE_FIND_VEX;
		IDLE8:			state_ns = IDLE4;
		// type123 write back
		IDLE4:			state_ns = (type_wr_done)?IDLE:wait_idle?WR_DRAM_HIST:IDLE4;
		WR_DRAM_HIST:	state_ns = (type_wr_round_done)?IDLE4:WR_DRAM_HIST;
		default: 		state_ns = state_cs;
	endcase	
end
// Counter
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_ns==IDLE2 || state_ns==WAIT_START || state_ns==IDLE3 || state_ns==IDLE4 || state_ns==IDLE5 || state_ns==IDLE6 || state_ns==IDLE7 || state_ns==IDLE_FIND_CAVE || state_ns==IDLE_FIND_VEX)
		counter<=0;
	else if(state_ns==TYPE1_OP)
		counter<=counter+1;
	else if(state_ns==TYPE0_OP)
		counter<=counter+1;
	else if(state_ns==RD_HIST)
		counter<=counter+1;
	else if(state_ns==WR_DRAM_HIST)
		counter<=counter+1;
	else if(state_ns==FIND_RANGE)
		counter<=counter+1;
	else if(state_ns==FIND_CAVE || state_ns==FIND_VEX)
		counter<=counter+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter2<=0;
	else if(state_ns==IDLE || (state_cs==TYPE1_OP && state_ns==WAIT_IDLE1) || ((state_cs==WR_DRAM_HIST||state_cs==IDLE8) && state_ns==IDLE4)||(state_cs==FIND_RANGE&& (state_ns==IDLE7||state_ns==IDLE6)) || (state_cs==FIND_CAVE && state_ns==IDLE_FIND_CAVE)||
			(state_cs==FIND_VEX && state_ns==IDLE_FIND_VEX))
		counter2<=0;
	else if(state_cs==IDLE_FIND_CAVE && state_ns==IDLE6 && round_counter==15)
		counter2<=0;
	else if(state_cs==WR_DRAM && write_out_valid)
		counter2<=counter2+1;
	else if(state_cs==IDLE3 || state_cs==TYPE1_OP)
		counter2<=counter2+1;
	else if(state_cs==IDLE4 || state_cs==WR_DRAM_HIST)
		counter2<=counter2+1;
	else if(state_cs==IDLE5 || state_cs==FIND_RANGE)
		counter2<=counter2+1;
	else if(state_cs==IDLE6 || state_cs==IDLE7 || state_cs==FIND_CAVE || state_cs==FIND_VEX || (state_cs==IDLE_FIND_VEX ) || (state_cs==IDLE_FIND_CAVE ))
		counter2<=counter2+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter3<=0;
	else if(state_ns==IDLE ||state_ns==IDLE6 || state_ns==IDLE7)
		counter3<=0;
	else if(state_cs==FIND_RANGE)
		counter3<=counter3+1;
	else if((state_cs==FIND_CAVE && state_ns==IDLE_FIND_CAVE) || (state_cs==FIND_VEX && state_ns==IDLE_FIND_VEX))
		counter3<=counter3+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter4<=0;
	else if(state_ns==IDLE || state_ns==IDLE_FIND_CAVE || state_ns==IDLE_FIND_VEX)
		counter4<=0;
	else if(state_cs==FIND_CAVE || state_cs==FIND_VEX)
		counter4<=counter4+1;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_counter<=0;
	else if(state_ns==IDLE || (state_cs==RD_HIST && state_ns==IDLE3) || (state_cs==IDLE3 && state_ns==IDLE4) || state_ns==IDLE5 || (state_cs==IDLE6 && state_ns==IDLE7) ||(state_cs==IDLE7 && state_ns==IDLE8))
		round_counter<=0;
	else if(state_cs==WR_DRAM && state_ns==IDLE2)
		round_counter<=round_counter+1;
	else if(state_cs==RD_HIST && state_ns==WAIT_START)
		round_counter<=round_counter+1;
	else if(state_cs==TYPE1_OP && state_ns==WAIT_IDLE1)
		round_counter<=round_counter+1;
	else if(state_cs==WR_DRAM_HIST && state_ns==IDLE4)
		round_counter<=round_counter+1;
	else if((state_cs==IDLE_FIND_CAVE && state_ns==IDLE6) || (state_cs==IDLE_FIND_VEX && state_ns==IDLE7))
		round_counter<=round_counter+1;
	
end
// reg control
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		frame_id_reg<=0;
	else if(state_cs==IDLE && (state_ns==SET_RD_VALID || state_ns==WAIT_START))
		frame_id_reg<=frame_id;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		mode_reg<=0;
	else if(state_cs==IDLE && in_valid)begin
		mode_reg<=inputtype;
	end
end

// output signal
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		busy<=0;
	else if(state_ns==IDLE)
		busy<=0;
	else if(!in_valid&&(state_cs==SET_RD_VALID || state_cs==IDLE3 || state_cs==IDLE5))
		busy<=1;
end

///////////
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		read_in_valid<=0;
	else if(state_ns==SET_RD_VALID && in_valid)
		read_in_valid <= 1;
	else
		read_in_valid <= 0;
end




//====================
// win5_metod control
//====================

// win5_in_valid
always@(*)begin
	if(state_ns==TYPE0_OP || state_ns==TYPE1_OP)
		win5_in_valid = 1;
	else
		win5_in_valid = 0;
end
// win5_large_dist_reg
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			win5_large_dist_reg[i]<=0;
	else if(state_cs==WAIT_IDLE0 && state_ns==WR_DRAM)begin
		win5_large_dist_reg[0]<=win5_large_dist[0];
		win5_large_dist_reg[1]<=win5_large_dist[1];
		win5_large_dist_reg[2]<=win5_large_dist[2];
		win5_large_dist_reg[3]<=win5_large_dist[3];
	end
	else if(state_cs==WAIT_IDLE1 && state_ns==IDLE3)begin
		win5_large_dist_reg[0]<=win5_large_dist[0];
		win5_large_dist_reg[1]<=win5_large_dist[1];
		win5_large_dist_reg[2]<=win5_large_dist[2];
		win5_large_dist_reg[3]<=win5_large_dist[3];
	end
end
// win5_in_data
always@(*)begin
	if(state_ns==TYPE0_OP)begin
		case(counter[3:0])
			0:begin
				win5_in_data[0] = {Q_mem_out[0][3:0],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][3:0],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][3:0],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][3:0],12'b0000_0000_0000};
			end
			1:begin
				win5_in_data[0] = {Q_mem_out[0][7 :4 ],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][7 :4 ],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][7 :4 ],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][7 :4 ],12'b0000_0000_0000};
			end                                        
			2:begin                                    
				win5_in_data[0] = {Q_mem_out[0][11:8 ],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][11:8 ],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][11:8 ],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][11:8 ],12'b0000_0000_0000};
			end                                        
			3:begin                                    
				win5_in_data[0] = {Q_mem_out[0][15:12],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][15:12],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][15:12],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][15:12],12'b0000_0000_0000};
			end                                        
			4:begin                                    
				win5_in_data[0] = {Q_mem_out[0][19:16],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][19:16],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][19:16],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][19:16],12'b0000_0000_0000};
			end                                        
			5:begin                                    
				win5_in_data[0] = {Q_mem_out[0][23:20],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][23:20],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][23:20],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][23:20],12'b0000_0000_0000};
			end                                        
			6:begin                                    
				win5_in_data[0] = {Q_mem_out[0][27:24],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][27:24],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][27:24],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][27:24],12'b0000_0000_0000};
			end                                        
			7:begin                                    
				win5_in_data[0] = {Q_mem_out[0][31:28],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][31:28],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][31:28],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][31:28],12'b0000_0000_0000};
			end                                        
			8:begin                                    
				win5_in_data[0] = {Q_mem_out[0][35:32],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][35:32],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][35:32],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][35:32],12'b0000_0000_0000};
			end                                        
			9:begin                                    
				win5_in_data[0] = {Q_mem_out[0][39:36],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][39:36],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][39:36],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][39:36],12'b0000_0000_0000};
			end                                        
			10:begin                                   
				win5_in_data[0] = {Q_mem_out[0][43:40],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][43:40],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][43:40],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][43:40],12'b0000_0000_0000};
			end                                        
			11:begin                                   
				win5_in_data[0] = {Q_mem_out[0][47:44],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][47:44],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][47:44],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][47:44],12'b0000_0000_0000};
			end                                        
			12:begin                                   
				win5_in_data[0] = {Q_mem_out[0][51:48],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][51:48],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][51:48],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][51:48],12'b0000_0000_0000};
			end                                        
			13:begin                                   
				win5_in_data[0] = {Q_mem_out[0][55:52],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][55:52],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][55:52],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][55:52],12'b0000_0000_0000};
			end                                        
			14:begin                                   
				win5_in_data[0] = {Q_mem_out[0][59:56],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][59:56],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][59:56],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][59:56],12'b0000_0000_0000};
			end                                        
			15:begin                                   
				win5_in_data[0] = {Q_mem_out[0][63:60],12'b0000_0000_0000};
				win5_in_data[1] = {Q_mem_out[1][63:60],12'b0000_0000_0000};
				win5_in_data[2] = {Q_mem_out[2][63:60],12'b0000_0000_0000};
				win5_in_data[3] = {Q_mem_out[3][63:60],12'b0000_0000_0000};
			end
		endcase
	end
	else if(state_ns==TYPE1_OP)begin
		case(counter[1:0])
			0:begin
				win5_in_data[0] = {Q_mem_out[0][3 :0 ],Q_mem_out[0][7 :4 ],Q_mem_out[0][19:16],Q_mem_out[0][23:20]};
				win5_in_data[1] = {Q_mem_out[0][11:8 ],Q_mem_out[0][15:12],Q_mem_out[0][27:24],Q_mem_out[0][31:28]};
				win5_in_data[2] = {Q_mem_out[0][35:32],Q_mem_out[0][39:36],Q_mem_out[0][51:48],Q_mem_out[0][55:52]};
				win5_in_data[3] = {Q_mem_out[0][43:40],Q_mem_out[0][47:44],Q_mem_out[0][59:56],Q_mem_out[0][63:60]};
			end                                       
			1:begin                                   
				win5_in_data[0] = {Q_mem_out[1][3 :0 ],Q_mem_out[1][7 :4 ],Q_mem_out[1][19:16],Q_mem_out[1][23:20]};
				win5_in_data[1] = {Q_mem_out[1][11:8 ],Q_mem_out[1][15:12],Q_mem_out[1][27:24],Q_mem_out[1][31:28]};
				win5_in_data[2] = {Q_mem_out[1][35:32],Q_mem_out[1][39:36],Q_mem_out[1][51:48],Q_mem_out[1][55:52]};
				win5_in_data[3] = {Q_mem_out[1][43:40],Q_mem_out[1][47:44],Q_mem_out[1][59:56],Q_mem_out[1][63:60]};
			end                                       
			2:begin                                   
				win5_in_data[0] = {Q_mem_out[2][3 :0 ],Q_mem_out[2][7 :4 ],Q_mem_out[2][19:16],Q_mem_out[2][23:20]};
				win5_in_data[1] = {Q_mem_out[2][11:8 ],Q_mem_out[2][15:12],Q_mem_out[2][27:24],Q_mem_out[2][31:28]};
				win5_in_data[2] = {Q_mem_out[2][35:32],Q_mem_out[2][39:36],Q_mem_out[2][51:48],Q_mem_out[2][55:52]};
				win5_in_data[3] = {Q_mem_out[2][43:40],Q_mem_out[2][47:44],Q_mem_out[2][59:56],Q_mem_out[2][63:60]};
			end                  
			3:begin              
				win5_in_data[0] = {Q_mem_out[3][3  :0 ],Q_mem_out[3][7 :4 ],Q_mem_out[3][19:16],Q_mem_out[3][23:20]};
				win5_in_data[1] = {Q_mem_out[3][11 :8 ],Q_mem_out[3][15:12],Q_mem_out[3][27:24],Q_mem_out[3][31:28]};
				win5_in_data[2] = {Q_mem_out[3][35 :32],Q_mem_out[3][39:36],Q_mem_out[3][51:48],Q_mem_out[3][55:52]};
				win5_in_data[3] = {Q_mem_out[3][43 :40],Q_mem_out[3][47:44],Q_mem_out[3][59:56],Q_mem_out[3][63:60]};
			end
		endcase
	end
	else begin
				win5_in_data[0] = 0;
				win5_in_data[1] = 0;
				win5_in_data[2] = 0;
				win5_in_data[3] = 0;
	end
end

//====================
// win10_metod control
//====================

reg [13:0] type23_shift_reg [0:9];
reg [63:0] sram_read_reg[0:3];
reg [63:0] curr_sel_sram_read_reg;
reg [7:0] type23_in_data;


//sram_read_reg
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			sram_read_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<4;i=i+1)
			sram_read_reg[i]<=0;
	else if(state_ns==FIND_RANGE || state_ns==FIND_CAVE || state_ns==FIND_VEX)begin
		sram_read_reg[0]<=Q_mem_out[0];
		sram_read_reg[1]<=Q_mem_out[1];
		sram_read_reg[2]<=Q_mem_out[2];
		sram_read_reg[3]<=Q_mem_out[3];
	end
end

//curr_sel_sram_read_reg
always@(*)begin
	if(state_cs==FIND_RANGE)begin
		case(counter3[1:0])
			0:curr_sel_sram_read_reg = sram_read_reg[0];
			1:curr_sel_sram_read_reg = sram_read_reg[1];
			2:curr_sel_sram_read_reg = sram_read_reg[2];
			3:curr_sel_sram_read_reg = sram_read_reg[3];
		endcase
	end
	else
		curr_sel_sram_read_reg = 0;
end
//type23_shift_reg
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<20;i=i+1)
			type23_shift_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<20;i=i+1)
			type23_shift_reg[i]<=0;
	else if(state_cs==FIND_RANGE)begin
		type23_shift_reg[0 ]<=type23_shift_reg[1 ];
		type23_shift_reg[1 ]<=type23_shift_reg[2 ];
		type23_shift_reg[2 ]<=type23_shift_reg[3 ];
		type23_shift_reg[3 ]<=type23_shift_reg[4 ];
		type23_shift_reg[4 ]<=type23_shift_reg[5 ];
		type23_shift_reg[5 ]<=type23_shift_reg[6 ];
		type23_shift_reg[6 ]<=type23_shift_reg[7 ];
		type23_shift_reg[7 ]<=type23_shift_reg[8 ];
		type23_shift_reg[8 ]<=type23_shift_reg[9 ];
		type23_shift_reg[9 ]<=type23_in_data;
	end
end

//type23_in_data
always@(*)begin
	if(state_ns==FIND_RANGE)begin
		type23_in_data = ((curr_sel_sram_read_reg[3 :0 ]+curr_sel_sram_read_reg[7 :4 ])+(curr_sel_sram_read_reg[11:8 ]+curr_sel_sram_read_reg[15:12]))+
						 ((curr_sel_sram_read_reg[19:16]+curr_sel_sram_read_reg[23:20])+(curr_sel_sram_read_reg[27:24]+curr_sel_sram_read_reg[31:28]))+
						 ((curr_sel_sram_read_reg[35:32]+curr_sel_sram_read_reg[39:36])+(curr_sel_sram_read_reg[43:40]+curr_sel_sram_read_reg[47:44]))+
						 ((curr_sel_sram_read_reg[51:48]+curr_sel_sram_read_reg[55:52])+(curr_sel_sram_read_reg[59:56]+curr_sel_sram_read_reg[63:60]));
	end
	else
		type23_in_data = 0;
end


//win10_curr_val
always@(*)begin
	if(state_cs==FIND_RANGE)
		win10_curr_val =type23_shift_reg[0] *1 +type23_shift_reg[1]*16 +type23_shift_reg[2]*9 +type23_shift_reg[3]*4+type23_shift_reg[4]*1+
						type23_shift_reg[5] *1 +type23_shift_reg[6]*16 +type23_shift_reg[7]*9 +type23_shift_reg[8]*4+type23_shift_reg[9]*1;
	else
		win10_curr_val = 0;
end
//win10_max_val
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		win10_max_val<=0;
	else if(state_ns==IDLE)
		win10_max_val<=0;
	else if(state_cs==FIND_RANGE && counter>=10 && win10_curr_val>win10_max_val)
		win10_max_val<=win10_curr_val;
end
//win10_max_dist
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		win10_max_dist<=1;
	else if(state_ns==IDLE)
		win10_max_dist<=1;
	else if(state_cs==FIND_RANGE && counter3>=10 && win10_curr_val>win10_max_val)
		win10_max_dist<=counter3-9;
end


//====================
// SRAM control
//====================

//wen
always@(*)begin
	if(state_ns==RD_DRAM)begin
		case(read_counter[5:4])
			0:begin
				mem_wen[0] = 0;
				mem_wen[1] = 1;
				mem_wen[2] = 1;
				mem_wen[3] = 1;
			end
			1:begin
				mem_wen[0] = 1;
				mem_wen[1] = 0;
				mem_wen[2] = 1;
				mem_wen[3] = 1;
			end
			2:begin
				mem_wen[0] = 1;
				mem_wen[1] = 1;
				mem_wen[2] = 0;
				mem_wen[3] = 1;
			end
			3:begin
				mem_wen[0] = 1;
				mem_wen[1] = 1;
				mem_wen[2] = 1;
				mem_wen[3] = 0;
			end
			default:begin
				mem_wen[0] = 1;
				mem_wen[1] = 1;
				mem_wen[2] = 1;
				mem_wen[3] = 1;
			end
		endcase
	end
	else if(state_ns==RD_HIST)begin
		case(counter[1:0])
			0:begin
				mem_wen[0] = 0;
				mem_wen[1] = 1;
				mem_wen[2] = 1;
				mem_wen[3] = 1;
			end
			1:begin
				mem_wen[0] = 1;
				mem_wen[1] = 0;
				mem_wen[2] = 1;
				mem_wen[3] = 1;
			end
			2:begin
				mem_wen[0] = 1;
				mem_wen[1] = 1;
				mem_wen[2] = 0;
				mem_wen[3] = 1;
			end
			3:begin
				mem_wen[0] = 1;
				mem_wen[1] = 1;
				mem_wen[2] = 1;
				mem_wen[3] = 0;
			end
			default:begin
				mem_wen[0] = 1;
				mem_wen[1] = 1;
				mem_wen[2] = 1;
				mem_wen[3] = 1;
			end
		endcase
	end
	else if(state_cs==RD_HIST&&state_ns==WAIT_START)begin
		mem_wen[0] = 1;
		mem_wen[1] = 1;
		mem_wen[2] = 1;
		mem_wen[3] = 0;
	end
	else begin
		mem_wen[0] = 1;
		mem_wen[1] = 1;
		mem_wen[2] = 1;
		mem_wen[3] = 1;
	end
end




wire [7:0]tmp_addr = round_max_dist+counter2;
wire [7:0]tmp_addr2 = round_max_dist+counter4;
reg [63:0] type23_curr_mem;
// round_max_dist
always@(*)begin
	if(counter3==0)
		round_max_dist = win10_max_dist-10;
	else if(counter3==1)
		round_max_dist = win10_max_dist-5;
	else
		round_max_dist = win10_max_dist;
end
// type23_curr_mem
always@(*)begin
	if(state_ns==FIND_CAVE || state_ns==FIND_VEX)begin
		case(tmp_addr2[1:0])
			0:type23_curr_mem = sram_read_reg[0];
			1:type23_curr_mem = sram_read_reg[1];
			2:type23_curr_mem = sram_read_reg[2];
			3:type23_curr_mem = sram_read_reg[3];
		endcase
	end
	else
		type23_curr_mem = 0;
end


//addr
always@(*)begin
	// MODE1
	if(state_ns==RD_DRAM) begin
		mem_address[0]={read_counter[7:6],read_counter[3:0]};
		mem_address[1]={read_counter[7:6],read_counter[3:0]};
		mem_address[2]={read_counter[7:6],read_counter[3:0]};
		mem_address[3]={read_counter[7:6],read_counter[3:0]};
	end	
	else if(state_ns==TYPE0_OP|| state_ns==WAIT_IDLE0 || state_ns==WR_DRAM || state_ns==IDLE2)begin
		mem_address[0] = {round_counter[1:0],counter[7:4]};
		mem_address[1] = {round_counter[1:0],counter[7:4]};
		mem_address[2] = {round_counter[1:0],counter[7:4]};
		mem_address[3] = {round_counter[1:0],counter[7:4]};
	end
	else if(state_ns==RD_HIST)begin
		case(counter[1:0])
			0:begin
				mem_address[0]=counter[7:2];
				mem_address[1]=counter[7:2];
				mem_address[2]=counter[7:2];
				mem_address[3]=counter[7:2];
			end
			1:begin
				mem_address[0]=counter[7:2];
				mem_address[1]=counter[7:2];
				mem_address[2]=counter[7:2];
				mem_address[3]=counter[7:2];
			end
			2:begin
				mem_address[0]=counter[7:2];
				mem_address[1]=counter[7:2];
				mem_address[2]=counter[7:2];
				mem_address[3]=counter[7:2];
			end
			3:begin
				mem_address[0]=counter[7:2]+1;
				mem_address[1]=counter[7:2];
				mem_address[2]=counter[7:2];
				mem_address[3]=counter[7:2];
			end
			default:begin
				mem_address[0]=counter[7:2];
				mem_address[1]=counter[7:2];
				mem_address[2]=counter[7:2];
				mem_address[3]=counter[7:2];
			end
		endcase
	end	
	else if(state_cs==RD_HIST && state_ns==WAIT_START)begin
		mem_address[0]=counter[7:2];
		mem_address[1]=counter[7:2];
		mem_address[2]=counter[7:2];
		mem_address[3]=counter[7:2];
	end
	else if(state_cs==TYPE1_OP)begin
		mem_address[0] = {counter2[7:2]};
		mem_address[1] = {counter2[7:2]};
		mem_address[2] = {counter2[7:2]};
		mem_address[3] = {counter2[7:2]};
	end
	else if(state_ns==WR_DRAM_HIST)begin
		mem_address[0] = {counter2[7:0]};
		mem_address[1] = {counter2[7:0]};
		mem_address[2] = {counter2[7:0]};
		mem_address[3] = {counter2[7:0]};
	end
	else if(state_cs==FIND_RANGE)begin
		mem_address[0] = {counter2[7:2]};
		mem_address[1] = {counter2[7:2]};
		mem_address[2] = {counter2[7:2]};
		mem_address[3] = {counter2[7:2]};
	end
	else if(state_cs==FIND_CAVE || state_cs==FIND_VEX || state_cs==IDLE6 || state_cs==IDLE7 || state_cs==IDLE_FIND_CAVE || state_cs==IDLE_FIND_VEX)begin
		mem_address[0] = tmp_addr/4;
		mem_address[1] = tmp_addr/4;
		mem_address[2] = tmp_addr/4;
		mem_address[3] = tmp_addr/4;
	end
	else begin
		mem_address[0] = 0;
		mem_address[1] = 0;
		mem_address[2] = 0;
		mem_address[3] = 0;
	end

end

wire [63:0] short_rdata_m_inf;
assign short_rdata_m_inf = {rdata_m_inf[123:120],
							rdata_m_inf[115:112],
							rdata_m_inf[107:104],
							rdata_m_inf[99 :96 ],
							rdata_m_inf[91 :88 ],
							rdata_m_inf[83 :80 ],
							rdata_m_inf[75 :72 ],
							rdata_m_inf[67 :64 ],
							rdata_m_inf[59 :56 ],
							rdata_m_inf[51 :48 ],
							rdata_m_inf[43 :40 ],
							rdata_m_inf[35 :32 ],
							rdata_m_inf[27 :24 ],
							rdata_m_inf[19 :16 ],
							rdata_m_inf[11 :8  ],
							rdata_m_inf[3  :0  ]};

wire [3:0]his[0:15];
assign his[0] = stop[0];
assign his[1] = stop[1];
assign his[2] = stop[2];
assign his[3] = stop[3];
assign his[4] = stop[4];
assign his[5] = stop[5];
assign his[6] = stop[6];
assign his[7] = stop[7];
assign his[8] = stop[8];
assign his[9] = stop[9];
assign his[10] = stop[10];
assign his[11] = stop[11];
assign his[12] = stop[12];
assign his[13] = stop[13];
assign his[14] = stop[14];
assign his[15] = stop[15];

// mem in
always@(*)begin
	if(state_ns==RD_DRAM)begin
		case(read_counter[5:4])
			0:begin
				D_mem_in[0] = short_rdata_m_inf;
				D_mem_in[1] = 0;
				D_mem_in[2] = 0;
				D_mem_in[3] = 0;
			end
			1:begin
				D_mem_in[0] = 0;
				D_mem_in[1] = short_rdata_m_inf;
				D_mem_in[2] = 0;
				D_mem_in[3] = 0;
			end
			2:begin
				D_mem_in[0] = 0;
				D_mem_in[1] = 0;
				D_mem_in[2] = short_rdata_m_inf;
				D_mem_in[3] = 0;
			end
			3:begin
				D_mem_in[0] = 0;
				D_mem_in[1] = 0;
				D_mem_in[2] = 0;
				D_mem_in[3] = short_rdata_m_inf;
			end
			default:begin
				D_mem_in[0] = 0;
				D_mem_in[1] = 0;
				D_mem_in[2] = 0;
				D_mem_in[3] = 0;
			end
		endcase
	end
	else if(state_ns==RD_HIST)begin
		if(round_counter==0)begin
			case(counter[1:0])
				0:begin
					D_mem_in[0] ={his[15],his[14],his[13],his[12],his[11],his[10],his[9],his[8],his[7],his[6],his[5],his[4],his[3],his[2],his[1],his[0]} ;
					D_mem_in[1] = 0;
					D_mem_in[2] = 0;
					D_mem_in[3] = 0;
				end
				1:begin
					D_mem_in[0] = 0;
					D_mem_in[1] = {his[15],his[14],his[13],his[12],his[11],his[10],his[9],his[8],his[7],his[6],his[5],his[4],his[3],his[2],his[1],his[0]};
					D_mem_in[2] = 0;
					D_mem_in[3] = 0;
				end
				2:begin
					D_mem_in[0] = 0;
					D_mem_in[1] = 0;
					D_mem_in[2] = {his[15],his[14],his[13],his[12],his[11],his[10],his[9],his[8],his[7],his[6],his[5],his[4],his[3],his[2],his[1],his[0]};
					D_mem_in[3] = 0;
				end
				3:begin
					D_mem_in[0] = 0;
					D_mem_in[1] = 0;
					D_mem_in[2] = 0;
					D_mem_in[3] = {his[15],his[14],his[13],his[12],his[11],his[10],his[9],his[8],his[7],his[6],his[5],his[4],his[3],his[2],his[1],his[0]};
				end
				default:begin
					D_mem_in[0] = 0;
					D_mem_in[1] = 0;
					D_mem_in[2] = 0;
					D_mem_in[3] = 0;
				end
			endcase
		end
		else begin
			case(counter[1:0])
				0:begin
					D_mem_in[0] ={his[15]+Q_mem_out[0][63:60],
								his[14]  +Q_mem_out[0][59:56],
								his[13]  +Q_mem_out[0][55:52],
								his[12]  +Q_mem_out[0][51:48],
								his[11]  +Q_mem_out[0][47:44],
								his[10]  +Q_mem_out[0][43:40],
								his[9]   +Q_mem_out[0][39:36],
								his[8]   +Q_mem_out[0][35:32],
								his[7]   +Q_mem_out[0][31:28],
								his[6]   +Q_mem_out[0][27:24],
								his[5]   +Q_mem_out[0][23:20],
								his[4]   +Q_mem_out[0][19:16],
								his[3]   +Q_mem_out[0][15:12],
								his[2]   +Q_mem_out[0][11:8],
								his[1]   +Q_mem_out[0][7:4],
								his[0]   +Q_mem_out[0][3:0]};
					D_mem_in[1] = 0;
					D_mem_in[2] = 0;
					D_mem_in[3] = 0;
				end
				1:begin
					D_mem_in[1] ={his[15]+Q_mem_out[1][63:60],
								his[14]  +Q_mem_out[1][59:56],
								his[13]  +Q_mem_out[1][55:52],
								his[12]  +Q_mem_out[1][51:48],
								his[11]  +Q_mem_out[1][47:44],
								his[10]  +Q_mem_out[1][43:40],
								his[9]   +Q_mem_out[1][39:36],
								his[8]   +Q_mem_out[1][35:32],
								his[7]   +Q_mem_out[1][31:28],
								his[6]   +Q_mem_out[1][27:24],
								his[5]   +Q_mem_out[1][23:20],
								his[4]   +Q_mem_out[1][19:16],
								his[3]   +Q_mem_out[1][15:12],
								his[2]   +Q_mem_out[1][11:8],
								his[1]   +Q_mem_out[1][7:4],
								his[0]   +Q_mem_out[1][3:0]};
					D_mem_in[0] = 0;
					D_mem_in[2] = 0;
					D_mem_in[3] = 0;
				end
				2:begin
					D_mem_in[2] ={his[15]+Q_mem_out[2][63:60],
								his[14]  +Q_mem_out[2][59:56],
								his[13]  +Q_mem_out[2][55:52],
								his[12]  +Q_mem_out[2][51:48],
								his[11]  +Q_mem_out[2][47:44],
								his[10]  +Q_mem_out[2][43:40],
								his[9]   +Q_mem_out[2][39:36],
								his[8]   +Q_mem_out[2][35:32],
								his[7]   +Q_mem_out[2][31:28],
								his[6]   +Q_mem_out[2][27:24],
								his[5]   +Q_mem_out[2][23:20],
								his[4]   +Q_mem_out[2][19:16],
								his[3]   +Q_mem_out[2][15:12],
								his[2]   +Q_mem_out[2][11:8],
								his[1]   +Q_mem_out[2][7:4],
								his[0]   +Q_mem_out[2][3:0]};
					D_mem_in[1] = 0;
					D_mem_in[0] = 0;
					D_mem_in[3] = 0;
				end
				3:begin
					D_mem_in[3] ={his[15]+Q_mem_out[3][63:60],
								his[14]  +Q_mem_out[3][59:56],
								his[13]  +Q_mem_out[3][55:52],
								his[12]  +Q_mem_out[3][51:48],
								his[11]  +Q_mem_out[3][47:44],
								his[10]  +Q_mem_out[3][43:40],
								his[9]   +Q_mem_out[3][39:36],
								his[8]   +Q_mem_out[3][35:32],
								his[7]   +Q_mem_out[3][31:28],
								his[6]   +Q_mem_out[3][27:24],
								his[5]   +Q_mem_out[3][23:20],
								his[4]   +Q_mem_out[3][19:16],
								his[3]   +Q_mem_out[3][15:12],
								his[2]   +Q_mem_out[3][11:8],
								his[1]   +Q_mem_out[3][7:4],
								his[0]   +Q_mem_out[3][3:0]};
					D_mem_in[1] = 0;
					D_mem_in[2] = 0;
					D_mem_in[0] = 0;
				end

				default:begin
					D_mem_in[0] = 0;
					D_mem_in[1] = 0;
					D_mem_in[2] = 0;
					D_mem_in[3] = 0;
				end
			endcase
		end	
	end
	
	else
		for(i=0;i<4;i=i+1)
			D_mem_in[i] = 0;
end


//====================
// Traverse
//====================

reg [13:0] type23_curr_win_val;
reg [13:0] type23_max_win_val;

reg [5:0]type23_val_sel;
wire [3:0]type23_curr_mem2[0:15];
//type23_peak_type
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		type23_peak_type<=0;
	else if((state_ns==IDLE_FIND_CAVE) &&  type23_curr_win_val>type23_max_win_val)
		type23_peak_type<={1'b1,round_counter[3:0],counter3[1:0]};
	else if((state_ns==IDLE_FIND_VEX) && type23_curr_win_val>type23_max_win_val)
		type23_peak_type<={1'b0,round_counter[3:0],counter3[1:0]};
end
//type23_max_win_val
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		type23_max_win_val<=0;
	else if(state_ns==IDLE)
		type23_max_win_val<=0;
	else if((state_ns==IDLE_FIND_CAVE || state_ns==IDLE_FIND_VEX) && type23_curr_win_val>type23_max_win_val)
		type23_max_win_val<=type23_curr_win_val;
end	
//type23_curr_win_val
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		type23_curr_win_val<=0;
	else if(state_ns==IDLE_FIND_CAVE || state_ns==IDLE_FIND_VEX)
		type23_curr_win_val<=0;
	else if(state_ns==FIND_CAVE || state_ns==FIND_VEX)begin
		if(counter==0 || counter==5 || counter==10 || counter==15)
			type23_curr_win_val<= type23_curr_win_val + type23_val_sel;
		else if(counter==1 || counter==6 || counter==11 || counter==16)
			type23_curr_win_val<= type23_curr_win_val + type23_val_sel * 16;
		else if(counter==2 || counter==7 || counter==12 || counter==17)
			type23_curr_win_val<= type23_curr_win_val + type23_val_sel * 9;
		else if(counter==3 || counter==8 || counter==13 || counter==18)
			type23_curr_win_val<= type23_curr_win_val + type23_val_sel * 4;
		else
			type23_curr_win_val<= type23_curr_win_val + type23_val_sel;
	end
end

assign type23_curr_mem2[0 ] = type23_curr_mem[3 :0 ];
assign type23_curr_mem2[1 ] = type23_curr_mem[7 :4 ];
assign type23_curr_mem2[2 ] = type23_curr_mem[11:8 ];
assign type23_curr_mem2[3 ] = type23_curr_mem[15:12];
assign type23_curr_mem2[4 ] = type23_curr_mem[19:16];
assign type23_curr_mem2[5 ] = type23_curr_mem[23:20];
assign type23_curr_mem2[6 ] = type23_curr_mem[27:24];
assign type23_curr_mem2[7 ] = type23_curr_mem[31:28];
assign type23_curr_mem2[8 ] = type23_curr_mem[35:32];
assign type23_curr_mem2[9 ] = type23_curr_mem[39:36];
assign type23_curr_mem2[10] = type23_curr_mem[43:40];
assign type23_curr_mem2[11] = type23_curr_mem[47:44];
assign type23_curr_mem2[12] = type23_curr_mem[51:48];
assign type23_curr_mem2[13] = type23_curr_mem[55:52];
assign type23_curr_mem2[14] = type23_curr_mem[59:56];
assign type23_curr_mem2[15] = type23_curr_mem[63:60];
//type23_val_sel
always@(*)begin
	if(state_ns==FIND_VEX)begin
		case(round_counter)
			0:begin // peak at 0
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[0];
					 1:type23_val_sel = type23_curr_mem2[0];
					 2:type23_val_sel = type23_curr_mem2[0];
					 3:type23_val_sel = type23_curr_mem2[0];
					 4:type23_val_sel = type23_curr_mem2[0];
					 5:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					 6:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					 7:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					 8:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					 9:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					10:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					11:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					12:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					13:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					14:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					15:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					16:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					17:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					18:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					19:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					default:type23_val_sel=0;
				endcase
			end
			1:begin //peak at 1
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[1];
					 1:type23_val_sel = type23_curr_mem2[1];
					 2:type23_val_sel = type23_curr_mem2[1];
					 3:type23_val_sel = type23_curr_mem2[1];
					 4:type23_val_sel = type23_curr_mem2[1];
					 5:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					 6:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					 7:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					 8:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					 9:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					10:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					11:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					12:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					13:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					14:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					15:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					16:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					17:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					18:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					19:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					default:type23_val_sel=0;
				endcase
			end
			2:begin //peak at 2
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[2];
					 1:type23_val_sel = type23_curr_mem2[2];
					 2:type23_val_sel = type23_curr_mem2[2];
					 3:type23_val_sel = type23_curr_mem2[2];
					 4:type23_val_sel = type23_curr_mem2[2];
					 5:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					 6:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					 7:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					 8:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					 9:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					10:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					11:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					12:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					13:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					14:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					15:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					16:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					17:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					18:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					19:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					default:type23_val_sel=0;
				endcase
			end
			3:begin //peak at 3
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[3];
					 1:type23_val_sel = type23_curr_mem2[3];
					 2:type23_val_sel = type23_curr_mem2[3];
					 3:type23_val_sel = type23_curr_mem2[3];
					 4:type23_val_sel = type23_curr_mem2[3];
					 5:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					 6:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					 7:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					 8:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					 9:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					10:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					11:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					12:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					13:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					14:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					15:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					16:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					17:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					18:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					19:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					default:type23_val_sel=0;
				endcase
			end
			4:begin //peak at 4
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[4];
					 1:type23_val_sel = type23_curr_mem2[4];
					 2:type23_val_sel = type23_curr_mem2[4];
					 3:type23_val_sel = type23_curr_mem2[4];
					 4:type23_val_sel = type23_curr_mem2[4];
					 5:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					 6:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					 7:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					 8:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					 9:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					10:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					11:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					12:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					13:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					14:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					15:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					16:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					17:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					18:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					19:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					default:type23_val_sel=0;
				endcase
			end
			5:begin //peak at 5
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[5];
					 1:type23_val_sel = type23_curr_mem2[5];
					 2:type23_val_sel = type23_curr_mem2[5];
					 3:type23_val_sel = type23_curr_mem2[5];
					 4:type23_val_sel = type23_curr_mem2[5];
					 5:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					 6:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					 7:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					 8:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					 9:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					10:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					11:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					12:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					13:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					14:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					15:type23_val_sel = 0;
					16:type23_val_sel = 0;
					17:type23_val_sel = 0;
					18:type23_val_sel = 0;
					19:type23_val_sel = 0;
					default:type23_val_sel=0;
				endcase
			end
			6:begin //peak at 6
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[6];
					 1:type23_val_sel = type23_curr_mem2[6];
					 2:type23_val_sel = type23_curr_mem2[6];
					 3:type23_val_sel = type23_curr_mem2[6];
					 4:type23_val_sel = type23_curr_mem2[6];
					 5:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 6:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 7:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 8:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 9:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					10:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					11:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					12:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					13:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					14:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					15:type23_val_sel = 0;
					16:type23_val_sel = 0;
					17:type23_val_sel = 0;
					18:type23_val_sel = 0;
					19:type23_val_sel = 0;
					default:type23_val_sel=0;
				endcase
			end
			7:begin //peak at 7
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[7];
					 1:type23_val_sel = type23_curr_mem2[7];
					 2:type23_val_sel = type23_curr_mem2[7];
					 3:type23_val_sel = type23_curr_mem2[7];
					 4:type23_val_sel = type23_curr_mem2[7];
					 5:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 6:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 7:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 8:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 9:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					10:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					11:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					12:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					13:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					14:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					15:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					16:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					17:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					18:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					19:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					default:type23_val_sel=0;
				endcase
			end
			8:begin //peak at 8
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[8];
					 1:type23_val_sel = type23_curr_mem2[8];
					 2:type23_val_sel = type23_curr_mem2[8];
					 3:type23_val_sel = type23_curr_mem2[8];
					 4:type23_val_sel = type23_curr_mem2[8];
					 5:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					 6:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					 7:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					 8:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					 9:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					10:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					11:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					12:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					13:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					14:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					15:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					16:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					17:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					18:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					19:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					default:type23_val_sel=0;
				endcase
			end
			9:begin //peak at 9
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[9];
					 1:type23_val_sel = type23_curr_mem2[9];
					 2:type23_val_sel = type23_curr_mem2[9];
					 3:type23_val_sel = type23_curr_mem2[9];
					 4:type23_val_sel = type23_curr_mem2[9];
					 5:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					 6:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					 7:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					 8:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					 9:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					10:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					11:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					12:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					13:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					14:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					15:type23_val_sel = 0;
					16:type23_val_sel = 0;
					17:type23_val_sel = 0;
					18:type23_val_sel = 0;
					19:type23_val_sel = 0;
					default:type23_val_sel=0;
				endcase
			end
			10:begin //peak at 10
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[10];
					 1:type23_val_sel = type23_curr_mem2[10];
					 2:type23_val_sel = type23_curr_mem2[10];
					 3:type23_val_sel = type23_curr_mem2[10];
					 4:type23_val_sel = type23_curr_mem2[10];
					 5:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 6:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 7:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 8:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 9:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					10:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					11:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					12:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					13:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					14:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					15:type23_val_sel = 0;
					16:type23_val_sel = 0;
					17:type23_val_sel = 0;
					18:type23_val_sel = 0;
					19:type23_val_sel = 0;
					default:type23_val_sel=0;
				endcase
			end
			11:begin //peak at 11
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[11];
					 1:type23_val_sel = type23_curr_mem2[11];
					 2:type23_val_sel = type23_curr_mem2[11];
					 3:type23_val_sel = type23_curr_mem2[11];
					 4:type23_val_sel = type23_curr_mem2[11];
					 5:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 6:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 7:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 8:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 9:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					10:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					11:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					12:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					13:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					14:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					15:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					16:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					17:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					18:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					19:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					default:type23_val_sel=0;
				endcase
			end
			12:begin //peak at 12
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[12];
					 1:type23_val_sel = type23_curr_mem2[12];
					 2:type23_val_sel = type23_curr_mem2[12];
					 3:type23_val_sel = type23_curr_mem2[12];
					 4:type23_val_sel = type23_curr_mem2[12];
					 5:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 6:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 7:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 8:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 9:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					10:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					11:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					12:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					13:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					14:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					15:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					16:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					17:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					18:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					19:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					default:type23_val_sel=0;
				endcase
			end
			13:begin //peak at 13
				case(counter)
					 0:type23_val_sel = type23_curr_mem2[13];
					 1:type23_val_sel = type23_curr_mem2[13];
					 2:type23_val_sel = type23_curr_mem2[13];
					 3:type23_val_sel = type23_curr_mem2[13];
					 4:type23_val_sel = type23_curr_mem2[13];
					 5:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					 6:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					 7:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					 8:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					 9:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					10:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					11:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					12:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					13:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					14:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					15:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					16:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					17:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					18:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					19:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					default:type23_val_sel=0;
				endcase
			end
			14:begin //peak at 14
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[14];
					 1:type23_val_sel = type23_curr_mem2[14];
					 2:type23_val_sel = type23_curr_mem2[14];
					 3:type23_val_sel = type23_curr_mem2[14];
					 4:type23_val_sel = type23_curr_mem2[14];
					 5:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					 6:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					 7:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					 8:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					 9:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					10:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					11:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					12:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					13:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					14:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					15:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					16:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					17:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					18:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					19:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					default:type23_val_sel=0;
				endcase
			end
			15:begin //peak at 15
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[15];
					 1:type23_val_sel = type23_curr_mem2[15];
					 2:type23_val_sel = type23_curr_mem2[15];
					 3:type23_val_sel = type23_curr_mem2[15];
					 4:type23_val_sel = type23_curr_mem2[15];
					 5:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					 6:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					 7:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					 8:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					 9:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					10:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					11:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					12:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					13:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					14:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					15:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					16:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					17:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					18:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					19:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					default:type23_val_sel=0;
				endcase
			end
			default: type23_val_sel = 0;
		endcase
	end
	else if(state_ns==FIND_CAVE)begin
		case(round_counter)
			0:begin // peak at 0
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 1:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 2:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 3:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 4:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 5:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					 6:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					 7:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					 8:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					 9:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					10:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					11:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					12:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					13:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					14:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[4]+type23_curr_mem2[5];
					15:type23_val_sel = type23_curr_mem2[0];
					16:type23_val_sel = type23_curr_mem2[0];
					17:type23_val_sel = type23_curr_mem2[0];
					18:type23_val_sel = type23_curr_mem2[0];
					19:type23_val_sel = type23_curr_mem2[0];
					default:type23_val_sel=0;
				endcase
			end
			1:begin // peak at 1
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 1:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 2:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 3:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 4:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 5:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 6:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 7:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 8:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 9:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					10:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					11:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					12:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					13:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					14:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6];
					15:type23_val_sel = type23_curr_mem2[1];
					16:type23_val_sel = type23_curr_mem2[1];
					17:type23_val_sel = type23_curr_mem2[1];
					18:type23_val_sel = type23_curr_mem2[1];
					19:type23_val_sel = type23_curr_mem2[1];
					default:type23_val_sel=0;
				endcase
			end
			2:begin // peak at 2
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 1:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 2:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 3:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 4:type23_val_sel = type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 5:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 6:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 7:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 8:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 9:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					10:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					11:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					12:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					13:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					14:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7];
					15:type23_val_sel = type23_curr_mem2[2];
					16:type23_val_sel = type23_curr_mem2[2];
					17:type23_val_sel = type23_curr_mem2[2];
					18:type23_val_sel = type23_curr_mem2[2];
					19:type23_val_sel = type23_curr_mem2[2];
					default:type23_val_sel=0;
				endcase
			end
			3:begin // peak at 3
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 1:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 2:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 3:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 4:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 5:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 6:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 7:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 8:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					 9:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					10:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					11:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					12:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					13:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					14:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[7];
					15:type23_val_sel = type23_curr_mem2[3];
					16:type23_val_sel = type23_curr_mem2[3];
					17:type23_val_sel = type23_curr_mem2[3];
					18:type23_val_sel = type23_curr_mem2[3];
					19:type23_val_sel = type23_curr_mem2[3];
					default:type23_val_sel=0;
				endcase
			end
			4:begin // peak at 4
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 1:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 2:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 3:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 4:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 5:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					 6:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					 7:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					 8:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					 9:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					10:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					11:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					12:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					13:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					14:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[8]+type23_curr_mem2[9];
					15:type23_val_sel = type23_curr_mem2[4];
					16:type23_val_sel = type23_curr_mem2[4];
					17:type23_val_sel = type23_curr_mem2[4];
					18:type23_val_sel = type23_curr_mem2[4];
					19:type23_val_sel = type23_curr_mem2[4];
					default:type23_val_sel=0;
				endcase
			end
			5:begin
				case(counter4)
					 0:type23_val_sel = 0;
					 1:type23_val_sel = 0;
					 2:type23_val_sel = 0;
					 3:type23_val_sel = 0;
					 4:type23_val_sel = 0;
					 5:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 6:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 7:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 8:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 9:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					10:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					11:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					12:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					13:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					14:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[4]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10];
					15:type23_val_sel = type23_curr_mem2[5];
					16:type23_val_sel = type23_curr_mem2[5];
					17:type23_val_sel = type23_curr_mem2[5];
					18:type23_val_sel = type23_curr_mem2[5];
					19:type23_val_sel = type23_curr_mem2[5];
					default:type23_val_sel=0;
				endcase
			end
			6:begin
				case(counter4)
					 0:type23_val_sel = 0;
					 1:type23_val_sel = 0;
					 2:type23_val_sel = 0;
					 3:type23_val_sel = 0;
					 4:type23_val_sel = 0;
					 5:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 6:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 7:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 8:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 9:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					10:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					11:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					12:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					13:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					14:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11];
					15:type23_val_sel = type23_curr_mem2[6];
					16:type23_val_sel = type23_curr_mem2[6];
					17:type23_val_sel = type23_curr_mem2[6];
					18:type23_val_sel = type23_curr_mem2[6];
					19:type23_val_sel = type23_curr_mem2[6];
					default:type23_val_sel=0;
				endcase
			end
			7:begin // peak at 7
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 1:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 2:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 3:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 4:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 5:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 6:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 7:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 8:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					 9:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					10:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					11:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					12:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					13:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					14:type23_val_sel = type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[11];
					15:type23_val_sel = type23_curr_mem2[7];
					16:type23_val_sel = type23_curr_mem2[7];
					17:type23_val_sel = type23_curr_mem2[7];
					18:type23_val_sel = type23_curr_mem2[7];
					19:type23_val_sel = type23_curr_mem2[7];
					default:type23_val_sel=0;
				endcase
			end
			8:begin // peak at 8
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 1:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 2:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 3:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 4:type23_val_sel = type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 5:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					 6:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					 7:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					 8:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					 9:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					10:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					11:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					12:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					13:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					14:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[12]+type23_curr_mem2[13];
					15:type23_val_sel = type23_curr_mem2[8];
					16:type23_val_sel = type23_curr_mem2[8];
					17:type23_val_sel = type23_curr_mem2[8];
					18:type23_val_sel = type23_curr_mem2[8];
					19:type23_val_sel = type23_curr_mem2[8];
					default:type23_val_sel=0;
				endcase
			end
			9:begin
				case(counter4)
					 0:type23_val_sel = 0;
					 1:type23_val_sel = 0;
					 2:type23_val_sel = 0;
					 3:type23_val_sel = 0;
					 4:type23_val_sel = 0;
					 5:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 6:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 7:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 8:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 9:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					10:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					11:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					12:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					13:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					14:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[8]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[13]+type23_curr_mem2[14];
					15:type23_val_sel = type23_curr_mem2[9];
					16:type23_val_sel = type23_curr_mem2[9];
					17:type23_val_sel = type23_curr_mem2[9];
					18:type23_val_sel = type23_curr_mem2[9];
					19:type23_val_sel = type23_curr_mem2[9];
					default:type23_val_sel=0;
				endcase
			end
			10:begin
				case(counter4)
					 0:type23_val_sel = 0;
					 1:type23_val_sel = 0;
					 2:type23_val_sel = 0;
					 3:type23_val_sel = 0;
					 4:type23_val_sel = 0;
					 5:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 6:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 7:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 8:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 9:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					10:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					11:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					12:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					13:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					14:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[14]+type23_curr_mem2[15];
					15:type23_val_sel = type23_curr_mem2[10];
					16:type23_val_sel = type23_curr_mem2[10];
					17:type23_val_sel = type23_curr_mem2[10];
					18:type23_val_sel = type23_curr_mem2[10];
					19:type23_val_sel = type23_curr_mem2[10];
					default:type23_val_sel=0;
				endcase
			end
			11:begin // peak at 11
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 1:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 2:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 3:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 4:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 5:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 6:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 7:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 8:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 9:type23_val_sel = type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[5]+type23_curr_mem2[9]+type23_curr_mem2[13];
					10:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					11:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					12:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					13:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					14:type23_val_sel = type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[10]+type23_curr_mem2[14]+type23_curr_mem2[15];
					15:type23_val_sel = type23_curr_mem2[11];
					16:type23_val_sel = type23_curr_mem2[11];
					17:type23_val_sel = type23_curr_mem2[11];
					18:type23_val_sel = type23_curr_mem2[11];
					19:type23_val_sel = type23_curr_mem2[11];
					default:type23_val_sel=0;
				endcase
			end
			12:begin // peak at 12
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 1:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 2:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 3:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 4:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 5:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					 6:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					 7:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					 8:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					 9:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[10]+type23_curr_mem2[14];
					10:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					11:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					12:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					13:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					14:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[13];
					15:type23_val_sel = type23_curr_mem2[12];
					16:type23_val_sel = type23_curr_mem2[12];
					17:type23_val_sel = type23_curr_mem2[12];
					18:type23_val_sel = type23_curr_mem2[12];
					19:type23_val_sel = type23_curr_mem2[12];
					default:type23_val_sel=0;
				endcase
			end
			13:begin // peak at 13
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 1:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 2:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 3:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 4:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 5:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 6:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 7:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 8:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					 9:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[11]+type23_curr_mem2[15];
					10:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					11:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					12:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					13:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					14:type23_val_sel = type23_curr_mem2[8]+type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[12]+type23_curr_mem2[14];
					15:type23_val_sel = type23_curr_mem2[13];
					16:type23_val_sel = type23_curr_mem2[13];
					17:type23_val_sel = type23_curr_mem2[13];
					18:type23_val_sel = type23_curr_mem2[13];
					19:type23_val_sel = type23_curr_mem2[13];
					default:type23_val_sel=0;
				endcase
			end
			14:begin // peak at 14
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 1:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 2:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 3:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 4:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3];
					 5:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 6:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 7:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 8:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 9:type23_val_sel = type23_curr_mem2[4]+type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[8]+type23_curr_mem2[12];
					10:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					11:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					12:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					13:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					14:type23_val_sel = type23_curr_mem2[9]+type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[13]+type23_curr_mem2[15];
					15:type23_val_sel = type23_curr_mem2[14];
					16:type23_val_sel = type23_curr_mem2[14];
					17:type23_val_sel = type23_curr_mem2[14];
					18:type23_val_sel = type23_curr_mem2[14];
					19:type23_val_sel = type23_curr_mem2[14];
					default:type23_val_sel=0;
				endcase
			end
			15:begin // peak at 15
				case(counter4)
					 0:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 1:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 2:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 3:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 4:type23_val_sel = type23_curr_mem2[0]+type23_curr_mem2[1]+type23_curr_mem2[2]+type23_curr_mem2[3]+type23_curr_mem2[4]+type23_curr_mem2[8]+type23_curr_mem2[12];
					 5:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 6:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 7:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 8:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					 9:type23_val_sel = type23_curr_mem2[5]+type23_curr_mem2[6]+type23_curr_mem2[7]+type23_curr_mem2[9]+type23_curr_mem2[13];
					10:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					11:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					12:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					13:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					14:type23_val_sel = type23_curr_mem2[10]+type23_curr_mem2[11]+type23_curr_mem2[14];
					15:type23_val_sel = type23_curr_mem2[15];
					16:type23_val_sel = type23_curr_mem2[15];
					17:type23_val_sel = type23_curr_mem2[15];
					18:type23_val_sel = type23_curr_mem2[15];
					19:type23_val_sel = type23_curr_mem2[15];
					default:type23_val_sel=0;
				endcase
			end
			default: type23_val_sel = 0;
		endcase
	end
	else
		type23_val_sel = 0;
end

//type23_coeff
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<16;i=i+1)
			type23_coeff[i]<=0;
	else if(state_ns==IDLE8)begin
			case(type23_peak_type[5:2])
				0 :begin
					type23_coeff[0 ]<=0;
					type23_coeff[1 ]<=1;
					type23_coeff[2 ]<=2;
					type23_coeff[3 ]<=3;
					type23_coeff[4 ]<=1;
					type23_coeff[5 ]<=1;
					type23_coeff[6 ]<=2;
					type23_coeff[7 ]<=3;
					type23_coeff[8 ]<=2;
					type23_coeff[9 ]<=2;
					type23_coeff[10]<=2;
					type23_coeff[11]<=3;
					type23_coeff[12]<=3;
					type23_coeff[13]<=3;
					type23_coeff[14]<=3;
					type23_coeff[15]<=3;
				end
				1 :begin
					type23_coeff[0 ]<=1;
					type23_coeff[1 ]<=0;
					type23_coeff[2 ]<=1;
					type23_coeff[3 ]<=2;
					type23_coeff[4 ]<=1;
					type23_coeff[5 ]<=1;
					type23_coeff[6 ]<=1;
					type23_coeff[7 ]<=2;
					type23_coeff[8 ]<=2;
					type23_coeff[9 ]<=2;
					type23_coeff[10]<=2;
					type23_coeff[11]<=2;
					type23_coeff[12]<=3;
					type23_coeff[13]<=3;
					type23_coeff[14]<=3;
					type23_coeff[15]<=3;
				end
				2 :begin
					type23_coeff[0 ]<=2;
					type23_coeff[1 ]<=1;
					type23_coeff[2 ]<=0;
					type23_coeff[3 ]<=1;
					type23_coeff[4 ]<=2;
					type23_coeff[5 ]<=1;
					type23_coeff[6 ]<=1;
					type23_coeff[7 ]<=1;
					type23_coeff[8 ]<=2;
					type23_coeff[9 ]<=2;
					type23_coeff[10]<=2;
					type23_coeff[11]<=2;
					type23_coeff[12]<=3;
					type23_coeff[13]<=3;
					type23_coeff[14]<=3;
					type23_coeff[15]<=3;
				end
				3 :begin
					type23_coeff[0 ]<=3;
					type23_coeff[1 ]<=2;
					type23_coeff[2 ]<=1;
					type23_coeff[3 ]<=0;
					type23_coeff[4 ]<=3;
					type23_coeff[5 ]<=2;
					type23_coeff[6 ]<=1;
					type23_coeff[7 ]<=1;
					type23_coeff[8 ]<=3;
					type23_coeff[9 ]<=2;
					type23_coeff[10]<=2;
					type23_coeff[11]<=2;
					type23_coeff[12]<=3;
					type23_coeff[13]<=3;
					type23_coeff[14]<=3;
					type23_coeff[15]<=3;
				end
				4 :begin
					type23_coeff[0 ]<=1;
					type23_coeff[1 ]<=1;
					type23_coeff[2 ]<=2;
					type23_coeff[3 ]<=3;
					type23_coeff[4 ]<=0;
					type23_coeff[5 ]<=1;
					type23_coeff[6 ]<=2;
					type23_coeff[7 ]<=3;
					type23_coeff[8 ]<=1;
					type23_coeff[9 ]<=1;
					type23_coeff[10]<=2;
					type23_coeff[11]<=3;
					type23_coeff[12]<=2;
					type23_coeff[13]<=2;
					type23_coeff[14]<=2;
					type23_coeff[15]<=3;
				end
				5 :begin
					type23_coeff[0 ]<=1;
					type23_coeff[1 ]<=1;
					type23_coeff[2 ]<=1;
					type23_coeff[3 ]<=2;
					type23_coeff[4 ]<=1;
					type23_coeff[5 ]<=0;
					type23_coeff[6 ]<=1;
					type23_coeff[7 ]<=2;
					type23_coeff[8 ]<=1;
					type23_coeff[9 ]<=1;
					type23_coeff[10]<=1;
					type23_coeff[11]<=2;
					type23_coeff[12]<=2;
					type23_coeff[13]<=2;
					type23_coeff[14]<=2;
					type23_coeff[15]<=2;
				end
				6 :begin
					type23_coeff[0 ]<=2;
					type23_coeff[1 ]<=1;
					type23_coeff[2 ]<=1;
					type23_coeff[3 ]<=1;
					type23_coeff[4 ]<=2;
					type23_coeff[5 ]<=1;
					type23_coeff[6 ]<=0;
					type23_coeff[7 ]<=1;
					type23_coeff[8 ]<=2;
					type23_coeff[9 ]<=1;
					type23_coeff[10]<=1;
					type23_coeff[11]<=1;
					type23_coeff[12]<=2;
					type23_coeff[13]<=2;
					type23_coeff[14]<=2;
					type23_coeff[15]<=2;
				end
				7 :begin
					type23_coeff[0 ]<=3;
					type23_coeff[1 ]<=2;
					type23_coeff[2 ]<=1;
					type23_coeff[3 ]<=1;
					type23_coeff[4 ]<=3;
					type23_coeff[5 ]<=2;
					type23_coeff[6 ]<=1;
					type23_coeff[7 ]<=0;
					type23_coeff[8 ]<=3;
					type23_coeff[9 ]<=2;
					type23_coeff[10]<=1;
					type23_coeff[11]<=1;
					type23_coeff[12]<=3;
					type23_coeff[13]<=2;
					type23_coeff[14]<=2;
					type23_coeff[15]<=2;
				end
				8 :begin
					type23_coeff[0 ]<=2;
					type23_coeff[1 ]<=2;
					type23_coeff[2 ]<=2;
					type23_coeff[3 ]<=3;
					type23_coeff[4 ]<=1;
					type23_coeff[5 ]<=1;
					type23_coeff[6 ]<=2;
					type23_coeff[7 ]<=3;
					type23_coeff[8 ]<=0;
					type23_coeff[9 ]<=1;
					type23_coeff[10]<=2;
					type23_coeff[11]<=3;
					type23_coeff[12]<=1;
					type23_coeff[13]<=1;
					type23_coeff[14]<=2;
					type23_coeff[15]<=3;
				end
				9 :begin
					type23_coeff[0 ]<=2;
					type23_coeff[1 ]<=2;
					type23_coeff[2 ]<=2;
					type23_coeff[3 ]<=2;
					type23_coeff[4 ]<=1;
					type23_coeff[5 ]<=1;
					type23_coeff[6 ]<=1;
					type23_coeff[7 ]<=2;
					type23_coeff[8 ]<=1;
					type23_coeff[9 ]<=0;
					type23_coeff[10]<=1;
					type23_coeff[11]<=2;
					type23_coeff[12]<=1;
					type23_coeff[13]<=1;
					type23_coeff[14]<=1;
					type23_coeff[15]<=2;
				end
				10:begin
					type23_coeff[0 ]<=2;
					type23_coeff[1 ]<=2;
					type23_coeff[2 ]<=2;
					type23_coeff[3 ]<=2;
					type23_coeff[4 ]<=2;
					type23_coeff[5 ]<=1;
					type23_coeff[6 ]<=1;
					type23_coeff[7 ]<=1;
					type23_coeff[8 ]<=2;
					type23_coeff[9 ]<=1;
					type23_coeff[10]<=0;
					type23_coeff[11]<=1;
					type23_coeff[12]<=2;
					type23_coeff[13]<=1;
					type23_coeff[14]<=1;
					type23_coeff[15]<=1;
				end
				11:begin
					type23_coeff[0 ]<=3;
					type23_coeff[1 ]<=2;
					type23_coeff[2 ]<=2;
					type23_coeff[3 ]<=2;
					type23_coeff[4 ]<=3;
					type23_coeff[5 ]<=2;
					type23_coeff[6 ]<=1;
					type23_coeff[7 ]<=1;
					type23_coeff[8 ]<=3;
					type23_coeff[9 ]<=2;
					type23_coeff[10]<=1;
					type23_coeff[11]<=0;
					type23_coeff[12]<=3;
					type23_coeff[13]<=2;
					type23_coeff[14]<=1;
					type23_coeff[15]<=1;
				end
				12:begin
					type23_coeff[0 ]<=3;
					type23_coeff[1 ]<=3;
					type23_coeff[2 ]<=3;
					type23_coeff[3 ]<=3;
					type23_coeff[4 ]<=2;
					type23_coeff[5 ]<=2;
					type23_coeff[6 ]<=2;
					type23_coeff[7 ]<=3;
					type23_coeff[8 ]<=1;
					type23_coeff[9 ]<=1;
					type23_coeff[10]<=2;
					type23_coeff[11]<=3;
					type23_coeff[12]<=0;
					type23_coeff[13]<=1;
					type23_coeff[14]<=2;
					type23_coeff[15]<=3;
				end
				13:begin
					type23_coeff[0 ]<=3;
					type23_coeff[1 ]<=3;
					type23_coeff[2 ]<=3;
					type23_coeff[3 ]<=3;
					type23_coeff[4 ]<=2;
					type23_coeff[5 ]<=2;
					type23_coeff[6 ]<=2;
					type23_coeff[7 ]<=2;
					type23_coeff[8 ]<=1;
					type23_coeff[9 ]<=1;
					type23_coeff[10]<=1;
					type23_coeff[11]<=2;
					type23_coeff[12]<=1;
					type23_coeff[13]<=0;
					type23_coeff[14]<=1;
					type23_coeff[15]<=2;
				end
				14:begin
					type23_coeff[0 ]<=3;
					type23_coeff[1 ]<=3;
					type23_coeff[2 ]<=3;
					type23_coeff[3 ]<=3;
					type23_coeff[4 ]<=2;
					type23_coeff[5 ]<=2;
					type23_coeff[6 ]<=2;
					type23_coeff[7 ]<=2;
					type23_coeff[8 ]<=2;
					type23_coeff[9 ]<=1;
					type23_coeff[10]<=1;
					type23_coeff[11]<=1;
					type23_coeff[12]<=2;
					type23_coeff[13]<=1;
					type23_coeff[14]<=0;
					type23_coeff[15]<=1;
				end
				15:begin
					type23_coeff[0 ]<=3;
					type23_coeff[1 ]<=3;
					type23_coeff[2 ]<=3;
					type23_coeff[3 ]<=3;
					type23_coeff[4 ]<=3;
					type23_coeff[5 ]<=2;
					type23_coeff[6 ]<=2;
					type23_coeff[7 ]<=2;
					type23_coeff[8 ]<=3;
					type23_coeff[9 ]<=2;
					type23_coeff[10]<=1;
					type23_coeff[11]<=1;
					type23_coeff[12]<=3;
					type23_coeff[13]<=2;
					type23_coeff[14]<=1;
					type23_coeff[15]<=0;
				end
			endcase
	end
end


endmodule



///////////////////////////////////////////////////////////////////////////////////////////


module DRAM_read(
	// global signals 
	   clk, rst_n,
	// axi read address channel 
		araddr_m_inf,	//master
		arlen_m_inf,	//master
		arvalid_m_inf,  //master
		arready_m_inf, 	//slave
	// axi read data channel 
		rdata_m_inf, 	//slave
		rlast_m_inf,	//slave
		rvalid_m_inf,	//slave
		rready_m_inf,	//master
	// in valid
		in_valid,
		curr_addr,
	// out valid
		out_valid,
		counter
);

//================================================================
//  Parameter and Integer                 
//================================================================
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 128;

parameter IDLE = 4'd0;
parameter WAIT_OUTPUT = 4'd1;
parameter RD_HIST = 4'd2;
parameter DONE = 4'd3;


//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
// global signals 
	input   clk, rst_n;
// axi read address channel 
	output reg [ADDR_WIDTH-1:0] araddr_m_inf; //*
	output reg  [7:0]           arlen_m_inf;
	output reg                  arvalid_m_inf;
	input  wire                 arready_m_inf;
// axi read data channel 
	input  wire [DATA_WIDTH-1:0]  rdata_m_inf;
	input  wire                   rlast_m_inf;
	input  wire                  rvalid_m_inf;
	output wire                  rready_m_inf;
// in valid
	input  wire					 in_valid;
	input  wire[31:0] curr_addr;
// out valid
	output wire					 out_valid;
	output reg [7:0]			 counter;
//================================================================
//  Reg and Wire                   
//================================================================
reg [3:0] state_cs,state_ns;

wire doneRD;
assign doneRD = counter==255;
//================================================================
//  FSM                      
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else 
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE: state_ns = arvalid_m_inf?WAIT_OUTPUT:IDLE;
		WAIT_OUTPUT: state_ns = (rready_m_inf && rvalid_m_inf)?RD_HIST:WAIT_OUTPUT;
		RD_HIST: state_ns = doneRD?DONE: RD_HIST;
		DONE: state_ns = IDLE;
		default : state_ns = state_cs;
	endcase
end
//================================================================
//  Design                     
//================================================================
assign out_valid = (state_ns==RD_HIST || state_cs==RD_HIST);
assign add_address = (counter[3:0]==15);
// counter
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_ns==IDLE)
		counter<=0;
	else if(state_ns==RD_HIST)
		counter<=counter+1;
end

// axi4
//assign araddr_m_inf = 8'h0001_0000 ;
assign rready_m_inf = 1 ;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		arlen_m_inf <= 0;
	else
		arlen_m_inf <= 255;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		arvalid_m_inf <= 0;
	else if(state_cs==IDLE && state_ns==WAIT_OUTPUT)
		arvalid_m_inf<=arvalid_m_inf;
	else if(in_valid)
		arvalid_m_inf <= 1;
	else
		arvalid_m_inf <= 0;
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		araddr_m_inf <= 0;
	else 
		araddr_m_inf <= curr_addr;
end

endmodule











module WINDOW_MET_5(
	// global signals
		clk,rst_n,
	// input signals
		in_valid,
		in_data,
		curr_mode,
	// output signals
		out_valid,
		out_dist
);

//================================================================
//  Parameter and Integer                 
//================================================================
parameter IDLE = 4'd0;
parameter FILL = 4'd1;
parameter OP   = 4'd2;
parameter DONE = 4'd3;
integer i;
//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
input clk;
input rst_n;
input in_valid;
input [15:0] in_data;
input [1:0] curr_mode;
output reg out_valid;
output reg [7:0] out_dist;
//================================================================
//  Reg and Wire                   
//================================================================
reg [3:0] state_cs,state_ns;
reg [8:0] counter;
reg [10:0] win_val;
reg [10:0] max_win_val;
reg [4:0] shift_reg[0:3];
wire fill_done;
wire op_done;
assign fill_done = counter==5;
assign op_done = counter==256;
//================================================================
//  FSM                      
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE:state_ns = in_valid?FILL:IDLE;
		FILL:state_ns = fill_done?OP:FILL;
		OP:state_ns = op_done?DONE:OP;
		DONE:state_ns = IDLE;
		default:state_ns = state_cs;
	endcase
end
//================================================================
//  Design                     
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_ns==IDLE)
		counter<=0;
	else if(state_ns==FILL || state_ns == OP)
		counter<=counter+1;
end

reg [3:0] in_data_reg[0:3];
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			in_data_reg[i]<=0;
	else if(state_ns==FILL || state_ns==OP)begin
		in_data_reg[0]<=in_data[3:0];
		in_data_reg[1]<=in_data[7:4];
		in_data_reg[2]<=in_data[11:8];
		in_data_reg[3]<=in_data[15:12];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			shift_reg[i]<=0;
	else if(state_ns==IDLE)
		for(i=0;i<4;i=i+1)
			shift_reg[i]<=0;
	else if(state_ns==FILL || state_ns==OP)begin
		shift_reg[0]<=shift_reg[1];
		shift_reg[1]<=shift_reg[2];
		shift_reg[2]<=shift_reg[3];
		shift_reg[3]<=in_data_reg[0]+in_data_reg[1]+in_data_reg[2]+in_data_reg[3];
	end
end
always@(*)begin
	if(state_ns==FILL || state_ns==OP)begin
		if(curr_mode==0 || curr_mode==1)
			win_val = shift_reg[0]+shift_reg[2]+in_data_reg[0]+in_data_reg[1]+in_data_reg[2]+in_data_reg[3];
		else
			win_val = shift_reg[0]+shift_reg[1]*16+shift_reg[2]*9+shift_reg[3]*4+in_data_reg[0]+in_data_reg[1]+in_data_reg[2]+in_data_reg[3];
	end
		
	else
		win_val = 0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		max_win_val<=0;
	else if(state_ns==IDLE)
		max_win_val<=0;
	else if(state_ns==OP && win_val>max_win_val)
		max_win_val<=win_val;
end	

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_dist<=1;
	else if(state_ns==IDLE)
		out_dist<=1;
	
	else if(state_ns==OP && win_val>max_win_val)
		out_dist<=counter-4;
	// to avoid large distribute
	else if(state_ns==OP &&  win_val==max_win_val)
		out_dist<=(out_dist+counter-4)/2;
		
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		out_valid<=0;
	else if(state_ns==IDLE)
		out_valid<=0;
	else if(state_ns==DONE)
		out_valid<=1;
end

endmodule




///////////////////////////////////////////////////////////////////////////////////////////







module DRAM_write(
	// global signals 
       clk, rst_n,
	// axi write address channel 
		awaddr_m_inf,
		awvalid_m_inf,
		awready_m_inf,
		awlen_m_inf,
	// axi write data channel 
		wdata_m_inf,
		wlast_m_inf,
		wvalid_m_inf,
		wready_m_inf,
	// axi write response channel
		bvalid_m_inf,
		bready_m_inf,
	// input
		in_valid,
		write_num,
		curr_addr,
		curr_val,
		curr_mode,
		data_ready,
	// output
		out_valid
);
//================================================================
//  Parameter and Integer                 
//================================================================
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 128;

// FSM parameter
parameter IDLE = 4'd0;
parameter SET_VALID = 4'd1;
parameter IDLE2 = 4'd2;
parameter WR = 4'd3;
parameter DONE = 4'd4;


//================================================================
//  INPUT AND OUTPUT DECLARATION                         
//================================================================
// global signals 
input   clk, rst_n;
// axi write address channel 
output reg [ADDR_WIDTH-1:0]    awaddr_m_inf;
output reg                     awvalid_m_inf;
output reg[7:0]				   awlen_m_inf;
input  wire                    awready_m_inf;
// axi write data channel 
output wire [DATA_WIDTH-1:0]      wdata_m_inf;
output reg                       wlast_m_inf;
output reg                      wvalid_m_inf;
input  wire                     wready_m_inf;
// axi write response channel
input  wire                     bvalid_m_inf;
output reg                      bready_m_inf;
// input signals
input wire 						in_valid;
input wire [3:0]				write_num;
input [127:0] curr_val;
input [ADDR_WIDTH-1:0] curr_addr;
input [1:0]curr_mode;
input data_ready;
// output signals
output reg 						out_valid;
//================================================================
//  Reg and Wire                   
//================================================================
reg [3:0] state_cs,state_ns;
reg [7:0] write_counter;

wire doneWRITE;
wire doneReady;
wire doneDONE;
assign doneWRITE = (wready_m_inf && wvalid_m_inf);
assign doneReady = (awvalid_m_inf && awready_m_inf);
assign doneDONE = (bready_m_inf && bvalid_m_inf);
//================================================================
//  FSM                      
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_cs<=IDLE;
	else
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE: state_ns = in_valid?SET_VALID:IDLE;
		SET_VALID: state_ns = doneReady?WR:SET_VALID;
		WR	:	state_ns = (write_counter==awlen_m_inf && doneWRITE)?DONE:WR;
		DONE: state_ns = doneDONE?IDLE:DONE;
		default : state_ns = state_cs;
	endcase
end

//================================================================
//  Design                     
//================================================================

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		write_counter<=0;
	else if(state_ns==IDLE)
		write_counter<=0;
	else if(doneWRITE)
		write_counter<=write_counter+1;
end

always@(*)begin
	if(doneWRITE)
		out_valid = 1;
	else
		out_valid = 0;
end

// AXI4
// write address channel
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		awaddr_m_inf<=0;
	else if(state_ns==SET_VALID)
		awaddr_m_inf<= curr_addr;
	else
		awaddr_m_inf<= 0;
end

always@(*)begin
	if(state_cs == SET_VALID)
		awvalid_m_inf<=1;
	else 
		awvalid_m_inf<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		awlen_m_inf <= 0;
	else if(curr_mode==0)
		awlen_m_inf <=0 ;
	else 
		awlen_m_inf<=255;
end

// write data channel
assign wdata_m_inf=curr_val;

always@(*)begin
	if(state_cs==WR && write_counter==awlen_m_inf)
		wlast_m_inf<=1;
	else
		wlast_m_inf<=0;
end

always@(*)begin
	if(state_cs==WR && data_ready)
		wvalid_m_inf<=1;
	else
		wvalid_m_inf<=0;
end

// write response channel
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		bready_m_inf<=0;
	else if(state_ns==WR || state_ns==DONE)
		bready_m_inf<=1;
	else
		bready_m_inf<=0;
end

endmodule



///////////////////////////////////////////////////////////////////////////////////////////
