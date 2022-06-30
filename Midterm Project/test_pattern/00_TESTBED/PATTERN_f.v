`ifdef RTL
    `define CYCLE_TIME 5
`endif
`ifdef GATE
    `define CYCLE_TIME 3.7
`endif

`include "../00_TESTBED/pseudo_DRAM.v"


module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
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
    awid_s_inf,
    awaddr_s_inf,
    awsize_s_inf,
    awburst_s_inf,
    awlen_s_inf,
    awvalid_s_inf,
    awready_s_inf,

    wdata_s_inf,
    wlast_s_inf,
    wvalid_s_inf,
    wready_s_inf,

    bid_s_inf,
    bresp_s_inf,
    bvalid_s_inf,
    bready_s_inf,

    arid_s_inf,
    araddr_s_inf,
    arlen_s_inf,
    arsize_s_inf,
    arburst_s_inf,
    arvalid_s_inf,

    arready_s_inf, 
    rid_s_inf,
    rdata_s_inf,
    rresp_s_inf,
    rlast_s_inf,
    rvalid_s_inf,
    rready_s_inf 
);

// ===============================================================
//                      Input / Output 
// ===============================================================

// << CHIP io port with system >>
output reg              clk, rst_n;
output reg              in_valid;
output reg              start;
output reg [15:0]       stop;     
output reg [1:0]        window; 
output reg              mode;
output reg [4:0]        frame_id;
input                   busy;       

// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1)     axi write address channel 
//         src master
input wire [ID_WIDTH-1:0]      awid_s_inf;
input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
input wire [2:0]             awsize_s_inf;
input wire [1:0]            awburst_s_inf;
input wire [7:0]              awlen_s_inf;
input wire                  awvalid_s_inf;
//         src slave
output wire                 awready_s_inf;
// -----------------------------

// (2)    axi write data channel 
//         src master
input wire [DATA_WIDTH-1:0]   wdata_s_inf;
input wire                    wlast_s_inf;
input wire                   wvalid_s_inf;
//         src slave
output wire                  wready_s_inf;

// (3)    axi write response channel 
//         src slave
output wire  [ID_WIDTH-1:0]     bid_s_inf;
output wire  [1:0]            bresp_s_inf;
output wire                  bvalid_s_inf;
//         src master 
input wire                   bready_s_inf;
// -----------------------------

// (4)    axi read address channel 
//         src master
input wire [ID_WIDTH-1:0]      arid_s_inf;
input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
input wire [7:0]              arlen_s_inf;
input wire [2:0]             arsize_s_inf;
input wire [1:0]            arburst_s_inf;
input wire                  arvalid_s_inf;
//         src slave
output wire                 arready_s_inf;
// -----------------------------

// (5)    axi read data channel 
//         src slave
output wire [ID_WIDTH-1:0]      rid_s_inf;
output wire [DATA_WIDTH-1:0]  rdata_s_inf;
output wire [1:0]             rresp_s_inf;
output wire                   rlast_s_inf;
output wire                  rvalid_s_inf;
//         src master
input wire                   rready_s_inf;


wire [7:0]test_dram0 =u_DRAM.DRAM_r['h2f1f0][7:0] ;
wire [7:0]test_dram1 =u_DRAM.DRAM_r['h2f1f1][7:0] ;
wire [7:0]test_dram2 =u_DRAM.DRAM_r['h2f1f2][7:0] ;
wire [7:0]test_dram3 =u_DRAM.DRAM_r['h2f1f3][7:0] ;
wire [7:0]test_dram4 =u_DRAM.DRAM_r['h2f1f4][7:0] ;
wire [7:0]test_dram5 =u_DRAM.DRAM_r['h2f1f5][7:0] ;
wire [7:0]test_dram6 =u_DRAM.DRAM_r['h2f1f6][7:0] ;
wire [7:0]test_dram7 =u_DRAM.DRAM_r['h2f1f7][7:0] ;
wire [7:0]test_dram8 =u_DRAM.DRAM_r['h2f1f8][7:0] ;
wire [7:0]test_dram9 =u_DRAM.DRAM_r['h2f1f9][7:0] ;
wire [7:0]test_dram10 =u_DRAM.DRAM_r['h2f1fa][7:0] ;
wire [7:0]test_dram11 =u_DRAM.DRAM_r['h2f1fb][7:0] ;
wire [7:0]test_dram12 =u_DRAM.DRAM_r['h2f1fc][7:0] ;
wire [7:0]test_dram13 =u_DRAM.DRAM_r['h2f1fd][7:0] ;
wire [7:0]test_dram14 =u_DRAM.DRAM_r['h2f1fe][7:0] ;
wire [7:0]test_dram15 =u_DRAM.DRAM_r['h2f1ff][7:0] ;

// -------------------------//
//     DRAM Connection      //
//--------------------------//

pseudo_DRAM u_DRAM(
    .clk(clk),
    .rst_n(rst_n),

    .   awid_s_inf(   awid_s_inf),
    . awaddr_s_inf( awaddr_s_inf),
    . awsize_s_inf( awsize_s_inf),
    .awburst_s_inf(awburst_s_inf),
    .  awlen_s_inf(  awlen_s_inf),
    .awvalid_s_inf(awvalid_s_inf),
    .awready_s_inf(awready_s_inf),

    .  wdata_s_inf(  wdata_s_inf),
    .  wlast_s_inf(  wlast_s_inf),
    . wvalid_s_inf( wvalid_s_inf),
    . wready_s_inf( wready_s_inf),

    .    bid_s_inf(    bid_s_inf),
    .  bresp_s_inf(  bresp_s_inf),
    . bvalid_s_inf( bvalid_s_inf),
    . bready_s_inf( bready_s_inf),

    .   arid_s_inf(   arid_s_inf),
    . araddr_s_inf( araddr_s_inf),
    .  arlen_s_inf(  arlen_s_inf),
    . arsize_s_inf( arsize_s_inf),
    .arburst_s_inf(arburst_s_inf),
    .arvalid_s_inf(arvalid_s_inf),
    .arready_s_inf(arready_s_inf), 

    .    rid_s_inf(    rid_s_inf),
    .  rdata_s_inf(  rdata_s_inf),
    .  rresp_s_inf(  rresp_s_inf),
    .  rlast_s_inf(  rlast_s_inf),
    . rvalid_s_inf( rvalid_s_inf),
    . rready_s_inf( rready_s_inf) 
);

    // initialize DRAM: $readmemh("../00_TESTBED/dram.dat", u_DRAM.DRAM_r);
    // direct access DRAM: u_DRAM.DRAM_r[addr][7:0];

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
real CYCLE = `CYCLE_TIME;
integer PATNUM, patcount, seed, gap, k, j, i, input_file, cycles, total_cycles;
integer time_num, window_in, mode_in, frame_id_in, input_time_in, distnat_max_in, distnat_pos_in, input_time_select;
//================================================================
// Wire & Reg Declaration
//================================================================
reg [7:0] histogram_in[15:0][255:0], histogram_backup[4095:0];
reg [3:0] first, second;
reg find;
reg flag;
//================================================================
// Clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// Initial
//================================================================
initial begin
	total_cycles = 0;
    rst_n       = 1'b1;
    in_valid    = 1'bx;
    start       = 1'bx;
    stop        = 16'bx;
    window      = 2'bx;
    mode        = 1'bx;
	frame_id    = 5'bx;
	find        = 0;
	force clk = 0;
    
	$readmemh("../00_TESTBED/dram.dat", u_DRAM.DRAM_r);
	
	reset_task;
    input_file  = $fopen("../00_TESTBED/dram_data/input.txt","r");
    j = $fscanf (input_file, "%d", seed);
	j = $fscanf (input_file, "%d", PATNUM);
    @(negedge clk);
    
    for (patcount=0;patcount<PATNUM;patcount=patcount+1) begin          
        input_data;

		while (busy === 0) begin
			cycles = cycles + 1;
			@(negedge clk);
		end

		while (busy === 1) begin
			cycles = cycles + 1;
			@(negedge clk);
		end

		check_dram;
		if (find) begin #(1000) $finish; end
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,cycles);
		total_cycles = total_cycles + cycles;
    end
    #(1000);
    YOU_PASS_task;
    $finish;
end 

task reset_task ; begin
	#(10); rst_n = 0;
	#(10); rst_n = 1;
		   in_valid = 1'b0;
	#(3.0); release clk;
end endtask

task input_data; begin

	cycles = 0;
	j = $fscanf (input_file, "%d", time_num); 
	j = $fscanf (input_file, "%d", window_in); 
	j = $fscanf (input_file, "%d", mode_in); 
	j = $fscanf (input_file, "%d", frame_id_in); 

	for (k = 0; k < 16; k = k + 1) begin
		for (i = 0; i < 255; i = i + 1) begin
			j = $fscanf (input_file, "%d", histogram_in[k][i]); 
			histogram_backup[k * 256 + i] = histogram_in[k][i];
		end	
	end

	j = $fscanf (input_file, "%d", input_time_in ); 

	for (k = 0; k < 16; k = k + 1) begin
		j = $fscanf (input_file, "%d", histogram_backup[(k+1) * 256 - 1]); 
	end

	gap = $urandom_range(3,10);
	repeat(gap) @(negedge clk);
	in_valid    = 1'b1;
	start       = 1'b0;
	stop        = 16'b0;
	window      = window_in;
	mode        = mode_in;
	frame_id    = frame_id_in;
	@(negedge clk);

	

	if (mode_in === 0) begin

		input_time_select = (input_time_in > 4) ? input_time_in : 4;
		for (j = 0; j < input_time_select; j = j + 1) begin
			
			if (j == 0) begin
				window      = 2'bx;
				mode        = 1'bx;
				frame_id    = 5'bx;
				gap = $urandom_range(2,9);
			end
			else gap = $urandom_range(3,10);
			
			repeat(gap) @(negedge clk);
			start       = 1'b1;

			for (i = 0; i < 255; i = i + 1) begin
				for (k = 0; k < 16; k = k + 1) begin
					if (histogram_in[k][i] > 0) begin
						stop[k] = 1'b1;
						histogram_in[k][i] = histogram_in[k][i] - 1;
					end
					else stop[k] = 1'b0;
				end

				@(negedge clk);
			end

			start  = 1'b0;
			stop   = 16'b0;
		end
	end
	else begin
		window      = 2'bx;
		mode        = 1'bx;
		frame_id    = 5'bx;

		if (time_num === 0) $readmemh("../00_TESTBED/dram_data/dram_mode0.dat", u_DRAM.DRAM_r);
		if (time_num === 1) $readmemh("../00_TESTBED/dram_data/dram_mode1.dat", u_DRAM.DRAM_r);
		if (time_num === 2) $readmemh("../00_TESTBED/dram_data/dram_mode2.dat", u_DRAM.DRAM_r);
		if (time_num === 3) $readmemh("../00_TESTBED/dram_data/dram_mode3.dat", u_DRAM.DRAM_r);
		if (time_num === 4) $readmemh("../00_TESTBED/dram_data/dram_mode4.dat", u_DRAM.DRAM_r);
		if (time_num === 5) $readmemh("../00_TESTBED/dram_data/dram_mode5.dat", u_DRAM.DRAM_r);
		if (time_num === 6) $readmemh("../00_TESTBED/dram_data/dram_mode6.dat", u_DRAM.DRAM_r);
		if (time_num === 7) $readmemh("../00_TESTBED/dram_data/dram_mode7.dat", u_DRAM.DRAM_r);
		if (time_num === 8) $readmemh("../00_TESTBED/dram_data/dram_mode8.dat", u_DRAM.DRAM_r);
		if (time_num === 9) $readmemh("../00_TESTBED/dram_data/dram_mode9.dat", u_DRAM.DRAM_r);
		if (time_num === 10) $readmemh("../00_TESTBED/dram_data/dram_mode10.dat", u_DRAM.DRAM_r);
		if (time_num === 11) $readmemh("../00_TESTBED/dram_data/dram_mode11.dat", u_DRAM.DRAM_r);
		if (time_num === 12) $readmemh("../00_TESTBED/dram_data/dram_mode12.dat", u_DRAM.DRAM_r);
		if (time_num === 13) $readmemh("../00_TESTBED/dram_data/dram_mode13.dat", u_DRAM.DRAM_r);
		if (time_num === 14) $readmemh("../00_TESTBED/dram_data/dram_mode14.dat", u_DRAM.DRAM_r);
		if (time_num === 15) $readmemh("../00_TESTBED/dram_data/dram_mode15.dat", u_DRAM.DRAM_r);
		if (time_num === 16) $readmemh("../00_TESTBED/dram_data/dram_mode16.dat", u_DRAM.DRAM_r);
		if (time_num === 17) $readmemh("../00_TESTBED/dram_data/dram_mode17.dat", u_DRAM.DRAM_r);
		if (time_num === 18) $readmemh("../00_TESTBED/dram_data/dram_mode18.dat", u_DRAM.DRAM_r);
		if (time_num === 19) $readmemh("../00_TESTBED/dram_data/dram_mode19.dat", u_DRAM.DRAM_r);
		if (time_num === 20) $readmemh("../00_TESTBED/dram_data/dram_mode20.dat", u_DRAM.DRAM_r);
		if (time_num === 21) $readmemh("../00_TESTBED/dram_data/dram_mode21.dat", u_DRAM.DRAM_r);
		if (time_num === 22) $readmemh("../00_TESTBED/dram_data/dram_mode22.dat", u_DRAM.DRAM_r);
		if (time_num === 23) $readmemh("../00_TESTBED/dram_data/dram_mode23.dat", u_DRAM.DRAM_r);
		if (time_num === 24) $readmemh("../00_TESTBED/dram_data/dram_mode24.dat", u_DRAM.DRAM_r);
		if (time_num === 25) $readmemh("../00_TESTBED/dram_data/dram_mode25.dat", u_DRAM.DRAM_r);
		if (time_num === 26) $readmemh("../00_TESTBED/dram_data/dram_mode26.dat", u_DRAM.DRAM_r);
		if (time_num === 27) $readmemh("../00_TESTBED/dram_data/dram_mode27.dat", u_DRAM.DRAM_r);
		if (time_num === 28) $readmemh("../00_TESTBED/dram_data/dram_mode28.dat", u_DRAM.DRAM_r);
		if (time_num === 29) $readmemh("../00_TESTBED/dram_data/dram_mode29.dat", u_DRAM.DRAM_r);
		if (time_num === 30) $readmemh("../00_TESTBED/dram_data/dram_mode30.dat", u_DRAM.DRAM_r);
		if (time_num === 31) $readmemh("../00_TESTBED/dram_data/dram_mode31.dat", u_DRAM.DRAM_r);
		if (time_num === 32) $readmemh("../00_TESTBED/dram_data/dram_mode32.dat", u_DRAM.DRAM_r);
		if (time_num === 33) $readmemh("../00_TESTBED/dram_data/dram_mode33.dat", u_DRAM.DRAM_r);
		if (time_num === 34) $readmemh("../00_TESTBED/dram_data/dram_mode34.dat", u_DRAM.DRAM_r);
		if (time_num === 35) $readmemh("../00_TESTBED/dram_data/dram_mode35.dat", u_DRAM.DRAM_r);
		if (time_num === 36) $readmemh("../00_TESTBED/dram_data/dram_mode36.dat", u_DRAM.DRAM_r);
		if (time_num === 37) $readmemh("../00_TESTBED/dram_data/dram_mode37.dat", u_DRAM.DRAM_r);
		if (time_num === 38) $readmemh("../00_TESTBED/dram_data/dram_mode38.dat", u_DRAM.DRAM_r);
		if (time_num === 39) $readmemh("../00_TESTBED/dram_data/dram_mode39.dat", u_DRAM.DRAM_r);
		if (time_num === 40) $readmemh("../00_TESTBED/dram_data/dram_mode40.dat", u_DRAM.DRAM_r);
		if (time_num === 41) $readmemh("../00_TESTBED/dram_data/dram_mode41.dat", u_DRAM.DRAM_r);
		if (time_num === 42) $readmemh("../00_TESTBED/dram_data/dram_mode42.dat", u_DRAM.DRAM_r);
		if (time_num === 43) $readmemh("../00_TESTBED/dram_data/dram_mode43.dat", u_DRAM.DRAM_r);
		if (time_num === 44) $readmemh("../00_TESTBED/dram_data/dram_mode44.dat", u_DRAM.DRAM_r);
		if (time_num === 45) $readmemh("../00_TESTBED/dram_data/dram_mode45.dat", u_DRAM.DRAM_r);
		if (time_num === 46) $readmemh("../00_TESTBED/dram_data/dram_mode46.dat", u_DRAM.DRAM_r);
		if (time_num === 47) $readmemh("../00_TESTBED/dram_data/dram_mode47.dat", u_DRAM.DRAM_r);
		if (time_num === 48) $readmemh("../00_TESTBED/dram_data/dram_mode48.dat", u_DRAM.DRAM_r);
		if (time_num === 49) $readmemh("../00_TESTBED/dram_data/dram_mode49.dat", u_DRAM.DRAM_r);
		if (time_num === 50) $readmemh("../00_TESTBED/dram_data/dram_mode50.dat", u_DRAM.DRAM_r);
		if (time_num === 51) $readmemh("../00_TESTBED/dram_data/dram_mode51.dat", u_DRAM.DRAM_r);
		if (time_num === 52) $readmemh("../00_TESTBED/dram_data/dram_mode52.dat", u_DRAM.DRAM_r);
		if (time_num === 53) $readmemh("../00_TESTBED/dram_data/dram_mode53.dat", u_DRAM.DRAM_r);
		if (time_num === 54) $readmemh("../00_TESTBED/dram_data/dram_mode54.dat", u_DRAM.DRAM_r);
		if (time_num === 55) $readmemh("../00_TESTBED/dram_data/dram_mode55.dat", u_DRAM.DRAM_r);
		if (time_num === 56) $readmemh("../00_TESTBED/dram_data/dram_mode56.dat", u_DRAM.DRAM_r);
		if (time_num === 57) $readmemh("../00_TESTBED/dram_data/dram_mode57.dat", u_DRAM.DRAM_r);
		if (time_num === 58) $readmemh("../00_TESTBED/dram_data/dram_mode58.dat", u_DRAM.DRAM_r);
		if (time_num === 59) $readmemh("../00_TESTBED/dram_data/dram_mode59.dat", u_DRAM.DRAM_r);
		if (time_num === 60) $readmemh("../00_TESTBED/dram_data/dram_mode60.dat", u_DRAM.DRAM_r);
		if (time_num === 61) $readmemh("../00_TESTBED/dram_data/dram_mode61.dat", u_DRAM.DRAM_r);
		if (time_num === 62) $readmemh("../00_TESTBED/dram_data/dram_mode62.dat", u_DRAM.DRAM_r);
		if (time_num === 63) $readmemh("../00_TESTBED/dram_data/dram_mode63.dat", u_DRAM.DRAM_r);
		if (time_num === 64) $readmemh("../00_TESTBED/dram_data/dram_mode64.dat", u_DRAM.DRAM_r);
		if (time_num === 65) $readmemh("../00_TESTBED/dram_data/dram_mode65.dat", u_DRAM.DRAM_r);
		if (time_num === 66) $readmemh("../00_TESTBED/dram_data/dram_mode66.dat", u_DRAM.DRAM_r);
		if (time_num === 67) $readmemh("../00_TESTBED/dram_data/dram_mode67.dat", u_DRAM.DRAM_r);
		if (time_num === 68) $readmemh("../00_TESTBED/dram_data/dram_mode68.dat", u_DRAM.DRAM_r);
		if (time_num === 69) $readmemh("../00_TESTBED/dram_data/dram_mode69.dat", u_DRAM.DRAM_r);
		if (time_num === 70) $readmemh("../00_TESTBED/dram_data/dram_mode70.dat", u_DRAM.DRAM_r);
		if (time_num === 71) $readmemh("../00_TESTBED/dram_data/dram_mode71.dat", u_DRAM.DRAM_r);
		if (time_num === 72) $readmemh("../00_TESTBED/dram_data/dram_mode72.dat", u_DRAM.DRAM_r);
		if (time_num === 73) $readmemh("../00_TESTBED/dram_data/dram_mode73.dat", u_DRAM.DRAM_r);
		if (time_num === 74) $readmemh("../00_TESTBED/dram_data/dram_mode74.dat", u_DRAM.DRAM_r);
		if (time_num === 75) $readmemh("../00_TESTBED/dram_data/dram_mode75.dat", u_DRAM.DRAM_r);
		if (time_num === 76) $readmemh("../00_TESTBED/dram_data/dram_mode76.dat", u_DRAM.DRAM_r);
		if (time_num === 77) $readmemh("../00_TESTBED/dram_data/dram_mode77.dat", u_DRAM.DRAM_r);
		if (time_num === 78) $readmemh("../00_TESTBED/dram_data/dram_mode78.dat", u_DRAM.DRAM_r);
		if (time_num === 79) $readmemh("../00_TESTBED/dram_data/dram_mode79.dat", u_DRAM.DRAM_r);
		if (time_num === 80) $readmemh("../00_TESTBED/dram_data/dram_mode80.dat", u_DRAM.DRAM_r);
		if (time_num === 81) $readmemh("../00_TESTBED/dram_data/dram_mode81.dat", u_DRAM.DRAM_r);
		if (time_num === 82) $readmemh("../00_TESTBED/dram_data/dram_mode82.dat", u_DRAM.DRAM_r);
		if (time_num === 83) $readmemh("../00_TESTBED/dram_data/dram_mode83.dat", u_DRAM.DRAM_r);
		if (time_num === 84) $readmemh("../00_TESTBED/dram_data/dram_mode84.dat", u_DRAM.DRAM_r);
		if (time_num === 85) $readmemh("../00_TESTBED/dram_data/dram_mode85.dat", u_DRAM.DRAM_r);
		if (time_num === 86) $readmemh("../00_TESTBED/dram_data/dram_mode86.dat", u_DRAM.DRAM_r);
		if (time_num === 87) $readmemh("../00_TESTBED/dram_data/dram_mode87.dat", u_DRAM.DRAM_r);
		if (time_num === 88) $readmemh("../00_TESTBED/dram_data/dram_mode88.dat", u_DRAM.DRAM_r);
		if (time_num === 89) $readmemh("../00_TESTBED/dram_data/dram_mode89.dat", u_DRAM.DRAM_r);
		if (time_num === 90) $readmemh("../00_TESTBED/dram_data/dram_mode90.dat", u_DRAM.DRAM_r);
		if (time_num === 91) $readmemh("../00_TESTBED/dram_data/dram_mode91.dat", u_DRAM.DRAM_r);
		if (time_num === 92) $readmemh("../00_TESTBED/dram_data/dram_mode92.dat", u_DRAM.DRAM_r);
		if (time_num === 93) $readmemh("../00_TESTBED/dram_data/dram_mode93.dat", u_DRAM.DRAM_r);
		if (time_num === 94) $readmemh("../00_TESTBED/dram_data/dram_mode94.dat", u_DRAM.DRAM_r);
		if (time_num === 95) $readmemh("../00_TESTBED/dram_data/dram_mode95.dat", u_DRAM.DRAM_r);
		if (time_num === 96) $readmemh("../00_TESTBED/dram_data/dram_mode96.dat", u_DRAM.DRAM_r);
		if (time_num === 97) $readmemh("../00_TESTBED/dram_data/dram_mode97.dat", u_DRAM.DRAM_r);
		if (time_num === 98) $readmemh("../00_TESTBED/dram_data/dram_mode98.dat", u_DRAM.DRAM_r);
		if (time_num === 99) $readmemh("../00_TESTBED/dram_data/dram_mode99.dat", u_DRAM.DRAM_r);
		if (time_num === 100) $readmemh("../00_TESTBED/dram_data/dram_mode100.dat", u_DRAM.DRAM_r);
	end

	in_valid = 1'b0;
	start    = 1'bx;
	stop     = 16'bx;
end endtask

task check_dram; begin
	first = (frame_id_in >= 16) ? 4'h2 : 4'h1;
	second = frame_id_in % 16;

	//$display("%d %d %d", {first, second, 12'h000}, first, second);
	for(i = 0; i < 16*16*16; i = i + 1) begin
		if (u_DRAM.DRAM_r[({first, second, 12'h000} + i)] !== histogram_backup[i]) begin
			
			$display("time:   %3d", time_num);
			$display("mode:   %3d", mode_in);
			$display("window: %3d", window_in);
			$display("%d, %d, %d, , %h, %d, %d, %d", i, i / 256, i % 256, {first, second, 12'h000}  + i, {first, second, 12'h000}  + i, u_DRAM.DRAM_r[({first, second, 12'h000} + i)], histogram_backup[i]);
			find = 1;
		end
	end
end endtask

task YOU_PASS_task; begin
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						             ");
	$display ("                                           You have passed all patterns!          						             ");
	$display ("                                           Your execution cycles = %5d cycles   						                 ", total_cycles);
	$display ("                                           Your clock period = %.1f ns        					                     ", `CYCLE_TIME);
	$display ("                                           Your total latency = %.1f ns         						                 ", total_cycles*`CYCLE_TIME);
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;
end endtask

endmodule
