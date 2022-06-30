///############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2022 SPRING
//   Midterm Proejct            : TOF  
//   Author                     : Wen-Yue, Lin
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TOF.v
//   Module Name : TOF
//   Release version : V1.0 (Release Date: 2022-3)
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
    window,
    mode,
    frame_id,
    busy,

    // AXI4 IO
	// read address channel
    arid_m_inf,
    araddr_m_inf,
    arlen_m_inf,
    arsize_m_inf,
    arburst_m_inf,
    arvalid_m_inf,
    arready_m_inf,
    // read data channel
    rid_m_inf,
    rdata_m_inf,
    rresp_m_inf,
    rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf,
	// write address channel
    awid_m_inf,
    awaddr_m_inf,
    awsize_m_inf,
    awburst_m_inf,
    awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,
	// write data channel
    wdata_m_inf,
    wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,
    // write response channel
    bid_m_inf,
    bresp_m_inf,
    bvalid_m_inf,
    bready_m_inf 
);
// ===============================================================
//                      Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter

integer i;

parameter IDLE = 4'd0;

// mode0
parameter WAIT_START = 4'd10;
parameter RD_HIST = 4'd11;
parameter IDLE2_M0 = 4'd12;
parameter M0_OP = 4'd13;
parameter IDLE3_M0 = 4'd1;
parameter WAIT_PIPEOUT = 4'd9;
parameter M0_WR = 4'd14;
parameter M0_DONE = 4'd15;

// mode1
parameter SET_RD_VALID = 4'd2;
parameter IDLE2 = 4'd3;
parameter RD_DRAM = 4'd4;
parameter IDLE3 = 4'd5;
parameter M1_OP = 4'd6;
parameter M1_WR = 4'd7;
parameter M1_DONE = 4'd8;
// ===============================================================
//                      Input / Output 
// ===============================================================
// << CHIP io port with system >>
input           clk, rst_n;
input           in_valid;
input           start;
input [15:0]    stop;     
input [1:0]     window; 
input           mode;
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


//================================================================
//  Reg and Wire                   
//================================================================
reg [4:0] state_cs,state_ns;
// input reg
reg [1:0] window_reg;
reg [4:0] frame_id_reg;
// counter reg
reg [7:0] counter;
reg [7:0] counter2;
reg [7:0] round_counter;
wire [15:0]tmp_stop;
assign tmp_stop = stop;

// his idx reg
reg [7:0] loc_array[0:15];

// pipeline 
wire pipeline_invalid;
wire pipeline_outvalid;
wire [7:0]out_id[0:3];
assign pipeline_invalid = (state_ns==M1_OP||state_ns==M0_OP || state_ns==WAIT_PIPEOUT);


// dram read write signal
wire read_out_valid;
wire write_out_valid;
reg read_in_valid;
wire write_in_valid;
wire [7:0] read_counter;
reg data_ready ;
// sram control
wire [127:0]Q_mem_out[0:3];
reg [5:0]mem_address[0:3];
reg [127:0]D_mem_in[0:3];
reg mem_wen[0:3];
wire mem_cen;
wire mem_oen;
assign mem_cen=0;
assign mem_oen=0;


// done Signal
wire doneM0OP;
wire doneM0WR;
wire doneM1OP;
wire doneM1WR;

wire doneM0SET;
wire [9:0]doNum;
assign doneM0SET = counter2==4;
assign doNum = (window_reg+1)*128;
assign doneM0OP = (round_counter==15 && pipeline_outvalid);
assign doneM0WR = (bvalid_m_inf);
assign doneM1WR =  (round_counter==15 && write_out_valid);
assign doneM1OP = (round_counter==3 && pipeline_outvalid);
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
		IDLE:begin
			if(in_valid)begin
				if(mode)
					state_ns=SET_RD_VALID;
				else
					state_ns=WAIT_START;//*
			end
			else 
				state_ns=IDLE;
		end
		// mode0
		WAIT_START: state_ns = start?RD_HIST:WAIT_START;
		RD_HIST: state_ns =	(~in_valid)?IDLE2_M0:(~start)?WAIT_START:RD_HIST;
		IDLE2_M0: state_ns = M0_OP;
		M0_OP: state_ns = (counter==64)?WAIT_PIPEOUT:M0_OP;
		WAIT_PIPEOUT: state_ns = pipeline_outvalid?M0_WR:WAIT_PIPEOUT;
		M0_WR:state_ns = IDLE3_M0;
		IDLE3_M0: state_ns = (round_counter==16)?M0_DONE:M0_OP;
		M0_DONE: state_ns =  IDLE;
		// mode1
		SET_RD_VALID:state_ns=read_out_valid?RD_DRAM:SET_RD_VALID;
		RD_DRAM: state_ns = (~read_out_valid)?IDLE3:RD_DRAM;
		IDLE3: state_ns = M1_OP; 	// 5
		M1_OP: state_ns = doneM1OP?M1_WR:M1_OP; 	// 6
		M1_WR: state_ns = doneM1WR?M1_DONE:M1_WR;
		M1_DONE: state_ns = IDLE; 	// 7
		default : state_ns = state_cs;
	endcase
end


//================================================================
//  Design                   
//================================================================

// temp assign
assign arid_m_inf = 0;
assign arburst_m_inf = 1;
assign arsize_m_inf = 3'b100;
assign awid_m_inf = 0;
assign awburst_m_inf = 1;
assign awsize_m_inf = 3'b100;
//assign awlen_m_inf = 0;



always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		read_in_valid<=0;
	else if(state_ns==SET_RD_VALID && in_valid)
		read_in_valid <= 1;
	else
		read_in_valid <= 0;
end


// counter
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter<=0;
	else if(state_ns==IDLE)
		counter<=0;
	else if(state_ns==M1_OP || state_ns==M0_OP|| state_ns==WAIT_PIPEOUT)
		counter<=counter+1;
	else if(state_ns==WAIT_START || state_ns==IDLE2_M0 || state_ns==IDLE3_M0)
		counter<=0;
	else if(state_ns==RD_HIST)
		counter<=counter+1;
	
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		counter2<=0;
	else if(state_ns==IDLE)
		counter2<=0;
	else if(state_ns==WAIT_PIPEOUT)
		counter2<=0;
	else if(state_ns==M1_OP || state_ns==IDLE3 || state_ns==M0_OP || state_ns==IDLE2_M0 || state_ns==IDLE3_M0)
		counter2<=counter2+1;

end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_counter<=0;
	else if(state_ns==IDLE || state_ns==IDLE2_M0 )
		round_counter<=0;		
	else if(state_cs==M1_OP && state_ns==M1_WR)
		round_counter<=0;
	else if((state_cs==M1_WR) && bvalid_m_inf) 
		round_counter<=round_counter+1;
	else if(state_ns==IDLE3_M0)
		round_counter<=round_counter+1;
	else if(state_cs==RD_HIST && state_ns==WAIT_START)
		round_counter<=round_counter+1;
	else if(state_ns==M1_OP && pipeline_outvalid)
		round_counter<=round_counter+1;	
end

// reg
reg mode_reg;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		mode_reg<=0;
	else if(state_ns==IDLE)
		mode_reg<=0;
	else if(state_cs==IDLE && (state_ns==SET_RD_VALID ||state_ns==WAIT_START))
		mode_reg<=mode;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		window_reg<=0;
	else if(state_ns==IDLE)
		window_reg<=0;
	else if(state_cs==IDLE && (state_ns==SET_RD_VALID ||state_ns==WAIT_START))
		window_reg<=window;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		frame_id_reg<=0;
	else if(state_ns==IDLE)
		frame_id_reg<=0;
	else if(state_cs==IDLE && (state_ns==SET_RD_VALID || state_ns==WAIT_START))
		frame_id_reg<=frame_id;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<16;i=i+1)
			loc_array[i]<=0;
	else if(state_cs==M1_OP &&pipeline_outvalid)begin
		loc_array[round_counter*4]<=out_id[0];
		loc_array[round_counter*4+1]<=out_id[1];
		loc_array[round_counter*4+2]<=out_id[2];
		loc_array[round_counter*4+3]<=out_id[3];
	end
	else if(state_cs==WAIT_PIPEOUT &&pipeline_outvalid)begin
		loc_array[round_counter]<=out_id[0];
	end
end

// Output
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		busy<=0;
	else if(!in_valid&&(state_cs==SET_RD_VALID || state_cs==M0_OP))
		busy<=1;
	else if(state_ns==M0_DONE || state_ns==M1_DONE)
		busy<=0;
end

// SRAM
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

always@(*)begin
	// MODE1
	if(state_ns==RD_DRAM) begin
		mem_address[0]={read_counter[7:6],read_counter[3:0]};
		mem_address[1]={read_counter[7:6],read_counter[3:0]};
		mem_address[2]={read_counter[7:6],read_counter[3:0]};
		mem_address[3]={read_counter[7:6],read_counter[3:0]};
	end	
	else if(state_ns==M1_OP)begin
		mem_address[0]={2'd0,counter2[7:2]};
		mem_address[1]={2'd0,counter2[7:2]};
		mem_address[2]={2'd0,counter2[7:2]};
		mem_address[3]={2'd0,counter2[7:2]};
	end
	else if(state_ns==M1_WR)begin
		mem_address[0]={(round_counter[3:2]+1)*16-1};
		mem_address[1]={(round_counter[3:2]+1)*16-1};
		mem_address[2]={(round_counter[3:2]+1)*16-1};
		mem_address[3]={(round_counter[3:2]+1)*16-1};
	end
	// MODE0
	else if(state_ns==M0_OP)begin
		mem_address[0]={2'd0,counter2[5:0]};
		mem_address[1]={2'd0,counter2[5:0]};
		mem_address[2]={2'd0,counter2[5:0]};
		mem_address[3]={2'd0,counter2[5:0]};
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
	else
		for(i=0;i<4;i=i+1)
			mem_address[i]=0;
end


wire [7:0]his[0:15];
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

always@(*)begin
	if(state_ns==RD_DRAM)begin
		case(read_counter[5:4])
			0:begin
				D_mem_in[0] = rdata_m_inf;
				D_mem_in[1] = 0;
				D_mem_in[2] = 0;
				D_mem_in[3] = 0;
			end
			1:begin
				D_mem_in[0] = 0;
				D_mem_in[1] = rdata_m_inf;
				D_mem_in[2] = 0;
				D_mem_in[3] = 0;
			end
			2:begin
				D_mem_in[0] = 0;
				D_mem_in[1] = 0;
				D_mem_in[2] = rdata_m_inf;
				D_mem_in[3] = 0;
			end
			3:begin
				D_mem_in[0] = 0;
				D_mem_in[1] = 0;
				D_mem_in[2] = 0;
				D_mem_in[3] = rdata_m_inf;
			end
			default:begin
				D_mem_in[0] = 0;
				D_mem_in[1] = 0;
				D_mem_in[2] = 0;
				D_mem_in[3] = 0;
			end
		endcase
	end
	/*
	else if(state_cs==SET_RD_VALID)begin

	end
	*/
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
					D_mem_in[0] ={his[15]+Q_mem_out[0][127:120],
								his[14]+Q_mem_out[0][119:112],
								his[13]+Q_mem_out[0][111:104],
								his[12]+Q_mem_out[0][103:96],
								his[11]+Q_mem_out[0][95:88],
								his[10]+Q_mem_out[0][87:80],
								his[9]+Q_mem_out[0][79:72],
								his[8]+Q_mem_out[0][71:64],
								his[7]+Q_mem_out[0][63:56],
								his[6]+Q_mem_out[0][55:48],
								his[5]+Q_mem_out[0][47:40],
								his[4]+Q_mem_out[0][39:32],
								his[3]+Q_mem_out[0][31:24],
								his[2]+Q_mem_out[0][23:16],
								his[1]+Q_mem_out[0][15:8],
								his[0]+Q_mem_out[0][7:0]} ;
					D_mem_in[1] = 0;
					D_mem_in[2] = 0;
					D_mem_in[3] = 0;
				end
				1:begin
					D_mem_in[1] ={his[15]+Q_mem_out[1][127:120],
								his[14]+Q_mem_out[1][119:112],
								his[13]+Q_mem_out[1][111:104],
								his[12]+Q_mem_out[1][103:96],
								his[11]+Q_mem_out[1][95:88],
								his[10]+Q_mem_out[1][87:80],
								his[9]+Q_mem_out[1][79:72],
								his[8]+Q_mem_out[1][71:64],
								his[7]+Q_mem_out[1][63:56],
								his[6]+Q_mem_out[1][55:48],
								his[5]+Q_mem_out[1][47:40],
								his[4]+Q_mem_out[1][39:32],
								his[3]+Q_mem_out[1][31:24],
								his[2]+Q_mem_out[1][23:16],
								his[1]+Q_mem_out[1][15:8],
								his[0]+Q_mem_out[1][7:0]} ;
					D_mem_in[0] = 0;
					D_mem_in[2] = 0;
					D_mem_in[3] = 0;
				end
				2:begin
					D_mem_in[2] ={his[15]+Q_mem_out[2][127:120],
								his[14]+Q_mem_out[2][119:112],
								his[13]+Q_mem_out[2][111:104],
								his[12]+Q_mem_out[2][103:96],
								his[11]+Q_mem_out[2][95:88],
								his[10]+Q_mem_out[2][87:80],
								his[9]+Q_mem_out[2][79:72],
								his[8]+Q_mem_out[2][71:64],
								his[7]+Q_mem_out[2][63:56],
								his[6]+Q_mem_out[2][55:48],
								his[5]+Q_mem_out[2][47:40],
								his[4]+Q_mem_out[2][39:32],
								his[3]+Q_mem_out[2][31:24],
								his[2]+Q_mem_out[2][23:16],
								his[1]+Q_mem_out[2][15:8],
								his[0]+Q_mem_out[2][7:0]} ;
					D_mem_in[0] = 0;
					D_mem_in[1] = 0;
					D_mem_in[3] = 0;
				end
				3:begin
					D_mem_in[3] ={his[15]+Q_mem_out[3][127:120],
								his[14]+Q_mem_out[3][119:112],
								his[13]+Q_mem_out[3][111:104],
								his[12]+Q_mem_out[3][103:96],
								his[11]+Q_mem_out[3][95:88],
								his[10]+Q_mem_out[3][87:80],
								his[9]+Q_mem_out[3][79:72],
								his[8]+Q_mem_out[3][71:64],
								his[7]+Q_mem_out[3][63:56],
								his[6]+Q_mem_out[3][55:48],
								his[5]+Q_mem_out[3][47:40],
								his[4]+Q_mem_out[3][39:32],
								his[3]+Q_mem_out[3][31:24],
								his[2]+Q_mem_out[3][23:16],
								his[1]+Q_mem_out[3][15:8],
								his[0]+Q_mem_out[3][7:0]} ;
					D_mem_in[0] = 0;
					D_mem_in[1] = 0;
					D_mem_in[2] = 0;
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


SRAM_64_128 sram0(.Q(Q_mem_out[0]),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen[0]),.A(mem_address[0]),.D(D_mem_in[0]),.OEN(mem_oen));
SRAM_64_128 sram1(.Q(Q_mem_out[1]),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen[1]),.A(mem_address[1]),.D(D_mem_in[1]),.OEN(mem_oen));
SRAM_64_128 sram2(.Q(Q_mem_out[2]),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen[2]),.A(mem_address[2]),.D(D_mem_in[2]),.OEN(mem_oen));
SRAM_64_128 sram3(.Q(Q_mem_out[3]),.CLK(clk),.CEN(mem_cen),.WEN(mem_wen[3]),.A(mem_address[3]),.D(D_mem_in[3]),.OEN(mem_oen));

reg [31:0]curr_stride_input[0:3];

always@(*)begin
	if(state_ns==M1_OP)begin
		case(counter[1:0])
			0:begin
				curr_stride_input[0] = Q_mem_out[0][31:0];
				curr_stride_input[1] = Q_mem_out[1][31:0];
				curr_stride_input[2] = Q_mem_out[2][31:0];
				curr_stride_input[3] = Q_mem_out[3][31:0];
			end
			1:begin
				curr_stride_input[0] = Q_mem_out[0][63:32];
				curr_stride_input[1] = Q_mem_out[1][63:32];
				curr_stride_input[2] = Q_mem_out[2][63:32];
				curr_stride_input[3] = Q_mem_out[3][63:32];
			end
			2:begin
				curr_stride_input[0] = Q_mem_out[0][95:64];
				curr_stride_input[1] = Q_mem_out[1][95:64];
				curr_stride_input[2] = Q_mem_out[2][95:64];
				curr_stride_input[3] = Q_mem_out[3][95:64];
			end
			3:begin
				if(counter[7:2]==63)begin
					curr_stride_input[0] = {8'd0,Q_mem_out[0][119:96]};
					curr_stride_input[1] = {8'd0,Q_mem_out[1][119:96]};
					curr_stride_input[2] = {8'd0,Q_mem_out[2][119:96]};
					curr_stride_input[3] = {8'd0,Q_mem_out[3][119:96]};
				end
				else begin
					curr_stride_input[0] = Q_mem_out[0][127:96];
					curr_stride_input[1] = Q_mem_out[1][127:96];
					curr_stride_input[2] = Q_mem_out[2][127:96];
					curr_stride_input[3] = Q_mem_out[3][127:96];
				end
			end
			default:begin
				curr_stride_input[0] = 0;
				curr_stride_input[1] = 0;
				curr_stride_input[2] = 0;
				curr_stride_input[3] = 0;
			end
		endcase
	end
	else if(state_ns==M0_OP)begin
		case(round_counter[3:0])
			0:begin
				curr_stride_input[0] = {Q_mem_out[3][7:0],Q_mem_out[2][7:0],Q_mem_out[1][7:0],Q_mem_out[0][7:0]};
				curr_stride_input[1] = {Q_mem_out[3][15:8],Q_mem_out[2][15:8],Q_mem_out[1][15:8],Q_mem_out[0][15:8]};
				curr_stride_input[2] = {Q_mem_out[3][23:16],Q_mem_out[2][23:16],Q_mem_out[1][23:16],Q_mem_out[0][23:16]};
				curr_stride_input[3] = {Q_mem_out[3][31:24],Q_mem_out[2][31:24],Q_mem_out[1][31:24],Q_mem_out[0][31:24]};
			end
			1:begin
				curr_stride_input[0] = {Q_mem_out[3][15:8],Q_mem_out[2][15:8],Q_mem_out[1][15:8],Q_mem_out[0][15:8]};
				curr_stride_input[1] = {Q_mem_out[3][15:8],Q_mem_out[2][15:8],Q_mem_out[1][15:8],Q_mem_out[0][15:8]};
				curr_stride_input[2] = {Q_mem_out[3][15:8],Q_mem_out[2][15:8],Q_mem_out[1][15:8],Q_mem_out[0][15:8]};
				curr_stride_input[3] = {Q_mem_out[3][15:8],Q_mem_out[2][15:8],Q_mem_out[1][15:8],Q_mem_out[0][15:8]};
			end
			2:begin
				curr_stride_input[0] = {Q_mem_out[3][23:16],Q_mem_out[2][23:16],Q_mem_out[1][23:16],Q_mem_out[0][23:16]};
				curr_stride_input[1] = {Q_mem_out[3][23:16],Q_mem_out[2][23:16],Q_mem_out[1][23:16],Q_mem_out[0][23:16]};
				curr_stride_input[2] = {Q_mem_out[3][23:16],Q_mem_out[2][23:16],Q_mem_out[1][23:16],Q_mem_out[0][23:16]};
				curr_stride_input[3] = {Q_mem_out[3][23:16],Q_mem_out[2][23:16],Q_mem_out[1][23:16],Q_mem_out[0][23:16]};
			end
			3:begin
				curr_stride_input[0] = {Q_mem_out[3][31:24],Q_mem_out[2][31:24],Q_mem_out[1][31:24],Q_mem_out[0][31:24]};
				curr_stride_input[1] = {Q_mem_out[3][31:24],Q_mem_out[2][31:24],Q_mem_out[1][31:24],Q_mem_out[0][31:24]};
				curr_stride_input[2] = {Q_mem_out[3][31:24],Q_mem_out[2][31:24],Q_mem_out[1][31:24],Q_mem_out[0][31:24]};
				curr_stride_input[3] = {Q_mem_out[3][31:24],Q_mem_out[2][31:24],Q_mem_out[1][31:24],Q_mem_out[0][31:24]};
			end
			4:begin
				curr_stride_input[0] = {Q_mem_out[3][39:32],Q_mem_out[2][39:32],Q_mem_out[1][39:32],Q_mem_out[0][39:32]};
				curr_stride_input[1] = {Q_mem_out[3][39:32],Q_mem_out[2][39:32],Q_mem_out[1][39:32],Q_mem_out[0][39:32]};
				curr_stride_input[2] = {Q_mem_out[3][39:32],Q_mem_out[2][39:32],Q_mem_out[1][39:32],Q_mem_out[0][39:32]};
				curr_stride_input[3] = {Q_mem_out[3][39:32],Q_mem_out[2][39:32],Q_mem_out[1][39:32],Q_mem_out[0][39:32]};
			end
			5:begin
				curr_stride_input[0] = {Q_mem_out[3][47:40],Q_mem_out[2][47:40],Q_mem_out[1][47:40],Q_mem_out[0][47:40]};
				curr_stride_input[1] = {Q_mem_out[3][47:40],Q_mem_out[2][47:40],Q_mem_out[1][47:40],Q_mem_out[0][47:40]};
				curr_stride_input[2] = {Q_mem_out[3][47:40],Q_mem_out[2][47:40],Q_mem_out[1][47:40],Q_mem_out[0][47:40]};
				curr_stride_input[3] = {Q_mem_out[3][47:40],Q_mem_out[2][47:40],Q_mem_out[1][47:40],Q_mem_out[0][47:40]};
			end
			6:begin
				curr_stride_input[0] = {Q_mem_out[3][55:48],Q_mem_out[2][55:48],Q_mem_out[1][55:48],Q_mem_out[0][55:48]};
				curr_stride_input[1] = {Q_mem_out[3][55:48],Q_mem_out[2][55:48],Q_mem_out[1][55:48],Q_mem_out[0][55:48]};
				curr_stride_input[2] = {Q_mem_out[3][55:48],Q_mem_out[2][55:48],Q_mem_out[1][55:48],Q_mem_out[0][55:48]};
				curr_stride_input[3] = {Q_mem_out[3][55:48],Q_mem_out[2][55:48],Q_mem_out[1][55:48],Q_mem_out[0][55:48]};
			end
			7:begin
				curr_stride_input[0] = {Q_mem_out[3][63:56],Q_mem_out[2][63:56],Q_mem_out[1][63:56],Q_mem_out[0][63:56]};
				curr_stride_input[1] = {Q_mem_out[3][63:56],Q_mem_out[2][63:56],Q_mem_out[1][63:56],Q_mem_out[0][63:56]};
				curr_stride_input[2] = {Q_mem_out[3][63:56],Q_mem_out[2][63:56],Q_mem_out[1][63:56],Q_mem_out[0][63:56]};
				curr_stride_input[3] = {Q_mem_out[3][63:56],Q_mem_out[2][63:56],Q_mem_out[1][63:56],Q_mem_out[0][63:56]};
			end
			8:begin
				curr_stride_input[0] = {Q_mem_out[3][71:64],Q_mem_out[2][71:64],Q_mem_out[1][71:64],Q_mem_out[0][71:64]};
				curr_stride_input[1] = {Q_mem_out[3][71:64],Q_mem_out[2][71:64],Q_mem_out[1][71:64],Q_mem_out[0][71:64]};
				curr_stride_input[2] = {Q_mem_out[3][71:64],Q_mem_out[2][71:64],Q_mem_out[1][71:64],Q_mem_out[0][71:64]};
				curr_stride_input[3] = {Q_mem_out[3][71:64],Q_mem_out[2][71:64],Q_mem_out[1][71:64],Q_mem_out[0][71:64]};
			end
			9:begin
				curr_stride_input[0] = {Q_mem_out[3][79:72],Q_mem_out[2][79:72],Q_mem_out[1][79:72],Q_mem_out[0][79:72]};
				curr_stride_input[1] = {Q_mem_out[3][79:72],Q_mem_out[2][79:72],Q_mem_out[1][79:72],Q_mem_out[0][79:72]};
				curr_stride_input[2] = {Q_mem_out[3][79:72],Q_mem_out[2][79:72],Q_mem_out[1][79:72],Q_mem_out[0][79:72]};
				curr_stride_input[3] = {Q_mem_out[3][79:72],Q_mem_out[2][79:72],Q_mem_out[1][79:72],Q_mem_out[0][79:72]};
			end
			10:begin
				curr_stride_input[0] = {Q_mem_out[3][87:80],Q_mem_out[2][87:80],Q_mem_out[1][87:80],Q_mem_out[0][87:80]};
				curr_stride_input[1] = {Q_mem_out[3][87:80],Q_mem_out[2][87:80],Q_mem_out[1][87:80],Q_mem_out[0][87:80]};
				curr_stride_input[2] = {Q_mem_out[3][87:80],Q_mem_out[2][87:80],Q_mem_out[1][87:80],Q_mem_out[0][87:80]};
				curr_stride_input[3] = {Q_mem_out[3][87:80],Q_mem_out[2][87:80],Q_mem_out[1][87:80],Q_mem_out[0][87:80]};
			end
			11:begin
				curr_stride_input[0] = {Q_mem_out[3][95:88],Q_mem_out[2][95:88],Q_mem_out[1][95:88],Q_mem_out[0][95:88]};
				curr_stride_input[1] = {Q_mem_out[3][95:88],Q_mem_out[2][95:88],Q_mem_out[1][95:88],Q_mem_out[0][95:88]};
				curr_stride_input[2] = {Q_mem_out[3][95:88],Q_mem_out[2][95:88],Q_mem_out[1][95:88],Q_mem_out[0][95:88]};
				curr_stride_input[3] = {Q_mem_out[3][95:88],Q_mem_out[2][95:88],Q_mem_out[1][95:88],Q_mem_out[0][95:88]};
			end
			12:begin
				curr_stride_input[0] = {Q_mem_out[3][103:96],Q_mem_out[2][103:96],Q_mem_out[1][103:96],Q_mem_out[0][103:96]};
				curr_stride_input[1] = {Q_mem_out[3][103:96],Q_mem_out[2][103:96],Q_mem_out[1][103:96],Q_mem_out[0][103:96]};
				curr_stride_input[2] = {Q_mem_out[3][103:96],Q_mem_out[2][103:96],Q_mem_out[1][103:96],Q_mem_out[0][103:96]};
				curr_stride_input[3] = {Q_mem_out[3][103:96],Q_mem_out[2][103:96],Q_mem_out[1][103:96],Q_mem_out[0][103:96]};
			end
			13:begin
				curr_stride_input[0] = {Q_mem_out[3][111:104],Q_mem_out[2][111:104],Q_mem_out[1][111:104],Q_mem_out[0][111:104]};
				curr_stride_input[1] = {Q_mem_out[3][111:104],Q_mem_out[2][111:104],Q_mem_out[1][111:104],Q_mem_out[0][111:104]};
				curr_stride_input[2] = {Q_mem_out[3][111:104],Q_mem_out[2][111:104],Q_mem_out[1][111:104],Q_mem_out[0][111:104]};
				curr_stride_input[3] = {Q_mem_out[3][111:104],Q_mem_out[2][111:104],Q_mem_out[1][111:104],Q_mem_out[0][111:104]};
			end
			14:begin
				curr_stride_input[0] = {Q_mem_out[3][119:112],Q_mem_out[2][119:112],Q_mem_out[1][119:112],Q_mem_out[0][119:112]};
				curr_stride_input[1] = {Q_mem_out[3][119:112],Q_mem_out[2][119:112],Q_mem_out[1][119:112],Q_mem_out[0][119:112]};
				curr_stride_input[2] = {Q_mem_out[3][119:112],Q_mem_out[2][119:112],Q_mem_out[1][119:112],Q_mem_out[0][119:112]};
				curr_stride_input[3] = {Q_mem_out[3][119:112],Q_mem_out[2][119:112],Q_mem_out[1][119:112],Q_mem_out[0][119:112]};
			end
			15:begin
				curr_stride_input[0] = {Q_mem_out[3][127:120],Q_mem_out[2][127:120],Q_mem_out[1][127:120],Q_mem_out[0][127:120]};
				curr_stride_input[1] = {Q_mem_out[3][127:120],Q_mem_out[2][127:120],Q_mem_out[1][127:120],Q_mem_out[0][127:120]};
				curr_stride_input[2] = {Q_mem_out[3][127:120],Q_mem_out[2][127:120],Q_mem_out[1][127:120],Q_mem_out[0][127:120]};
				curr_stride_input[3] = {Q_mem_out[3][127:120],Q_mem_out[2][127:120],Q_mem_out[1][127:120],Q_mem_out[0][127:120]};
			end
			default:begin
				curr_stride_input[0] = 0;
				curr_stride_input[1] = 0;
				curr_stride_input[2] = 0;
				curr_stride_input[3] = 0;
			end
		endcase
	end
	else begin
		curr_stride_input[0] = 0;
		curr_stride_input[1] = 0;
		curr_stride_input[2] = 0;
		curr_stride_input[3] = 0;
	end
	
end

pipeline p0(.clk(clk),.rst_n(rst_n),.window_reg(window_reg),.curr_stride(curr_stride_input[0]),.counter(counter),.in_valid(pipeline_invalid),.out_valid(pipeline_outvalid),.out_id(out_id[0]));
pipeline p1(.clk(clk),.rst_n(rst_n),.window_reg(window_reg),.curr_stride(curr_stride_input[1]),.counter(counter),.in_valid(pipeline_invalid),.out_valid(pipeline_outvalid),.out_id(out_id[1]));
pipeline p2(.clk(clk),.rst_n(rst_n),.window_reg(window_reg),.curr_stride(curr_stride_input[2]),.counter(counter),.in_valid(pipeline_invalid),.out_valid(pipeline_outvalid),.out_id(out_id[2]));
pipeline p3(.clk(clk),.rst_n(rst_n),.window_reg(window_reg),.curr_stride(curr_stride_input[3]),.counter(counter),.in_valid(pipeline_invalid),.out_valid(pipeline_outvalid),.out_id(out_id[3]));
// DRAM read write

wire [31:0] dram_read_addr = {frame_id_reg+8'h10,12'b0000_0000_0000}; 

DRAM_read test_read(
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
	// input signals
		read_in_valid,
		dram_read_addr,
	// output signals
		read_out_valid,
		read_counter
);

assign write_in_valid = state_ns==M1_WR|| (state_cs==WAIT_START && state_ns==RD_HIST);

//assign wdata_m_inf = loc_array[0];
reg [ADDR_WIDTH-1:0]dram_write_addr;
reg [127:0]dram_write_val;
wire [31:0]idx_sel = frame_id_reg+8'h10;


reg [7:0]Q_out_sel[0:3];
always@(*)begin
	if(state_ns==M0_OP)
		case(round_counter[3:0])
			0:begin
				Q_out_sel[0] = Q_mem_out[0][7:0];
				Q_out_sel[1] = Q_mem_out[1][7:0];
				Q_out_sel[2] = Q_mem_out[2][7:0];
				Q_out_sel[3] = Q_mem_out[3][7:0];
			end
			1:begin
				Q_out_sel[0] = Q_mem_out[0][15:8];
				Q_out_sel[1] = Q_mem_out[1][15:8];
				Q_out_sel[2] = Q_mem_out[2][15:8];
				Q_out_sel[3] = Q_mem_out[3][15:8];
			end
			2:begin
				Q_out_sel[0] = Q_mem_out[0][23:16];
				Q_out_sel[1] = Q_mem_out[1][23:16];
				Q_out_sel[2] = Q_mem_out[2][23:16];
				Q_out_sel[3] = Q_mem_out[3][23:16];
			end
			3:begin
				Q_out_sel[0] = Q_mem_out[0][31:24];
				Q_out_sel[1] = Q_mem_out[1][31:24];
				Q_out_sel[2] = Q_mem_out[2][31:24];
				Q_out_sel[3] = Q_mem_out[3][31:24];
			end
			4:begin
				Q_out_sel[0] = Q_mem_out[0][39:32];
				Q_out_sel[1] = Q_mem_out[1][39:32];
				Q_out_sel[2] = Q_mem_out[2][39:32];
				Q_out_sel[3] = Q_mem_out[3][39:32];
			end
			5:begin
				Q_out_sel[0] = Q_mem_out[0][47:40];
				Q_out_sel[1] = Q_mem_out[1][47:40];
				Q_out_sel[2] = Q_mem_out[2][47:40];
				Q_out_sel[3] = Q_mem_out[3][47:40];
			end
			6:begin
				Q_out_sel[0] = Q_mem_out[0][55:48];
				Q_out_sel[1] = Q_mem_out[1][55:48];
				Q_out_sel[2] = Q_mem_out[2][55:48];
				Q_out_sel[3] = Q_mem_out[3][55:48];
			end
			7:begin
				Q_out_sel[0] = Q_mem_out[0][63:56];
				Q_out_sel[1] = Q_mem_out[1][63:56];
				Q_out_sel[2] = Q_mem_out[2][63:56];
				Q_out_sel[3] = Q_mem_out[3][63:56];
			end
			8:begin
				Q_out_sel[0] = Q_mem_out[0][71:64];
				Q_out_sel[1] = Q_mem_out[1][71:64];
				Q_out_sel[2] = Q_mem_out[2][71:64];
				Q_out_sel[3] = Q_mem_out[3][71:64];
			end
			9:begin
				Q_out_sel[0] = Q_mem_out[0][79:72];
				Q_out_sel[1] = Q_mem_out[1][79:72];
				Q_out_sel[2] = Q_mem_out[2][79:72];
				Q_out_sel[3] = Q_mem_out[3][79:72];
			end
			10:begin
				Q_out_sel[0] = Q_mem_out[0][87:80];
				Q_out_sel[1] = Q_mem_out[1][87:80];
				Q_out_sel[2] = Q_mem_out[2][87:80];
				Q_out_sel[3] = Q_mem_out[3][87:80];
			end
			11:begin
				Q_out_sel[0] = Q_mem_out[0][95:88];
				Q_out_sel[1] = Q_mem_out[1][95:88];
				Q_out_sel[2] = Q_mem_out[2][95:88];
				Q_out_sel[3] = Q_mem_out[3][95:88];
			end
			12:begin
				Q_out_sel[0] = Q_mem_out[0][103:96];
				Q_out_sel[1] = Q_mem_out[1][103:96];
				Q_out_sel[2] = Q_mem_out[2][103:96];
				Q_out_sel[3] = Q_mem_out[3][103:96];
			end
			13:begin
				Q_out_sel[0] = Q_mem_out[0][111:104];
				Q_out_sel[1] = Q_mem_out[1][111:104];
				Q_out_sel[2] = Q_mem_out[2][111:104];
				Q_out_sel[3] = Q_mem_out[3][111:104];
			end
			14:begin
				Q_out_sel[0] = Q_mem_out[0][119:112];
				Q_out_sel[1] = Q_mem_out[1][119:112];
				Q_out_sel[2] = Q_mem_out[2][119:112];
				Q_out_sel[3] = Q_mem_out[3][119:112];
			end
			15:begin
				Q_out_sel[0] = Q_mem_out[0][127:120];
				Q_out_sel[1] = Q_mem_out[1][127:120];
				Q_out_sel[2] = Q_mem_out[2][127:120];
				Q_out_sel[3] = Q_mem_out[3][127:120];
			end
			default:begin
				Q_out_sel[0] = 0;
				Q_out_sel[1] = 0;
				Q_out_sel[2] = 0;
				Q_out_sel[3] = 0;
			end
		endcase
	else if(state_ns==M0_WR)begin
		Q_out_sel[0] = 0;
		Q_out_sel[1] = 0;
		Q_out_sel[2] = 0;
		Q_out_sel[3] = loc_array[round_counter[3:0]];
	end
	else begin
		Q_out_sel[0] = 0;
		Q_out_sel[1] = 0;
		Q_out_sel[2] = 0;
		Q_out_sel[3] = 0;
	end
end



always@(*)begin
	if(state_ns==M1_WR)
		dram_write_addr = {12'b0000_0000_0000,idx_sel,round_counter[3:0],8'hf0};
	else if(state_ns==RD_HIST)
		dram_write_addr = {12'b0000_0000_0000,idx_sel,round_counter,4'h0};
	else
		dram_write_addr = 0;
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		dram_write_val<=0;
	else if(state_ns==M1_WR)
		dram_write_val <={loc_array[round_counter],Q_mem_out[round_counter[1:0]][119:0]};
	else if(state_ns==IDLE3_M0)
		dram_write_val <={loc_array[round_counter[3:0]],dram_write_val[119:0]};
	else if(state_ns==WAIT_PIPEOUT||state_ns==M0_WR)
		dram_write_val <=dram_write_val;
	else if(state_ns==M0_OP)
		case(counter[1:0])
			0:dram_write_val <={96'h0,Q_out_sel[3],Q_out_sel[2],Q_out_sel[1],Q_out_sel[0]};
			1:dram_write_val <={64'h0,Q_out_sel[3],Q_out_sel[2],Q_out_sel[1],Q_out_sel[0],dram_write_val[31:0]};
			2:dram_write_val <={32'h0,Q_out_sel[3],Q_out_sel[2],Q_out_sel[1],Q_out_sel[0],dram_write_val[63:0]};
			3:dram_write_val <={Q_out_sel[3],Q_out_sel[2],Q_out_sel[1],Q_out_sel[0],dram_write_val[95:0]};
			default:dram_write_val <=0;
		endcase
	else
		dram_write_val <= 0;
end







always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		data_ready<=0;
	else if(state_ns==M1_WR)
		data_ready<=1;
	else if(state_ns==IDLE)
		data_ready<=0;
	else if(state_ns==IDLE3_M0)
		data_ready<=1;
	else if(state_cs==M0_OP && counter2==2 && round_counter==0)
		data_ready<=1;
	else if(state_cs==M0_OP && counter2==5)
		data_ready<=0;
	else if(state_cs==IDLE3_M0)
		data_ready<=0;
	else if(state_cs==M0_OP && counter==63)
		data_ready<=0;
	else if(state_cs==M0_OP && counter[1:0]==3)
		data_ready<=1;
	else if(state_cs==M0_OP && counter2>5)
		data_ready<=0;
end

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

endmodule








//================================================================================================
//   SUBMODULE
//================================================================================================
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
//reg [7:0] counter;


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
input curr_mode;
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
		//IDLE2 : state_ns = wready_m_inf?WR:IDLE2; //wait ready
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
		/*
	else if(!in_valid)
		write_counter<=0;
		*/
	else if(doneWRITE)
		write_counter<=write_counter+1;
end
//assign out_valid = doneWRITE;

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
	else if(curr_mode)
		awlen_m_inf <=0 ;
	else if(curr_mode==0)
		awlen_m_inf<=255;
end

// write data channel
assign wdata_m_inf=curr_val;
/*
always@(*)begin
	 if(data_ready)
		wdata_m_inf<=curr_val;
	else 
		wdata_m_inf<=0;
end
*/
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



module pipeline(
	clk,rst_n,
	window_reg,
	curr_stride,
	counter,
	in_valid,
	out_valid,
	out_id
);

input clk,rst_n;
//input [127:0]curr_sel_sram_output;
input [31:0]curr_stride;
input [1:0] window_reg;
input in_valid;
input [7:0] counter;
output reg out_valid;
output wire [7:0]out_id;

integer i;
//pipeline operation
reg [7:0] max_idx_reg;
reg [14:0] max_val_reg;
//reg [31:0] curr_stride;
//stage1
reg [7:0]stage1_in_reg[0:3];
reg [7:0]stage1_buffer_reg[0:7];
reg signed [8:0] stage1_sub_wire[0:3]; //1+8
//stage2
reg signed [8:0]stage2_reg[0:3];//1+8
reg signed [9:0] stage2_add_wire[0:1];//1+9
//stage3
reg signed[9:0]stage3_reg[0:3];//1+9
reg signed[10:0]stage3_add_wire[0:1];//1+10
//stage4
reg [7:0]stage4_idx_reg[0:3];
reg signed[10:0]stage4_reg[0:3];
reg signed[10:0]stage4_cmp_wire[0:1];
//stage5
reg [7:0]stage5_idx_reg[0:1];
reg signed[10:0]stage5_reg[0:2];
reg signed[10:0]stage5_cmp_wire;
//stage6
reg [7:0]stage6_idx_reg;
reg signed[10:0]stage6_reg[0:1];
//stage7
reg [7:0]stage7_idx_reg;
reg [10:0]stage7_reg[0:1];
reg [10:0]stage7_cmp_wire;
//stage8
reg [7:0]stage8_idx_reg;
reg [10:0]stage8_reg;

reg round_done_signal[1:8];


// Operation Register (pipeline ver)

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_done_signal[1]<=1;
	else if((!(&counter[5:0]))|| !in_valid)
		round_done_signal[1]<=1;
	else
		round_done_signal[1]<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_done_signal[2]<=1;
	else if(round_done_signal[1]==1)
		round_done_signal[2]<=1;
	else
		round_done_signal[2]<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_done_signal[3]<=1;
	else if(round_done_signal[2]==1)
		round_done_signal[3]<=1;
	else
		round_done_signal[3]<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_done_signal[4]<=1;
	else if(round_done_signal[3]==1)
		round_done_signal[4]<=1;
	else
		round_done_signal[4]<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_done_signal[5]<=1;
	else if(round_done_signal[4]==1)
		round_done_signal[5]<=1;
	else
		round_done_signal[5]<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_done_signal[6]<=1;
	else if(round_done_signal[5]==1)
		round_done_signal[6]<=1;
	else
		round_done_signal[6]<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_done_signal[7]<=1;
	else if(round_done_signal[6]==1)
		round_done_signal[7]<=1;
	else
		round_done_signal[7]<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		round_done_signal[8]<=1;
	else if(round_done_signal[7]==1)
		round_done_signal[8]<=1;
	else
		round_done_signal[8]<=0;
end
/*
always@(*)begin
	if(in_valid)begin
		case(counter[1:0])
			0:curr_stride = curr_sel_sram_output[31:0];
			1:curr_stride = curr_sel_sram_output[63:32];
			2:curr_stride = curr_sel_sram_output[95:64];
			3:curr_stride = curr_sel_sram_output[127:96];
			default:curr_stride = 0;
		endcase
	end
	else
		curr_stride = 0;
end
*/
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		max_idx_reg<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		max_val_reg<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			stage1_in_reg[i]<=0;
	else if(!in_valid)
		for(i=0;i<4;i=i+1)
			stage1_in_reg[i]<=0;
	else begin
		stage1_in_reg[0]<=curr_stride[7:0];
		stage1_in_reg[1]<=curr_stride[15:8];
		stage1_in_reg[2]<=curr_stride[23:16];
		stage1_in_reg[3]<=curr_stride[31:24];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<8;i=i+1)
			stage1_buffer_reg[i]<=0;
	else if(!in_valid)
		for(i=0;i<8;i=i+1)
			stage1_buffer_reg[i]<=0;
			/*
	else if(&counter[5:0])
		for(i=0;i<8;i=i+1)
			stage1_buffer_reg[i]<=0;
			*/
	else if(!round_done_signal[1])begin
		if(window_reg==2)begin //size = 8
			stage1_buffer_reg[0]<=0;
			stage1_buffer_reg[1]<=0;
			stage1_buffer_reg[2]<=0;
			stage1_buffer_reg[3]<=0;
			stage1_buffer_reg[4]<=0;
			stage1_buffer_reg[5]<=0;
			stage1_buffer_reg[6]<=0;
			stage1_buffer_reg[7]<=0;
		end
		else if(window_reg==0)begin
			stage1_buffer_reg[0]<=curr_stride[31:24];
			stage1_buffer_reg[1]<=0;
			stage1_buffer_reg[2]<=0;
			stage1_buffer_reg[3]<=curr_stride[7:0];
			stage1_buffer_reg[4]<=0;
			stage1_buffer_reg[5]<=curr_stride[15:8];
			stage1_buffer_reg[6]<=0;
			stage1_buffer_reg[7]<=curr_stride[23:16];
		end
		else if(window_reg==1)begin
			stage1_buffer_reg[0]<=curr_stride[23:16];
			stage1_buffer_reg[1]<=0;
			stage1_buffer_reg[2]<=curr_stride[31:24];
			stage1_buffer_reg[3]<=0;
			stage1_buffer_reg[4]<=0;
			stage1_buffer_reg[5]<=curr_stride[7:0];
			stage1_buffer_reg[6]<=0;
			stage1_buffer_reg[7]<=curr_stride[15:8];
		end
		else begin //size = 1,2,4
			stage1_buffer_reg[0]<=0;
			stage1_buffer_reg[1]<=0;
			stage1_buffer_reg[2]<=0;
			stage1_buffer_reg[3]<=0;
			stage1_buffer_reg[4]<=0;
			stage1_buffer_reg[5]<=0;
			stage1_buffer_reg[6]<=0;
			stage1_buffer_reg[7]<=0;
		end
	end
	else begin

		
		if(window_reg==2)begin //size = 4
			stage1_buffer_reg[0]<=0;
			stage1_buffer_reg[1]<=stage1_in_reg[0];
			stage1_buffer_reg[2]<=0;
			stage1_buffer_reg[3]<=stage1_in_reg[1];
			stage1_buffer_reg[4]<=0;
			stage1_buffer_reg[5]<=stage1_in_reg[2];
			stage1_buffer_reg[6]<=0;
			stage1_buffer_reg[7]<=stage1_in_reg[3];
		end
		else if(window_reg==0)begin
			stage1_buffer_reg[0]<=curr_stride[31:24];
			stage1_buffer_reg[1]<=stage1_buffer_reg[0];
			stage1_buffer_reg[2]<=0;
			stage1_buffer_reg[3]<=curr_stride[7:0];
			stage1_buffer_reg[4]<=0;
			stage1_buffer_reg[5]<=curr_stride[15:8];
			stage1_buffer_reg[6]<=0;
			stage1_buffer_reg[7]<=curr_stride[23:16];
		end
		else if(window_reg==1)begin
			stage1_buffer_reg[0]<=curr_stride[23:16];
			stage1_buffer_reg[1]<=stage1_buffer_reg[0];
			stage1_buffer_reg[2]<=curr_stride[31:24];
			stage1_buffer_reg[3]<=stage1_buffer_reg[2];
			stage1_buffer_reg[4]<=0;
			stage1_buffer_reg[5]<=curr_stride[7:0];
			stage1_buffer_reg[6]<=0;
			stage1_buffer_reg[7]<=curr_stride[15:8];
		end
		else begin // 3
			stage1_buffer_reg[0]<=stage1_in_reg[0];
			stage1_buffer_reg[1]<=stage1_buffer_reg[0];
			stage1_buffer_reg[2]<=stage1_in_reg[1];
			stage1_buffer_reg[3]<=stage1_buffer_reg[2];
			stage1_buffer_reg[4]<=stage1_in_reg[2];
			stage1_buffer_reg[5]<=stage1_buffer_reg[4];
			stage1_buffer_reg[6]<=stage1_in_reg[3];
			stage1_buffer_reg[7]<=stage1_buffer_reg[6];
		end
		
	end
	
end

always@(*)begin
	if(in_valid)begin
		stage1_sub_wire[0] = stage1_in_reg[0] - stage1_buffer_reg[1];
		stage1_sub_wire[1] = stage1_in_reg[1] - stage1_buffer_reg[3];
		stage1_sub_wire[2] = stage1_in_reg[2] - stage1_buffer_reg[5];
		stage1_sub_wire[3] = stage1_in_reg[3] - stage1_buffer_reg[7];
	end
	else begin
		stage1_sub_wire[0] = 0;
		stage1_sub_wire[1] = 0;
		stage1_sub_wire[2] = 0;
		stage1_sub_wire[3] = 0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			stage2_reg[i]<=0;
	else if(!in_valid)
		for(i=0;i<4;i=i+1)
			stage2_reg[i]<=0;
	else if(in_valid)begin
		stage2_reg[0]<=stage1_sub_wire[0];
		stage2_reg[1]<=stage1_sub_wire[1];
		stage2_reg[2]<=stage1_sub_wire[2];
		stage2_reg[3]<=stage1_sub_wire[3];
	end
end

always@(*)begin
	if(in_valid)begin
		stage2_add_wire[0] = stage2_reg[0]+stage2_reg[1];
		stage2_add_wire[1] = stage2_reg[2]+stage2_reg[3];
	end
	else begin
		stage2_add_wire[0] = 0;
		stage2_add_wire[1] = 0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			stage3_reg[i]<=0;
	else if(!in_valid)
		for(i=0;i<4;i=i+1)
			stage3_reg[i]<=0;
	else begin
		stage3_reg[0]<=stage2_reg[0];
		stage3_reg[1]<=stage2_add_wire[0];
		stage3_reg[2]<=stage2_reg[2];
		stage3_reg[3]<=stage2_add_wire[1];
	end
end

always@(*)begin
	if(in_valid)begin
		stage3_add_wire[0] = stage3_reg[1]+stage3_reg[2];
		stage3_add_wire[1] = stage3_reg[1]+stage3_reg[3];
	end
	else begin
		stage3_add_wire[0] = 0;
		stage3_add_wire[1] = 0;
	end
end



always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			stage4_reg[i]<=0;
	else if(!in_valid)
		for(i=0;i<4;i=i+1)
			stage4_reg[i]<=0;
	else begin
		stage4_reg[0]<=stage3_reg[0];
		stage4_reg[1]<=stage3_reg[1];
		stage4_reg[2]<=stage3_add_wire[0];
		stage4_reg[3]<=stage3_add_wire[1];
	end
end

always@(*)begin
	if(in_valid)begin
		stage4_cmp_wire[0] = (stage4_reg[0]<stage4_reg[1])?stage4_reg[1]:stage4_reg[0];
		stage4_cmp_wire[1] = (stage4_reg[2]<stage4_reg[3])?stage4_reg[3]:stage4_reg[2];
	end
	else begin
		stage4_cmp_wire[0] = 0;
		stage4_cmp_wire[1] = 0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<3;i=i+1)
			stage5_reg[i]<=0;
	else if(!in_valid)
		for(i=0;i<3;i=i+1)
			stage5_reg[i]<=0;
	else begin
		case(window_reg)
			0:begin
				stage5_reg[0]<=stage4_cmp_wire[0];
				stage5_reg[1]<=stage4_cmp_wire[1];
				stage5_reg[2]<=stage4_reg[3];
			end
			1:begin
				if(stage4_idx_reg[0]==252)begin
					stage5_reg[0]<=stage4_cmp_wire[0];
					stage5_reg[1]<=0;
					stage5_reg[2]<=stage4_reg[3];
				end
				else begin
					stage5_reg[0]<=stage4_cmp_wire[0];
					stage5_reg[1]<=stage4_cmp_wire[1];
					stage5_reg[2]<=stage4_reg[3];
				end
			end
			2:begin
				if(stage4_idx_reg[2]==252)begin
					stage5_reg[0]<=stage4_cmp_wire[0];
					stage5_reg[1]<=stage4_reg[2];
					stage5_reg[2]<=stage4_reg[3];
				end
				else begin
					stage5_reg[0]<=stage4_cmp_wire[0];
					stage5_reg[1]<=stage4_cmp_wire[1];
					stage5_reg[2]<=stage4_reg[3];
				end
			end
			3:begin
				if(stage4_idx_reg[2]>248)begin
					stage5_reg[0]<=0;
					stage5_reg[1]<=0;
					stage5_reg[2]<=stage4_reg[3];
				end
				else begin
					stage5_reg[0]<=stage4_cmp_wire[0];
					stage5_reg[1]<=stage4_cmp_wire[1];
					stage5_reg[2]<=stage4_reg[3];
				end
			end
			default:begin
				stage5_reg[0]<=0;
				stage5_reg[1]<=0;
				stage5_reg[2]<=0;
			end	
		endcase
	end
end

always@(*)begin
	if(in_valid)begin
		stage5_cmp_wire = (stage5_reg[0]<stage5_reg[1])?stage5_reg[1]:stage5_reg[0];
	end
	else begin
		stage5_cmp_wire = 0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<2;i=i+1)
			stage6_reg[i]<=0;
	else if(!in_valid)
		for(i=0;i<2;i=i+1)
			stage6_reg[i]<=0;		
	else begin
		stage6_reg[0]<=stage5_cmp_wire;
		stage6_reg[1]<=stage5_reg[2];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		stage7_reg[0]<=0;
		stage7_reg[1]<=0;
	end
	else if(!in_valid)begin
		stage7_reg[0]<=0;
		stage7_reg[1]<=0;
	end
	else if(!round_done_signal[7])begin
		stage7_reg[0]<=stage6_reg[0];
		stage7_reg[1]<=stage6_reg[1];
	end
	else begin
		stage7_reg[0]<=stage7_reg[1]+stage6_reg[0];
		stage7_reg[1]<=stage7_reg[1]+stage6_reg[1];
	end
end

always@(*)begin
	if(in_valid)begin
		case(window_reg)
			0:stage7_cmp_wire = (stage7_reg[0]>stage8_reg)?stage7_reg[0]:stage8_reg;
			1:begin
				if(stage7_idx_reg<255)
					stage7_cmp_wire = (stage7_reg[0]>stage8_reg)?stage7_reg[0]:stage8_reg;
				else
					stage7_cmp_wire = stage8_reg;
			end
			2:begin
				if(stage7_idx_reg<253)
					stage7_cmp_wire = (stage7_reg[0]>stage8_reg)?stage7_reg[0]:stage8_reg;
				else
					stage7_cmp_wire = stage8_reg;
			end
			3:begin
				if(stage7_idx_reg<249)
					stage7_cmp_wire = (stage7_reg[0]>stage8_reg)?stage7_reg[0]:stage8_reg;
				else
					stage7_cmp_wire = stage8_reg;
			end
			default:stage7_cmp_wire = 0;
		endcase
	end
		
	else
		stage7_cmp_wire = 0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		stage8_reg<=0;
	end
	else if(!in_valid)begin
		stage8_reg<=0;
	end
	else if(!round_done_signal[8])begin
		stage8_reg<=stage7_reg[0];
	end
	else begin
		stage8_reg<=stage7_cmp_wire;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		for(i=0;i<4;i=i+1)
			stage4_idx_reg[i]<=0;
	else if(!in_valid)
		for(i=0;i<4;i=i+1)
			stage4_idx_reg[i]<=0;
	else begin
		case(window_reg)
			0:begin
				stage4_idx_reg[0] <= (counter-3)*4+1;
				stage4_idx_reg[1] <= (counter-3)*4+2;
				stage4_idx_reg[2] <= (counter-3)*4+3;
				stage4_idx_reg[3] <= (counter-3)*4+4;
			end
			1:begin
				stage4_idx_reg[0] <= (counter-3)*4;
				stage4_idx_reg[1] <= (counter-3)*4+1;
				stage4_idx_reg[2] <= (counter-3)*4+2;
				stage4_idx_reg[3] <= (counter-3)*4+3;
			end
			2:begin
				stage4_idx_reg[0] <= (counter-3)*4-2;
				stage4_idx_reg[1] <= (counter-3)*4-1;
				stage4_idx_reg[2] <= (counter-3)*4;
				stage4_idx_reg[3] <= (counter-3)*4+1;
			end
			3:begin
				stage4_idx_reg[0] <= (counter-3)*4-6;
				stage4_idx_reg[1] <= (counter-3)*4-5;
				stage4_idx_reg[2] <= (counter-3)*4-4;
				stage4_idx_reg[3] <= (counter-3)*4-3;
			end
			default:begin
				stage4_idx_reg[0] <= 0;
				stage4_idx_reg[1] <= 0;
				stage4_idx_reg[2] <= 0;
				stage4_idx_reg[3] <= 0;
			end
		endcase
		
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		stage5_idx_reg[0]<=0;
	else if(!in_valid)
		stage5_idx_reg[0]<=0;
	else begin
		case(window_reg)
			0:begin
				if(stage4_reg[0]<stage4_reg[1])
					stage5_idx_reg[0]<=stage4_idx_reg[1];
				else
					stage5_idx_reg[0]<=stage4_idx_reg[0];
			end
			1:begin
				if(stage4_reg[0]<stage4_reg[1])
					stage5_idx_reg[0]<=stage4_idx_reg[1];
				else
					stage5_idx_reg[0]<=stage4_idx_reg[0];
			end
			2:begin
				if(stage4_reg[0]<stage4_reg[1])
					stage5_idx_reg[0]<=stage4_idx_reg[1];
				else
					stage5_idx_reg[0]<=stage4_idx_reg[0];
			end
			3:begin
				if(stage4_idx_reg[2]>248)begin
					stage5_idx_reg[0]<=0;
				end
				else if(stage4_reg[0]<stage4_reg[1])
					stage5_idx_reg[0]<=stage4_idx_reg[1];
				else
					stage5_idx_reg[0]<=stage4_idx_reg[0];
			end
			default:begin
				stage5_idx_reg[0]<=0;
			end	
		endcase
	end	
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		stage5_idx_reg[1]<=0;
	else if(!in_valid)
		stage5_idx_reg[1]<=0;
	else begin
		case(window_reg)
			0:begin
				if(stage4_reg[2]<stage4_reg[3])
					stage5_idx_reg[1]<=stage4_idx_reg[3];
				else
					stage5_idx_reg[1]<=stage4_idx_reg[2];
			end
			1:begin
				if(stage4_idx_reg[0]==252)begin
					stage5_idx_reg[1]<=0;
				end
				else if(stage4_reg[2]<stage4_reg[3])
					stage5_idx_reg[1]<=stage4_idx_reg[3];
				else
					stage5_idx_reg[1]<=stage4_idx_reg[2];
			end
			2:begin
				if(stage4_idx_reg[2]==252)begin
					stage5_idx_reg[1]<=stage4_idx_reg[2];
				end
				else if(stage4_reg[2]<stage4_reg[3])
					stage5_idx_reg[1]<=stage4_idx_reg[3];
				else
					stage5_idx_reg[1]<=stage4_idx_reg[2];
			end
			3:begin
				if(stage4_idx_reg[2]>248)begin
					stage5_idx_reg[1]<=0;
				end
				else if(stage4_reg[2]<stage4_reg[3])
					stage5_idx_reg[1]<=stage4_idx_reg[3];
				else
					stage5_idx_reg[1]<=stage4_idx_reg[2];
			end
			default:stage5_idx_reg[1]<=0;
		endcase
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		stage6_idx_reg<=0;
	else if(!in_valid)
		stage6_idx_reg<=0;
	else begin
		if(stage5_reg[0]<stage5_reg[1])
			stage6_idx_reg<=stage5_idx_reg[1];
		else
			stage6_idx_reg<=stage5_idx_reg[0];
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		stage7_idx_reg<=0;
	else if(!in_valid)
		stage7_idx_reg<=0;
	else begin
		stage7_idx_reg<=stage6_idx_reg;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		stage8_idx_reg<=0;
	else if(!in_valid)
		stage8_idx_reg<=0;
	else if(!round_done_signal[8])begin
		if(window_reg==3)
			stage8_idx_reg<=0;
		else if(window_reg==0 && stage7_idx_reg==0)
			stage8_idx_reg<=stage8_idx_reg;
		else
			stage8_idx_reg<=stage7_idx_reg;
	end
	else begin
		case(window_reg)
			0:begin
				if(!round_done_signal[7] && stage7_idx_reg==0)
					stage8_idx_reg<=stage8_idx_reg;
				else
					stage8_idx_reg <= (stage7_reg[0]>stage8_reg)?stage7_idx_reg:stage8_idx_reg;
			end
			1:begin
				if(stage7_idx_reg<255)
					stage8_idx_reg <= (stage7_reg[0]>stage8_reg)?stage7_idx_reg:stage8_idx_reg;
			end
			2:begin
				if(stage7_idx_reg<253)
					stage8_idx_reg <= (stage7_reg[0]>stage8_reg)?stage7_idx_reg:stage8_idx_reg;
			end
			3:begin
				if(stage7_idx_reg<249)
					stage8_idx_reg <= (stage7_reg[0]>stage8_reg)?stage7_idx_reg:stage8_idx_reg;
			end
			default: stage8_idx_reg<=0;
		endcase
	end
end

assign out_id = stage8_idx_reg==0?1:stage8_idx_reg;

always@(*)begin
	if(!round_done_signal[8])
		out_valid = 1;
	else
		out_valid = 0;
end

endmodule