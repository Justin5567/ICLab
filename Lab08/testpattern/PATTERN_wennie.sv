`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
//      PARAMETERS FOR PATTERN CONTROL
//================================================================
parameter OUT_NUM   = 1;
parameter PATNUM    = 5000;
integer   SEED      = 122;

//================================================================
//      pseudo_DRAM
//================================================================
parameter DRAM_OFFSET = 'h10000;
parameter USER_NUM    = 256;
parameter DRAM_p_r    = "../00_TESTBED/DRAM/dram.dat";
logic [7:0] golden_DRAM[ (DRAM_OFFSET+0) : ((DRAM_OFFSET+USER_NUM*8)-1) ];
initial $readmemh( DRAM_p_r, golden_DRAM );

//================================================================
//      BAG PATAMETERS
//================================================================
parameter BERRY_BUY_COIN    = 16;
parameter MEDICINE_BUY_COIN = 128;
parameter CANDY_BUY_COIN    = 300;
parameter BRACER_BUY_COIN   = 64;
parameter STONE_BUY_COIN    = 800;

parameter BERRY_SELL_COIN    = 12;
parameter MEDICINE_SELL_COIN = 96;
parameter CANDY_SELL_COIN    = 225;
parameter BRACER_SELL_COIN   = 48;
parameter STONE_SELL_COIN    = 600;

//================================================================
//      PKM PATAMETERS
//================================================================
// GRASS
parameter GRASS_LOW_HP    = 128;
parameter GRASS_LOW_ATK   = 63;
parameter GRASS_LOW_EXP   = 32;
parameter GRASS_LOW_COIN  = 100;

parameter GRASS_MID_HP    = 192;
parameter GRASS_MID_ATK   = 94;
parameter GRASS_MID_EXP   = 63;
parameter GRASS_MID_COIN  = 510;

parameter GRASS_HIGH_HP   = 254;
parameter GRASS_HIGH_ATK  = 123;
parameter GRASS_HIGH_COIN = 1100;

// FIRE
parameter FIRE_LOW_HP    = 119;
parameter FIRE_LOW_ATK   = 64;
parameter FIRE_LOW_EXP   = 30;
parameter FIRE_LOW_COIN  = 90;

parameter FIRE_MID_HP    = 177;
parameter FIRE_MID_ATK   = 96;
parameter FIRE_MID_EXP   = 59;
parameter FIRE_MID_COIN  = 450;

parameter FIRE_HIGH_HP   = 225;
parameter FIRE_HIGH_ATK  = 127;
parameter FIRE_HIGH_COIN = 1000;

// WATER
parameter WATER_LOW_HP    = 125;
parameter WATER_LOW_ATK   = 60;
parameter WATER_LOW_EXP   = 28;
parameter WATER_LOW_COIN  = 110;

parameter WATER_MID_HP    = 187;
parameter WATER_MID_ATK   = 89;
parameter WATER_MID_EXP   = 55;
parameter WATER_MID_COIN  = 500;

parameter WATER_HIGH_HP   = 245;
parameter WATER_HIGH_ATK  = 113;
parameter WATER_HIGH_COIN = 1200;

// ElECTRIC
parameter ELEC_LOW_HP    = 122;
parameter ELEC_LOW_ATK   = 65;
parameter ELEC_LOW_EXP   = 26;
parameter ELEC_LOW_COIN  = 120;

parameter ELEC_MID_HP    = 182;
parameter ELEC_MID_ATK   = 97;
parameter ELEC_MID_EXP   = 51;
parameter ELEC_MID_COIN  = 550;

parameter ELEC_HIGH_HP   = 235;
parameter ELEC_HIGH_ATK  = 124;
parameter ELEC_HIGH_COIN = 1300;

// NORMAL
parameter NORM_LOW_HP    = 124;
parameter NORM_LOW_ATK   = 62;
parameter NORM_LOW_EXP   = 29;
parameter NORM_LOW_COIN  = 130;

//================================================================
//      PARAMETERS & VARIABLES
//================================================================
parameter DELAY     = 1200;

integer       i;
integer       j;
integer       m;
integer       n;

integer     pat;
integer    size;

integer total_lat;
integer   exe_lat;
integer   out_lat;

//pragma protect
//pragma protect begin
//================================================================
//      CACULATION REGISTER AND INTEGER
//================================================================
// Old Info
integer     add_clk_flag;
Player_id   old_id;
Player_Info player1_info;
Player_Info player1_old_info;
Player_Info player2_info;
Player_Info player2_old_info;

// Data input
Money       player1_money;
Player_id   player1_id;
Action      player1_act;
Item        player1_item;
PKM_Type    player1_type;
integer     pkm_price;
integer     item_price;
integer     money_chek;
// atk
integer     player1_atk_flag;
real        player1_atk_incr;
// exp
integer     player1_exp_incr = 0;
integer     player2_exp_incr = 0;

Player_id   player2_id;
integer     buy_flag;
integer     sell_flag;
// 0 is PKM
// 1 is Item

// Check Output
logic       gold_complete;
Error_Msg   gold_err_msg;
logic[63:0] gold_info;

logic       your_complete;
Error_Msg   your_err_msg;
logic[63:0] your_info;

integer dumy_flag;

//================================================================
//      CLASS RANDOM
//================================================================
class Id_R;
    rand Player_id id_r;
    function new ( int seed );
        this.srandom(seed);
    endfunction
    constraint range1{
        id_r inside { [0:255] };
    }
endclass

class Id_def_R;
    rand Player_id id_r;
    Player_id atk_player;
    function new ( int seed, Player_id in );
        this.srandom(seed);
        atk_player = in;
    endfunction
    constraint range1{
        !(id_r inside { atk_player });
    }
endclass

class Act_R;
    rand Action act_r;
    function new ( int seed );
        this.srandom(seed);
    endfunction 
    constraint range{
        act_r inside { Buy, Sell, Deposit, Use_item, Check, Attack };
    }
endclass

class Type_R;
    rand PKM_Type type_r;

    function new ( int seed );
        this.srandom(seed);
    endfunction 
    constraint range{
        type_r inside { Grass, Fire, Water, Electric, Normal };
    }    
endclass

class Item_R;
    rand Item item_r;
    function new ( int seed );
        this.srandom(seed);
    endfunction 
    constraint range{
        item_r inside { Berry, Medicine, Candy, Bracer, Water_stone, Fire_stone, Thunder_stone };
    }    
endclass

class Money_R;
    rand Money money_r;
    Money bound;
    function new ( int seed, Money in );
        this.srandom(seed);
        bound = in;
    endfunction 
    constraint range{
        money_r inside { [0:16383-bound] };
    }    
endclass

//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              TASKS
//======================================
//***************************
//      Execution Task
//***************************
task exe_task; begin
    reset_task;
    for ( pat=0 ; pat<PATNUM ; pat=pat+1 ) begin
        input_task;
        cal_task;
        wait_task;
        check_task;
        $display("\033[32mNo.%-5d PATTERN PASS!!! \033[1;34mLatency : %-5d\033[1;0m", pat, exe_lat);
    end
    pass_task;
end endtask

//***************************
//      Reset Task
//***************************
task reset_task; begin
    inf.rst_n      = 1;
    inf.id_valid   = 0;
    inf.act_valid  = 0;
    inf.item_valid = 0;
    inf.type_valid = 0;
    inf.amnt_valid = 0;
    inf.D          = 'dx;
    total_lat      = 0;

    player1_atk_flag = 0;

    #(10) inf.rst_n = 0;
    #(10) inf.rst_n = 1;
    if ( inf.out_valid !== 0 || inf.complete !== 0 || inf.err_msg !== 0 || inf.out_info !== 0 ) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(10);
        $finish;
    end
end endtask

//***************************
//      Input Task
//***************************
task input_task; begin
    repeat( ({$random(SEED)} % 9 + 2) ) @(negedge clk);
    add_clk_flag = 0;
    // Decide Player1 Id
    if(pat == 0) begin
        id_task;
        add_clk_flag = 1;
    end
    else if(({$random(SEED)} % 2) == 0) begin
        id_new_task;
        add_clk_flag = 1;
    end

    get_player_task(player1_id, player1_info);
    //display_player_task(player1_id, player1_info);
    if(old_id != player1_id)
        player1_atk_flag = 0;
    if(add_clk_flag == 1)
        repeat( ({$random(SEED)} % 5 + 1) ) @(negedge clk);

    // Decide Action
    act_task;

    case(player1_act)
        Buy      : begin
            repeat( ({$random(SEED)} % 5 + 1) ) @(negedge clk);
            buy_flag = {$random(SEED)} % 2;
            if(buy_flag == 0) type_task;
            else              item_task;
        end
        Sell     : begin
            repeat( ({$random(SEED)} % 5 + 1) ) @(negedge clk);
            sell_flag = {$random(SEED)} % 2;
            if(sell_flag == 0) type_task;
            else               item_task;
        end
        Deposit  : begin
            repeat( ({$random(SEED)} % 5 + 1) ) @(negedge clk);
            amnt_task;
        end
        Use_item : begin
            repeat( ({$random(SEED)} % 5 + 1) ) @(negedge clk);
            item_task;
        end
        Attack   : begin
            repeat( ({$random(SEED)} % 5 + 1) ) @(negedge clk);
            def_task;
            get_player_task(player2_id, player2_info);
            //display_player_task(player2_id, player2_info);
        end
    endcase
    // Display info for debug
    //display_act_task;

    //display_player_task(player1_id, player1_info);
    //if(player1_act == Attack)
    //    display_player_task(player2_id, player2_info);
end endtask

task id_task; begin
    // Random Class
    Id_R rId = new(SEED);

    // Valid
    inf.id_valid = 1'b1;
    void'(rId.randomize());
    player1_id = rId.id_r;
    inf.D = { 8'd0, player1_id };
    
    @(negedge clk);
    inf.id_valid = 1'b0;
    inf.D = 'dx;
end endtask

task id_new_task; begin
    // Random Class
    Id_def_R rId = new(SEED, player1_id);

    // Valid
    inf.id_valid = 1'b1;
    void'(rId.randomize());
    player1_id = rId.id_r;
    inf.D = { 8'd0, player1_id };
    
    @(negedge clk);
    inf.id_valid = 1'b0;
    inf.D = 'dx;
end endtask

task def_task; begin
    // Random Class
    Id_def_R rId = new(SEED, player1_id);

    // Valid
    inf.id_valid = 1'b1;
    void'(rId.randomize());
    player2_id = rId.id_r;
    inf.D = { 8'd0, player2_id };
    
    @(negedge clk);
    inf.id_valid = 1'b0;
    inf.D = 'dx;
end endtask

task act_task; begin
    // Random Class
    Act_R rAct = new(SEED);

    // Valid
    inf.act_valid = 1'b1;
    void'(rAct.randomize());
    player1_act = rAct.act_r;
    // Money is too much to sell
    // Select another action
    while(player1_info.bag_info.money > (10000) && player1_act==Sell ) begin
        void'(rAct.randomize());
        player1_act = rAct.act_r;
    end
    inf.D = { 12'd0, player1_act };
    
    @(negedge clk);
    inf.act_valid = 1'b0;
    inf.D = 'dx;
end endtask

task item_task; begin
    // Random Class
    Item_R  rItem  = new(SEED);

    // Valid
    inf.item_valid = 1'b1;
    void'(rItem.randomize());
    player1_item = rItem.item_r;
    inf.D = { 12'd0, player1_item };
    
    @(negedge clk);
    inf.item_valid = 1'b0;
    inf.D = 'dx;
end endtask

task type_task; begin
    // Random Class
    Type_R  rType  = new(SEED);

    // Valid
    inf.type_valid = 1'b1;
    void'(rType.randomize());
    player1_type = rType.type_r;
    inf.D = { 12'd0, player1_type };
    
    @(negedge clk);
    inf.type_valid = 1'b0;
    inf.D = 'dx;
end endtask

task amnt_task; begin
    // Random Class
    Money_R rMoney = new(SEED, player1_info.bag_info.money);

    // Valid
    inf.amnt_valid = 1'b1;
    void'(rMoney.randomize());
    player1_money = rMoney.money_r;
    inf.D = { 12'd0, player1_money };
    
    @(negedge clk);
    inf.amnt_valid = 1'b0;
    inf.D = 'dx;
end endtask

//**************************************************************************************************************************************************************
//      Player Task
//**************************************************************************************************************************************************************
task get_player_task;
    input Player_id    in_id;
    output Player_Info out_info;
begin
    out_info.bag_info.berry_num    = Item_num'( golden_DRAM[ (DRAM_OFFSET+in_id*8)   ][7:4]);
    out_info.bag_info.medicine_num = Item_num'( golden_DRAM[ (DRAM_OFFSET+in_id*8)   ][3:0]);
    out_info.bag_info.candy_num    = Item_num'( golden_DRAM[ (DRAM_OFFSET+in_id*8+1) ][7:4]);
    out_info.bag_info.bracer_num   = Item_num'( golden_DRAM[ (DRAM_OFFSET+in_id*8+1) ][3:0]);
    out_info.bag_info.stone        =    Stone'( golden_DRAM[ (DRAM_OFFSET+in_id*8+2) ][7:6]);
    out_info.bag_info.money        =    Money'({golden_DRAM[ (DRAM_OFFSET+in_id*8+2) ][5:0], golden_DRAM[ (DRAM_OFFSET+in_id*8+3) ]});

    out_info.pkm_info.stage        =    Stage'( golden_DRAM[ (DRAM_OFFSET+in_id*8+4) ][7:4]);
    out_info.pkm_info.pkm_type     = PKM_Type'( golden_DRAM[ (DRAM_OFFSET+in_id*8+4) ][3:0]);
    out_info.pkm_info.hp           =       HP'( golden_DRAM[ (DRAM_OFFSET+in_id*8+5) ]);
    out_info.pkm_info.atk          =      ATK'( golden_DRAM[ (DRAM_OFFSET+in_id*8+6) ]);
    out_info.pkm_info.exp          =      EXP'( golden_DRAM[ (DRAM_OFFSET+in_id*8+7) ]);
end endtask

task set_player_task;
    input Player_id   in_id;
    input Player_Info in_info;
begin
    golden_DRAM[ (DRAM_OFFSET+in_id*8)   ][7:4] = in_info.bag_info.berry_num;
    golden_DRAM[ (DRAM_OFFSET+in_id*8)   ][3:0] = in_info.bag_info.medicine_num;
    golden_DRAM[ (DRAM_OFFSET+in_id*8+1) ][7:4] = in_info.bag_info.candy_num;
    golden_DRAM[ (DRAM_OFFSET+in_id*8+1) ][3:0] = in_info.bag_info.bracer_num;
    golden_DRAM[ (DRAM_OFFSET+in_id*8+2) ]      = {in_info.bag_info.stone, in_info.bag_info.money[13:8]};
    golden_DRAM[ (DRAM_OFFSET+in_id*8+3) ]      = in_info.bag_info.money[7:0];

    golden_DRAM[ (DRAM_OFFSET+in_id*8+4) ][7:4] = in_info.pkm_info.stage;
    golden_DRAM[ (DRAM_OFFSET+in_id*8+4) ][3:0] = in_info.pkm_info.pkm_type;
    golden_DRAM[ (DRAM_OFFSET+in_id*8+5) ]      = in_info.pkm_info.hp;
    golden_DRAM[ (DRAM_OFFSET+in_id*8+6) ]      = in_info.pkm_info.atk;
    golden_DRAM[ (DRAM_OFFSET+in_id*8+7) ]      = in_info.pkm_info.exp;
end endtask

//----------------------------------------------------------------------------------------------------------------------------------------//
// Evolve PKM Function
// TODO
// Normal
// Only use stone to evolve
task evolv_pkm_task;
    input PKM_Info  in_pkm_info;
    input integer   in_flag;
    output PKM_Info out_pkm_info;
    output integer  out_flag;
begin
    case(in_pkm_info.pkm_type)
        Grass: begin
            if(in_pkm_info.stage == Lowest && in_pkm_info.exp >= GRASS_LOW_EXP) begin
                in_pkm_info.exp   = 0;
                in_pkm_info.stage = Middle;
                in_pkm_info.hp    = GRASS_MID_HP;
                in_pkm_info.atk   = GRASS_MID_ATK;
                in_flag           = 0;
            end
            else if(in_pkm_info.stage == Middle && in_pkm_info.exp >= GRASS_MID_EXP) begin
                in_pkm_info.exp   = 0;
                in_pkm_info.stage = Highest;
                in_pkm_info.hp    = GRASS_HIGH_HP;
                in_pkm_info.atk   = GRASS_HIGH_ATK;
                in_flag           = 0;
            end
        end
        Fire: begin
            if(in_pkm_info.stage == Lowest && in_pkm_info.exp >= FIRE_LOW_EXP) begin
                in_pkm_info.exp   = 0;
                in_pkm_info.stage = Middle;
                in_pkm_info.hp    = FIRE_MID_HP;
                in_pkm_info.atk   = FIRE_MID_ATK;
                in_flag           = 0;
            end
            else if(in_pkm_info.stage == Middle && in_pkm_info.exp >= FIRE_MID_EXP) begin
                in_pkm_info.exp   = 0;
                in_pkm_info.stage = Highest;
                in_pkm_info.hp    = FIRE_HIGH_HP;
                in_pkm_info.atk   = FIRE_HIGH_ATK;
                in_flag           = 0;
            end
        end
        Water: begin
            if(in_pkm_info.stage == Lowest && in_pkm_info.exp >= WATER_LOW_EXP) begin
                in_pkm_info.exp   = 0;
                in_pkm_info.stage = Middle;
                in_pkm_info.hp    = WATER_MID_HP;
                in_pkm_info.atk   = WATER_MID_ATK;
                in_flag           = 0;
            end
            else if(in_pkm_info.stage == Middle && in_pkm_info.exp >= WATER_MID_EXP) begin
                in_pkm_info.exp   = 0;
                in_pkm_info.stage = Highest;
                in_pkm_info.hp    = WATER_HIGH_HP;
                in_pkm_info.atk   = WATER_HIGH_ATK;
                in_flag           = 0;
            end
        end
        Electric: begin
            if(in_pkm_info.stage == Lowest && in_pkm_info.exp >= ELEC_LOW_EXP) begin
                in_pkm_info.exp   = 0;
                in_pkm_info.stage = Middle;
                in_pkm_info.hp    = ELEC_MID_HP;
                in_pkm_info.atk   = ELEC_MID_ATK;
                in_flag           = 0;
            end
            else if(in_pkm_info.stage == Middle && in_pkm_info.exp >= ELEC_MID_EXP) begin
                in_pkm_info.exp   = 0;
                in_pkm_info.stage = Highest;
                in_pkm_info.hp    = ELEC_HIGH_HP;
                in_pkm_info.atk   = ELEC_HIGH_ATK;
                in_flag           = 0;
            end
        end
        // Make sure that Normal PKM will not exceed the NORM_LOW_EXP
        Normal: begin
            if(in_pkm_info.stage == Lowest && in_pkm_info.exp >= NORM_LOW_EXP) begin
                in_pkm_info.exp   = NORM_LOW_EXP;
            end
        end
    endcase
    out_pkm_info = in_pkm_info;
    out_flag     = in_flag;
end endtask
//----------------------------------------------------------------------------------------------------------------------------------------//
// Display Input
task display_player_task;
    input Player_id   in_id;
    input Player_Info in_info;
begin
	 $display("[Complete : %d                ]", your_complete);
    $display("[Err Msg  : %-16s ]", your_err_msg);
    $display("[Info     : %-16h ]", your_info);
    $display("\033[41m========================\033[0m");
    $display("\033[41m=     Player Info      =\033[0m");
    $display("\033[41m========================\033[0m");
    $display("[Player    : %-4h      ]",   in_id);
    $display("[DRAM Addr : %-4h      ]\n",   in_id*8);
    $display("[Berry     : %-4h      ]",   in_info.bag_info.berry_num   );
    $display("[Medicine  : %-4h      ]",   in_info.bag_info.medicine_num);
    $display("[Candy     : %-4h      ]",   in_info.bag_info.candy_num   );
    $display("[Bracer    : %-4h      ]",   in_info.bag_info.bracer_num  );
    $display("[Stone     : %-8s  ]",       in_info.bag_info.stone.name());
    $display("[Money     : %-4h      ]\n", in_info.bag_info.money       );

    $display("[PKM Stage : %-8s  ]",     in_info.pkm_info.stage.name());
    $display("[PKM Type  : %-8s  ]",     in_info.pkm_info.pkm_type.name());
    $display("[PKM HP    : %-4h      ]", in_info.pkm_info.hp);
    $display("[PKM Atk   : %-4h      ]", in_info.pkm_info.atk);
    $display("[PKM Exp   : %-4h      ]", in_info.pkm_info.exp);
end endtask

task display_act_task; begin
    $display("\033[44m========================\033[0m");
    $display("\033[44m=     Action Info      =\033[0m");
    $display("\033[44m========================\033[0m");
    $display("[Cur Id : %-4h         ]",player1_id);
    $display("[Action : %-13s]",player1_act.name());
    case (player1_act)
        Buy:
            if(buy_flag==0) $display("[Type   : %-13s]",player1_type.name());
            else            $display("[Item   : %-13s]",player1_item.name());
        Sell:
            if(sell_flag==0) $display("[Type   : %-13s]",player1_type.name());
            else             $display("[Item   : %-13s]",player1_item.name());
        Deposit:
            $display("[Money  : %-4h         ]",player1_money);
        Use_item:
            $display("[Item   : %-13s]",player1_item.name());
        Attack:
            $display("[Def Id : %-4h         ]",player2_id);
    endcase
end endtask

//----------------------------------------------------------------------------------------------------------------------------------------//
// Display Gold
task display_gold_task; begin
    $display("\033[43m======================\033[0m");
    $display("\033[43m=    Golden Info     =\033[0m");
    $display("\033[43m======================\033[0m");
    $display("[Complete : %d                ]", gold_complete);
    $display("[Err Msg  : %-16s ]", gold_err_msg.name());
    $display("[Info     : %-16h ]", gold_info);
    if(player1_act != Attack) begin
        $display("[Player    : %-4h    ]",   player1_id);
        $display("[DRAM Addr : %-4h    ]\n", player1_id*8);
        $display("[Berry     : %-4h    ]",   player1_info.bag_info.berry_num   );
        $display("[Medicine  : %-4h    ]",   player1_info.bag_info.medicine_num);
        $display("[Candy     : %-4h    ]",   player1_info.bag_info.candy_num   );
        $display("[Bracer    : %-4h    ]",   player1_info.bag_info.bracer_num  );
        $display("[Stone     : %-8s]",       player1_info.bag_info.stone.name());
        $display("[Money     : %-4h    ]\n", player1_info.bag_info.money       );

        $display("[PKM Stage : %-8s]",     player1_info.pkm_info.stage.name());
        $display("[PKM Type  : %-8s]",     player1_info.pkm_info.pkm_type.name());
        $display("[PKM HP    : %-4h    ]", player1_info.pkm_info.hp);
        if(player1_atk_flag == 1)
            $display("[PKM Atk   : %-4h    ]", player1_info.pkm_info.atk + 32);
        else
            $display("[PKM Atk   : %-4h    ]", player1_info.pkm_info.atk);
        $display("[PKM Exp   : %-4h    ]", player1_info.pkm_info.exp);
    end
    else begin
        // Player1
        $display("\033[41m[Attack Player       ]\033[0m");
        $display("[Player    : %-4h    ]",   player1_id);
        $display("[DRAM Addr : %-4h    ]\n", player1_id*8);
        $display("[Berry     : %-4h    ]",   player1_info.bag_info.berry_num   );
        $display("[Medicine  : %-4h    ]",   player1_info.bag_info.medicine_num);
        $display("[Candy     : %-4h    ]",   player1_info.bag_info.candy_num   );
        $display("[Bracer    : %-4h    ]",   player1_info.bag_info.bracer_num  );
        $display("[Stone     : %-8s]",       player1_info.bag_info.stone.name());
        $display("[Money     : %-4h    ]\n", player1_info.bag_info.money       );

        $display("[PKM Stage : %-8s]",     player1_info.pkm_info.stage.name());
        $display("[PKM Type  : %-8s]",     player1_info.pkm_info.pkm_type.name());
        $display("[PKM HP    : %-4h    ]", player1_info.pkm_info.hp);
        if(player1_atk_flag == 1)
            $display("[PKM Atk   : %-4h    ]", player1_info.pkm_info.atk + 32);
        else
            $display("[PKM Atk   : %-4h    ]", player1_info.pkm_info.atk);
        $display("[PKM Exp   : %-4h    ]", player1_info.pkm_info.exp);

        $display("\033[43m[====================]\033[0m");
        // Player2
        $display("\033[41m[Defender Player     ]\033[0m");
        $display("[Player    : %-4h    ]",   player2_id);
        $display("[DRAM Addr : %-4h    ]\n", player2_id*8);
        $display("[Berry     : %-4h    ]",   player2_info.bag_info.berry_num   );
        $display("[Medicine  : %-4h    ]",   player2_info.bag_info.medicine_num);
        $display("[Candy     : %-4h    ]",   player2_info.bag_info.candy_num   );
        $display("[Bracer    : %-4h    ]",   player2_info.bag_info.bracer_num  );
        $display("[Stone     : %-8s]",       player2_info.bag_info.stone.name());
        $display("[Money     : %-4h    ]\n", player2_info.bag_info.money       );

        $display("[PKM Stage : %-8s]",     player2_info.pkm_info.stage.name());
        $display("[PKM Type  : %-8s]",     player2_info.pkm_info.pkm_type.name());
        $display("[PKM HP    : %-4h    ]", player2_info.pkm_info.hp);
        $display("[PKM Atk   : %-4h    ]", player2_info.pkm_info.atk);
        $display("[PKM Exp   : %-4h    ]", player2_info.pkm_info.exp);
    end
end endtask

//**************************************************************************************************************************************************************
//      Calculate Task
//**************************************************************************************************************************************************************
task cal_task; begin
    player1_old_info = player1_info;
    player2_old_info = player2_info;
    case(player1_act)
        Buy:begin
            if(buy_flag == 0) begin
                //***************
                // Buy PKM
                //***************
                case(player1_type)
                    Grass:    pkm_price = GRASS_LOW_COIN;
                    Fire:     pkm_price = FIRE_LOW_COIN;
                    Water:    pkm_price = WATER_LOW_COIN;
                    Electric: pkm_price = ELEC_LOW_COIN;
                    Normal:   pkm_price = NORM_LOW_COIN;
                endcase
                money_chek = (player1_info.bag_info.money - pkm_price);

                if( money_chek < 0) begin
                    // Out of money
                    gold_complete = 0;
                    gold_err_msg  = Out_of_money;
                    gold_info     = 0;
                end
                else if(player1_info.pkm_info.pkm_type !== No_type) begin
                    // Already have a PKM
                    gold_complete = 0;
                    gold_err_msg  = Already_Have_PKM;
                    gold_info     = 0;
                end
                else begin
                    // Buy PKM success
                    gold_complete = 1;
                    gold_err_msg  = No_Err;

                    // Modify player1_info
                    player1_info.pkm_info.stage    = Lowest;
                    player1_info.pkm_info.pkm_type = player1_type;
                    player1_info.pkm_info.exp      = 0;
                    case(player1_type)
                        Grass: begin
                            player1_info.bag_info.money = player1_info.bag_info.money - GRASS_LOW_COIN;
                            player1_info.pkm_info.hp  = GRASS_LOW_HP;
                            player1_info.pkm_info.atk = GRASS_LOW_ATK;
                        end
                        Fire: begin
                            player1_info.bag_info.money = player1_info.bag_info.money - FIRE_LOW_COIN;
                            player1_info.pkm_info.hp  = FIRE_LOW_HP;
                            player1_info.pkm_info.atk = FIRE_LOW_ATK;
                        end
                        Water: begin
                            player1_info.bag_info.money = player1_info.bag_info.money - WATER_LOW_COIN;
                            player1_info.pkm_info.hp  = WATER_LOW_HP;
                            player1_info.pkm_info.atk = WATER_LOW_ATK;
                        end
                        Electric: begin
                            player1_info.bag_info.money = player1_info.bag_info.money - ELEC_LOW_COIN;
                            player1_info.pkm_info.hp  = ELEC_LOW_HP;
                            player1_info.pkm_info.atk = ELEC_LOW_ATK;
                        end
                        Normal: begin
                            player1_info.bag_info.money = player1_info.bag_info.money - NORM_LOW_COIN;
                            player1_info.pkm_info.hp  = NORM_LOW_HP;
                            player1_info.pkm_info.atk = NORM_LOW_ATK;
                        end
                    endcase

                    // Give player1_info to output
                    gold_info = player1_info;
                end
            end
            else begin
                //***************
                // Buy Item
                //***************
                case(player1_item)
                    Berry:         item_price = BERRY_BUY_COIN;
                    Medicine:      item_price = MEDICINE_BUY_COIN;
                    Candy:         item_price = CANDY_BUY_COIN;
                    Bracer:        item_price = BRACER_BUY_COIN;
                    Water_stone:   item_price = STONE_BUY_COIN;
                    Fire_stone:    item_price = STONE_BUY_COIN;
                    Thunder_stone: item_price = STONE_BUY_COIN;
                endcase
                money_chek = (player1_info.bag_info.money - item_price);

                if(money_chek < 0) begin
                    // Out of money
                    gold_complete = 0;
                    gold_err_msg  = Out_of_money;
                    gold_info     = 0;
                end
                else begin
                    // Bag is full
                    // Buy item success
                    case(player1_item)
                        Berry: begin
                            if(player1_info.bag_info.berry_num == 'hf) begin
                                gold_complete = 0;
                                gold_err_msg  = Bag_is_full;
                                gold_info     = 0;
                            end
                            else begin
                                gold_complete = 1;
                                gold_err_msg  = No_Err;

                                // Modify player1_info
                                player1_info.bag_info.berry_num = player1_info.bag_info.berry_num + 1;
                                player1_info.bag_info.money     = player1_info.bag_info.money - BERRY_BUY_COIN;

                                // Give player1_info to output
                                gold_info = player1_info;
                                // Add (Atk+32 effect)
                                if(player1_atk_flag == 1)
                                    gold_info[15:8] = gold_info[15:8] + 32;
                            end
                        end
                        Medicine: begin
                            if(player1_info.bag_info.medicine_num == 'hf) begin
                                gold_complete = 0;
                                gold_err_msg  = Bag_is_full;
                                gold_info     = 0;
                            end
                            else begin
                                gold_complete = 1;
                                gold_err_msg  = No_Err;

                                // Modify player1_info
                                player1_info.bag_info.medicine_num = player1_info.bag_info.medicine_num + 1;
                                player1_info.bag_info.money        = player1_info.bag_info.money - MEDICINE_BUY_COIN;

                                // Give player1_info to output
                                gold_info = player1_info;
                                // Add (Atk+32 effect)
                                if(player1_atk_flag == 1)
                                    gold_info[15:8] = gold_info[15:8] + 32;
                            end
                        end
                        Candy: begin
                            if(player1_info.bag_info.candy_num == 'hf) begin
                                gold_complete = 0;
                                gold_err_msg  = Bag_is_full;
                                gold_info     = 0;
                            end
                            else begin
                                gold_complete = 1;
                                gold_err_msg  = No_Err;

                                // Modify player1_info
                                player1_info.bag_info.candy_num = player1_info.bag_info.candy_num + 1;
                                player1_info.bag_info.money     = player1_info.bag_info.money - CANDY_BUY_COIN;

                                // Give player1_info to output
                                gold_info = player1_info;
                                // Add (Atk+32 effect)
                                if(player1_atk_flag == 1)
                                    gold_info[15:8] = gold_info[15:8] + 32;
                            end
                        end
                        Bracer: begin
                            if(player1_info.bag_info.bracer_num == 'hf) begin
                                gold_complete = 0;
                                gold_err_msg  = Bag_is_full;
                                gold_info     = 0;
                            end
                            else begin
                                gold_complete = 1;
                                gold_err_msg  = No_Err;

                                // Modify player1_info
                                player1_info.bag_info.bracer_num = player1_info.bag_info.bracer_num + 1;
                                player1_info.bag_info.money      = player1_info.bag_info.money - BRACER_BUY_COIN;

                                // Give player1_info to output
                                gold_info = player1_info;
                                // Add (Atk+32 effect)
                                if(player1_atk_flag == 1)
                                    gold_info[15:8] = gold_info[15:8] + 32;
                            end
                        end
                        Water_stone, Fire_stone, Thunder_stone: begin
                            if(player1_info.bag_info.stone !== No_stone) begin
                                gold_complete = 0;
                                gold_err_msg  = Bag_is_full;
                                gold_info     = 0;
                            end
                            else begin
                                gold_complete = 1;
                                gold_err_msg  = No_Err;

                                // Modify player1_info
                                if(player1_item == Water_stone)        player1_info.bag_info.stone = W_stone;
                                else if(player1_item == Fire_stone)    player1_info.bag_info.stone = F_stone;
                                else if(player1_item == Thunder_stone) player1_info.bag_info.stone = T_stone;
                                player1_info.bag_info.money = player1_info.bag_info.money - STONE_BUY_COIN;

                                // Give player1_info to output
                                gold_info = player1_info;
                                // Add (Atk+32 effect)
                                if(player1_atk_flag == 1)
                                    gold_info[15:8] = gold_info[15:8] + 32;
                            end
                        end
                    endcase
                end
            end
        end
        Sell: begin
            if(sell_flag==0) begin
                //***************
                // Sell PKM
                //***************
                if(player1_info.pkm_info.pkm_type == No_type) begin
                    // Do not have a PKM
                    gold_complete = 0;
                    gold_err_msg  = Not_Having_PKM;
                    gold_info     = 0;
                end
                else if(player1_info.pkm_info.stage == Lowest) begin
                    // PKM is in the lowest stage
                    gold_complete = 0;
                    gold_err_msg  = Has_Not_Grown;
                    gold_info     = 0;
                end
                else begin
                    // Sell success
                    gold_complete = 1;
                    gold_err_msg  = No_Err;

                    // Give PKM info to output
                    gold_info[31:0] = player1_info.pkm_info;
                    // Add (Atk+32 effect)
                    if(player1_atk_flag == 1)
                        gold_info[15:8] = gold_info[15:8] + 32;

                    // Modify player1_info
                    case(player1_info.pkm_info.pkm_type)
                        Grass: begin
                            if(player1_info.pkm_info.stage == Middle)       player1_info.bag_info.money = player1_info.bag_info.money + GRASS_MID_COIN;
                            else if(player1_info.pkm_info.stage == Highest) player1_info.bag_info.money = player1_info.bag_info.money + GRASS_HIGH_COIN;
                        end
                        Fire: begin
                            if(player1_info.pkm_info.stage == Middle)       player1_info.bag_info.money = player1_info.bag_info.money + FIRE_MID_COIN;
                            else if(player1_info.pkm_info.stage == Highest) player1_info.bag_info.money = player1_info.bag_info.money + FIRE_HIGH_COIN;
                        end
                        Water: begin
                            if(player1_info.pkm_info.stage == Middle)       player1_info.bag_info.money = player1_info.bag_info.money + WATER_MID_COIN;
                            else if(player1_info.pkm_info.stage == Highest) player1_info.bag_info.money = player1_info.bag_info.money + WATER_HIGH_COIN;
                        end
                        Electric: begin
                            if(player1_info.pkm_info.stage == Middle)       player1_info.bag_info.money = player1_info.bag_info.money + ELEC_MID_COIN;
                            else if(player1_info.pkm_info.stage == Highest) player1_info.bag_info.money = player1_info.bag_info.money + ELEC_HIGH_COIN;
                        end
                        // Normal is always "Lowest"
                        // Thus, the PKM can't be sold.
                    endcase
                    player1_info.pkm_info = 0;

                    // Give Bag info to output
                    //gold_info[63:32] = player1_info.bag_info;
                    gold_info = player1_info;
                    // Clear (Atk+32 effect)
                    player1_atk_flag = 0;
                end
            end
            else begin
                //***************
                // Sell Item
                //***************
                case(player1_item)
                    Berry: begin
                        if(player1_info.bag_info.berry_num == 0) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            gold_complete = 1;
                            gold_err_msg  = No_Err;

                            // Modify player1_info
                            player1_info.bag_info.berry_num = player1_info.bag_info.berry_num - 1;
                            player1_info.bag_info.money     = player1_info.bag_info.money + BERRY_SELL_COIN;

                            // Give player1_info to output
                            gold_info = player1_info;
                            // Add (Atk+32 effect)
                            if(player1_atk_flag == 1)
                                gold_info[15:8] = gold_info[15:8] + 32;
                        end
                    end
                    Medicine: begin
                        if(player1_info.bag_info.medicine_num == 0) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            gold_complete = 1;
                            gold_err_msg  = No_Err;

                            // Modify player1_info
                            player1_info.bag_info.medicine_num = player1_info.bag_info.medicine_num - 1;
                            player1_info.bag_info.money        = player1_info.bag_info.money + MEDICINE_SELL_COIN;

                            // Give player1_info to output
                            gold_info = player1_info;
                            // Add (Atk+32 effect)
                            if(player1_atk_flag == 1)
                                gold_info[15:8] = gold_info[15:8] + 32;
                        end
                    end
                    Candy: begin
                        if(player1_info.bag_info.candy_num == 0) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            gold_complete = 1;
                            gold_err_msg  = No_Err;

                            // Modify player1_info
                            player1_info.bag_info.candy_num = player1_info.bag_info.candy_num - 1;
                            player1_info.bag_info.money     = player1_info.bag_info.money + CANDY_SELL_COIN;

                            // Give player1_info to output
                            gold_info = player1_info;
                            // Add (Atk+32 effect)
                            if(player1_atk_flag == 1)
                                gold_info[15:8] = gold_info[15:8] + 32;
                        end
                    end
                    Bracer: begin
                        if(player1_info.bag_info.bracer_num == 0) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            gold_complete = 1;
                            gold_err_msg  = No_Err;

                            // Modify player1_info
                            player1_info.bag_info.bracer_num = player1_info.bag_info.bracer_num - 1;
                            player1_info.bag_info.money      = player1_info.bag_info.money + BRACER_SELL_COIN;

                            // Give player1_info to output
                            gold_info = player1_info;
                            // Add (Atk+32 effect)
                            if(player1_atk_flag == 1)
                                gold_info[15:8] = gold_info[15:8] + 32;
                        end
                    end
                    Water_stone, Fire_stone, Thunder_stone: begin
                        if(player1_info.bag_info.stone == No_stone) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            

                            // Stone is not consistent ==> error
                            case (player1_info.bag_info.stone)
                                W_stone: begin
                                    if(player1_item !== Water_stone) begin
                                        gold_complete = 0;
                                        gold_err_msg  = Not_Having_Item;
                                        gold_info     = 0;
                                    end
                                    else begin
                                        gold_complete = 1;
                                        gold_err_msg  = No_Err;

                                        // Modify player1_info
                                        player1_info.bag_info.stone = No_stone;
                                        player1_info.bag_info.money = player1_info.bag_info.money + STONE_SELL_COIN;

                                        // Give player1_info to output
                                        gold_info = player1_info;
                                        // Add (Atk+32 effect)
                                        if(player1_atk_flag == 1)
                                            gold_info[15:8] = gold_info[15:8] + 32;
                                    end
                                end
                                F_stone: begin
                                    if(player1_item !== Fire_stone) begin
                                        gold_complete = 0;
                                        gold_err_msg  = Not_Having_Item;
                                        gold_info     = 0;
                                    end
                                    else begin
                                        gold_complete = 1;
                                        gold_err_msg  = No_Err;

                                        // Modify player1_info
                                        player1_info.bag_info.stone = No_stone;
                                        player1_info.bag_info.money = player1_info.bag_info.money + STONE_SELL_COIN;

                                        // Give player1_info to output
                                        gold_info = player1_info;
                                        // Add (Atk+32 effect)
                                        if(player1_atk_flag == 1)
                                            gold_info[15:8] = gold_info[15:8] + 32;
                                    end
                                end
                                T_stone: begin
                                    if(player1_item !== Thunder_stone) begin
                                        gold_complete = 0;
                                        gold_err_msg  = Not_Having_Item;
                                        gold_info     = 0;
                                    end
                                    else begin
                                        gold_complete = 1;
                                        gold_err_msg  = No_Err;

                                        // Modify player1_info
                                        player1_info.bag_info.stone = No_stone;
                                        player1_info.bag_info.money = player1_info.bag_info.money + STONE_SELL_COIN;

                                        // Give player1_info to output
                                        gold_info = player1_info;
                                        // Add (Atk+32 effect)
                                        if(player1_atk_flag == 1)
                                            gold_info[15:8] = gold_info[15:8] + 32;
                                    end
                                end
                            endcase
                        end
                    end
                endcase
            end
        end
        Use_item: begin
            if(player1_info.pkm_info.pkm_type == No_type) begin
                // Do not have a PKM
                gold_complete = 0;
                gold_err_msg  = Not_Having_PKM;
                gold_info     = 0;
            end
            else begin
                // Do not have item
                // Use item success
                case(player1_item)
                    Berry: begin // HP+32
                        if(player1_info.bag_info.berry_num == 0) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            gold_complete = 1;
                            gold_err_msg  = No_Err;

                            // Modify player1_info
                            player1_info.bag_info.berry_num = player1_info.bag_info.berry_num - 1;

                            // Modify player1_info PKM
                            case(player1_info.pkm_info.pkm_type)
                                Grass: begin
                                    if(player1_info.pkm_info.stage == Lowest)       player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= GRASS_LOW_HP  ? GRASS_LOW_HP  : (player1_info.pkm_info.hp + 32);
                                    else if(player1_info.pkm_info.stage == Middle)  player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= GRASS_MID_HP  ? GRASS_MID_HP  : (player1_info.pkm_info.hp + 32);
                                    else if(player1_info.pkm_info.stage == Highest) player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= GRASS_HIGH_HP ? GRASS_HIGH_HP : (player1_info.pkm_info.hp + 32);
                                end
                                Fire: begin
                                    if(player1_info.pkm_info.stage == Lowest)       player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= FIRE_LOW_HP   ? FIRE_LOW_HP   : (player1_info.pkm_info.hp + 32);
                                    else if(player1_info.pkm_info.stage == Middle)  player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= FIRE_MID_HP   ? FIRE_MID_HP   : (player1_info.pkm_info.hp + 32);
                                    else if(player1_info.pkm_info.stage == Highest) player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= FIRE_HIGH_HP  ? FIRE_HIGH_HP  : (player1_info.pkm_info.hp + 32);
                                end
                                Water: begin
                                    if(player1_info.pkm_info.stage == Lowest)       player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= WATER_LOW_HP  ? WATER_LOW_HP  : (player1_info.pkm_info.hp + 32);
                                    else if(player1_info.pkm_info.stage == Middle)  player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= WATER_MID_HP  ? WATER_MID_HP  : (player1_info.pkm_info.hp + 32);
                                    else if(player1_info.pkm_info.stage == Highest) player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= WATER_HIGH_HP ? WATER_HIGH_HP : (player1_info.pkm_info.hp + 32);
                                end
                                Electric: begin
                                    if(player1_info.pkm_info.stage == Lowest)       player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= ELEC_LOW_HP   ? ELEC_LOW_HP   : (player1_info.pkm_info.hp + 32);
                                    else if(player1_info.pkm_info.stage == Middle)  player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= ELEC_MID_HP   ? ELEC_MID_HP   : (player1_info.pkm_info.hp + 32);
                                    else if(player1_info.pkm_info.stage == Highest) player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= ELEC_HIGH_HP  ? ELEC_HIGH_HP  : (player1_info.pkm_info.hp + 32);
                                end
                                Normal: begin
                                    player1_info.pkm_info.hp = (player1_info.pkm_info.hp + 32) >= NORM_LOW_HP ? NORM_LOW_HP : (player1_info.pkm_info.hp + 32);
                                end
                            endcase

                            // Give player1_info to output
                            gold_info = player1_info;
                            // Add (Atk+32 effect)
                            if(player1_atk_flag == 1)
                                gold_info[15:8] = gold_info[15:8] + 32;
                        end
                    end
                    Medicine: begin // Recover full HP
                        if(player1_info.bag_info.medicine_num == 0) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            gold_complete = 1;
                            gold_err_msg  = No_Err;

                            // Modify player1_info
                            player1_info.bag_info.medicine_num = player1_info.bag_info.medicine_num - 1;

                            // Modify player1_info PKM
                            case(player1_info.pkm_info.pkm_type)
                                Grass: begin
                                    if(player1_info.pkm_info.stage == Lowest)       player1_info.pkm_info.hp = GRASS_LOW_HP ;
                                    else if(player1_info.pkm_info.stage == Middle)  player1_info.pkm_info.hp = GRASS_MID_HP ;
                                    else if(player1_info.pkm_info.stage == Highest) player1_info.pkm_info.hp = GRASS_HIGH_HP;
                                end
                                Fire: begin
                                    if(player1_info.pkm_info.stage == Lowest)       player1_info.pkm_info.hp = FIRE_LOW_HP ;
                                    else if(player1_info.pkm_info.stage == Middle)  player1_info.pkm_info.hp = FIRE_MID_HP ;
                                    else if(player1_info.pkm_info.stage == Highest) player1_info.pkm_info.hp = FIRE_HIGH_HP;
                                end
                                Water: begin
                                    if(player1_info.pkm_info.stage == Lowest)       player1_info.pkm_info.hp = WATER_LOW_HP ;
                                    else if(player1_info.pkm_info.stage == Middle)  player1_info.pkm_info.hp = WATER_MID_HP ;
                                    else if(player1_info.pkm_info.stage == Highest) player1_info.pkm_info.hp = WATER_HIGH_HP;
                                end
                                Electric: begin
                                    if(player1_info.pkm_info.stage == Lowest)       player1_info.pkm_info.hp = ELEC_LOW_HP ;
                                    else if(player1_info.pkm_info.stage == Middle)  player1_info.pkm_info.hp = ELEC_MID_HP ;
                                    else if(player1_info.pkm_info.stage == Highest) player1_info.pkm_info.hp = ELEC_HIGH_HP;
                                end
                                Normal: begin
                                    player1_info.pkm_info.hp = NORM_LOW_HP;
                                end
                            endcase

                            // Give player1_info to output
                            gold_info = player1_info;
                            // Add (Atk+32 effect)
                            if(player1_atk_flag == 1)
                                gold_info[15:8] = gold_info[15:8] + 32;
                        end
                    end
                    Candy: begin // Exp + 15
                        if(player1_info.bag_info.candy_num == 0) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            gold_complete = 1;
                            gold_err_msg  = No_Err;

                            // Modify player1_info
                            player1_info.bag_info.candy_num = player1_info.bag_info.candy_num - 1;

                            // Modify player1_info PKM
                            // 1. Modify Exp
                            if(player1_info.pkm_info.stage != Highest)
                                player1_info.pkm_info.exp = player1_info.pkm_info.exp + 15;

                            // 2. Modify Stage and Exp depending on Exp
                            evolv_pkm_task(player1_info.pkm_info, player1_atk_flag, player1_info.pkm_info, player1_atk_flag);

                            // Give player1_info to output
                            gold_info = player1_info;
                            // Add (Atk+32 effect)
                            if(player1_atk_flag == 1)
                                gold_info[15:8] = gold_info[15:8] + 32;
                        end
                    end
                    Bracer: begin // Atk + 32
                        if(player1_info.bag_info.bracer_num == 0) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            gold_complete = 1;
                            gold_err_msg  = No_Err;

                            // Modify player1_info
                            player1_info.bag_info.bracer_num = player1_info.bag_info.bracer_num - 1;

                            // Modify player1_info PKM
                            player1_atk_flag = 1;

                            // Give player1_info to output
                            // Only atk should become +32
                            gold_info = player1_info;
                            gold_info[15:8] = gold_info[15:8] + 32;
                        end
                    end
                    //---------------------
                    // Should be comfirmed
                    //---------------------
                    // If the stone of the action "Use_item" is not consistent to the stone of "Bag_Info"
                    // The message is error 
                    Water_stone, Fire_stone, Thunder_stone: begin
                        if(player1_info.bag_info.stone == No_stone) begin
                            gold_complete = 0;
                            gold_err_msg  = Not_Having_Item;
                            gold_info     = 0;
                        end
                        else begin
                            // Modify player1_info

                            // Stone is not consistent ==> error
                            // Evolve or no change
                            case (player1_info.bag_info.stone)
                                W_stone: begin
                                    if(player1_item !== Water_stone) begin
                                        gold_complete = 0;
                                        gold_err_msg  = Not_Having_Item;
                                        gold_info     = 0;
                                    end
                                    else begin
                                        gold_complete = 1;
                                        gold_err_msg  = No_Err;
                                        // Check whether the PKM evolves
                                        if(player1_info.pkm_info.pkm_type == Normal && player1_info.pkm_info.exp >= NORM_LOW_EXP) begin
                                            player1_info.pkm_info.exp      = 0;
                                            player1_info.pkm_info.stage    = Highest;
                                            player1_info.pkm_info.hp       = WATER_HIGH_HP;
                                            player1_info.pkm_info.atk      = WATER_HIGH_ATK;
                                            player1_info.pkm_info.pkm_type = Water;
                                            // Clear (Atk+32 effect)
                                            player1_atk_flag = 0;
                                        end
                                        // Use stone
                                        player1_info.bag_info.stone = No_stone;
                                        // Give player1_info to output
                                        gold_info = player1_info;
                                        // Add (Atk+32 effect)
                                        if(player1_atk_flag == 1)
                                            gold_info[15:8] = gold_info[15:8] + 32;
                                    end
                                end
                                F_stone: begin
                                    if(player1_item !== Fire_stone) begin
                                        gold_complete = 0;
                                        gold_err_msg  = Not_Having_Item;
                                        gold_info     = 0;
                                    end
                                    else begin
                                        gold_complete = 1;
                                        gold_err_msg  = No_Err;
                                        // Check whether the PKM evolves
                                        if(player1_info.pkm_info.pkm_type == Normal && player1_info.pkm_info.exp >= NORM_LOW_EXP) begin
                                            player1_info.pkm_info.exp      = 0;
                                            player1_info.pkm_info.stage    = Highest;
                                            player1_info.pkm_info.hp       = FIRE_HIGH_HP;
                                            player1_info.pkm_info.atk      = FIRE_HIGH_ATK;
                                            player1_info.pkm_info.pkm_type = Fire;
                                            // Clear (Atk+32 effect)
                                            player1_atk_flag = 0;
                                        end
                                        // Use stone
                                        player1_info.bag_info.stone = No_stone;
                                        // Give player1_info to output
                                        gold_info = player1_info;
                                        // Add (Atk+32 effect)
                                        if(player1_atk_flag == 1)
                                            gold_info[15:8] = gold_info[15:8] + 32;
                                    end
                                end
                                T_stone: begin
                                    if(player1_item !== Thunder_stone) begin
                                        gold_complete = 0;
                                        gold_err_msg  = Not_Having_Item;
                                        gold_info     = 0;
                                    end
                                    else begin
                                        gold_complete = 1;
                                        gold_err_msg  = No_Err;
                                        // Check whether the PKM evolves
                                        if(player1_info.pkm_info.pkm_type == Normal && player1_info.pkm_info.exp >= NORM_LOW_EXP) begin
                                            player1_info.pkm_info.exp      = 0;
                                            player1_info.pkm_info.stage    = Highest;
                                            player1_info.pkm_info.hp       = ELEC_HIGH_HP;
                                            player1_info.pkm_info.atk      = ELEC_HIGH_ATK;
                                            player1_info.pkm_info.pkm_type = Electric;
                                            // Clear (Atk+32 effect)
                                            player1_atk_flag = 0;
                                        end
                                        // Use stone
                                        player1_info.bag_info.stone = No_stone;
                                        // Give player1_info to output
                                        gold_info = player1_info;
                                        // Add (Atk+32 effect)
                                        if(player1_atk_flag == 1)
                                            gold_info[15:8] = gold_info[15:8] + 32;
                                    end
                                end
                            endcase
                        end
                    end
                endcase
            end
        end
        Attack: begin
            if(player1_info.pkm_info.pkm_type == No_type || player2_info.pkm_info.pkm_type == No_type) begin
                // Do not have a PKM
                gold_complete = 0;
                gold_err_msg  = Not_Having_PKM;
                gold_info     = 0;
            end
            else if(player1_info.pkm_info.hp == 0 || player2_info.pkm_info.hp == 0) begin
                // HP is zero
                gold_complete = 0;
                gold_err_msg  = HP_is_Zero;
                gold_info     = 0;
            end
            else begin
                // Attack success
                gold_complete = 1;
                gold_err_msg  = No_Err;
                // Modify Atk increment
                if(player1_info.pkm_info.pkm_type == Grass) begin
                    if(player2_info.pkm_info.pkm_type == Grass)         player1_atk_incr = 0.5;
                    else if(player2_info.pkm_info.pkm_type == Fire)     player1_atk_incr = 0.5;
                    else if(player2_info.pkm_info.pkm_type == Water)    player1_atk_incr = 2;
                    else if(player2_info.pkm_info.pkm_type == Electric) player1_atk_incr = 1;
                    else if(player2_info.pkm_info.pkm_type == Normal)   player1_atk_incr = 1;
                end
                else if(player1_info.pkm_info.pkm_type == Fire) begin
                    if(player2_info.pkm_info.pkm_type == Grass)         player1_atk_incr = 2;
                    else if(player2_info.pkm_info.pkm_type == Fire)     player1_atk_incr = 0.5;
                    else if(player2_info.pkm_info.pkm_type == Water)    player1_atk_incr = 0.5;
                    else if(player2_info.pkm_info.pkm_type == Electric) player1_atk_incr = 1;
                    else if(player2_info.pkm_info.pkm_type == Normal)   player1_atk_incr = 1;
                end
                else if(player1_info.pkm_info.pkm_type == Water) begin
                    if(player2_info.pkm_info.pkm_type == Grass)         player1_atk_incr = 0.5;
                    else if(player2_info.pkm_info.pkm_type == Fire)     player1_atk_incr = 2;
                    else if(player2_info.pkm_info.pkm_type == Water)    player1_atk_incr = 0.5;
                    else if(player2_info.pkm_info.pkm_type == Electric) player1_atk_incr = 1;
                    else if(player2_info.pkm_info.pkm_type == Normal)   player1_atk_incr = 1;
                end
                else if(player1_info.pkm_info.pkm_type == Electric) begin
                    if(player2_info.pkm_info.pkm_type == Grass)         player1_atk_incr = 0.5;
                    else if(player2_info.pkm_info.pkm_type == Fire)     player1_atk_incr = 1;
                    else if(player2_info.pkm_info.pkm_type == Water)    player1_atk_incr = 2;
                    else if(player2_info.pkm_info.pkm_type == Electric) player1_atk_incr = 0.5;
                    else if(player2_info.pkm_info.pkm_type == Normal)   player1_atk_incr = 1;
                end
                else if(player1_info.pkm_info.pkm_type == Normal) begin
                    if(player2_info.pkm_info.pkm_type == Grass)         player1_atk_incr = 1;
                    else if(player2_info.pkm_info.pkm_type == Fire)     player1_atk_incr = 1;
                    else if(player2_info.pkm_info.pkm_type == Water)    player1_atk_incr = 1;
                    else if(player2_info.pkm_info.pkm_type == Electric) player1_atk_incr = 1;
                    else if(player2_info.pkm_info.pkm_type == Normal)   player1_atk_incr = 1;
                end

                //$display("%d", player1_atk_incr);
                //$display("%d", player1_atk_flag);
                //$display("%d", player1_info.pkm_info.atk);
                //$display("%d", player2_info.pkm_info.hp);
                //$display("%d", (player2_info.pkm_info.hp - (player1_info.pkm_info.atk+player1_atk_flag*32)*player1_atk_incr));

                // Modify HP
                player2_info.pkm_info.hp = (player2_info.pkm_info.hp - (player1_info.pkm_info.atk+player1_atk_flag*32)*player1_atk_incr) <= 0 ? 0 : (player2_info.pkm_info.hp - (player1_info.pkm_info.atk+player1_atk_flag*32)*player1_atk_incr);

                //===========================================================================
                // Modify Exp increment
                player1_exp_incr = 0;
                player2_exp_incr = 0;

                if(player2_info.pkm_info.stage == Lowest)       player1_exp_incr = 16;
                else if(player2_info.pkm_info.stage == Middle)  player1_exp_incr = 24;
                else if(player2_info.pkm_info.stage == Highest) player1_exp_incr = 32;

                if(player1_info.pkm_info.stage == Lowest)       player2_exp_incr = 8;
                else if(player1_info.pkm_info.stage == Middle)  player2_exp_incr = 12;
                else if(player1_info.pkm_info.stage == Highest) player2_exp_incr = 16;

                // 1. Modify Exp
                if(player1_info.pkm_info.stage != Highest)
                    player1_info.pkm_info.exp = player1_info.pkm_info.exp + player1_exp_incr;
                if(player2_info.pkm_info.stage != Highest)
                    player2_info.pkm_info.exp = player2_info.pkm_info.exp + player2_exp_incr;

                // 2. Modify Stage and Exp depending on Exp
                // Player1
                evolv_pkm_task(player1_info.pkm_info, dumy_flag, player1_info.pkm_info, dumy_flag);
                // Player2
                evolv_pkm_task(player2_info.pkm_info, dumy_flag, player2_info.pkm_info, dumy_flag);

                // Clear the (atk+32) effect
                player1_atk_flag = 0;
				
                gold_info = {player1_info.pkm_info, player2_info.pkm_info};
            end
        end
        Deposit: begin
            // Deposite success
            gold_complete = 1;
            gold_err_msg  = No_Err;
            
            // Modify player1_info
            player1_info.bag_info.money = player1_info.bag_info.money + player1_money;

            // Give player1_info to output
            gold_info = player1_info;
            // Add (Atk+32 effect)
            if(player1_atk_flag == 1)
                    gold_info[15:8] = gold_info[15:8] + 32;
        end
        Check: begin
            // Deposite success
            gold_complete = 1;
            gold_err_msg  = No_Err;

            // Give player1_info to output
            gold_info = player1_info;
            // Add (Atk+32 effect)
            if(player1_atk_flag == 1)
                    gold_info[15:8] = gold_info[15:8] + 32;
        end
    endcase

    //$display("======================");
    //$display("=   After Action!!!  =");
    //$display("======================");
    //display_player_task(player1_id, player1_info);
    //if(player1_act == Attack)
    //    display_player_task(player2_id, player2_info);

    //display_gold_task;

    // Write DRAM
    set_player_task(player1_id, player1_info);
    if(player1_act == Attack)
        set_player_task(player2_id, player2_info);

    // Store the old id to clear the (atk+32) effect
    old_id = player1_id;
end endtask

//**************************************************************************************************************************************************************
//      Wait Task
//**************************************************************************************************************************************************************
task wait_task; begin
    exe_lat = -1;
    while ( inf.out_valid !== 1 ) begin
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             ");
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over 5000 cycles       `:::--:/++:----------::/:.                ");
            $display("                            -+:--:++////-------------::/-               ");
            $display("                            .+---------------------------:/--::::::.`   ");
            $display("                          `.+-----------------------------:o/------::.  ");
            $display("                       .-::-----------------------------:--:o:-------:  ");
            $display("                     -:::--------:/yy------------------/y/--/o------/-  ");
            $display("                    /:-----------:+y+:://:--------------+y--:o//:://-   ");
            $display("                   //--------------:-:+ssoo+/------------s--/. ````     ");
            $display("                   o---------:/:------dNNNmds+:----------/-//           ");
            $display("                   s--------/o+:------yNNNNNd/+--+y:------/+            ");
            $display("                 .-y---------o:-------:+sso+/-:-:yy:------o`            ");
            $display("              `:oosh/--------++-----------------:--:------/.            ");
            $display("              +ssssyy--------:y:---------------------------/            ");
            $display("              +ssssyd/--------/s/-------------++-----------/`           ");
            $display("              `/yyssyso/:------:+o/::----:::/+//:----------+`           ");
            $display("             ./osyyyysssso/------:/++o+++///:-------------/:            ");
            $display("           -osssssssssssssso/---------------------------:/.             ");
            $display("         `/sssshyssssssssssss+:---------------------:/+ss               ");
            $display("        ./ssssyysssssssssssssso:--------------:::/+syyys+               ");
            $display("     `-+sssssyssssssssssssssssso-----::/++ooooossyyssyy:                ");
            $display("     -syssssyssssssssssssssssssso::+ossssssssssssyyyyyss+`              ");
            $display("     .hsyssyssssssssssssssssssssyssssssssssyhhhdhhsssyssso`             ");
            $display("     +/yyshsssssssssssssssssssysssssssssyhhyyyyssssshysssso             ");
            $display("    ./-:+hsssssssssssssssssssssyyyyyssssssssssssssssshsssss:`           ");
            $display("    /---:hsyysyssssssssssssssssssssssssssssssssssssssshssssy+           ");
            $display("    o----oyy:-:/+oyysssssssssssssssssssssssssssssssssshssssy+-          ");
            $display("    s-----++-------/+sysssssssssssssssssssssssssssssyssssyo:-:-         ");
            $display("    o/----s-----------:+syyssssssssssssssssssssssyso:--os:----/.        ");
            $display("    `o/--:o---------------:+ossyysssssssssssyyso+:------o:-----:        ");
            $display("      /+:/+---------------------:/++ooooo++/:------------s:---::        ");
            $display("       `/o+----------------------------------------------:o---+`        ");
            $display("         `+-----------------------------------------------o::+.         ");
            $display("          +-----------------------------------------------/o/`          ");
            $display("          ::----------------------------------------------:-            ");
            repeat(5) @(negedge clk);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk);
    end
end endtask

//**************************************************************************************************************************************************************
//      Check Task
//**************************************************************************************************************************************************************
task check_task; begin
    out_lat = 0;
    i = 0;
    while ( inf.out_valid === 1 ) begin
        if (out_lat==OUT_NUM) begin
            $display("                                                                                ");   
            $display("                                                   ./+oo+/.                     ");   
            $display("    Out cycles is more than 1                     /s:-----+s`     at %-12d ps   ",$time*1000);   
            $display("                                                  y/-------:y                   ");   
            $display("                                             `.-:/od+/------y`                  ");   
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");   
            $display("                              -m+:::::::---------------------::o+.              ");   
            $display("                             `hod-------------------------------:o+             ");   
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");   
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");   
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");   
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");   
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");   
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");   
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");   
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");   
            $display("                 s:----------------/s+///------------------------------o`       ");   
            $display("           ``..../s------------------::--------------------------------o        ");   
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");   
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");   
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");   
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");   
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");   
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");   
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");   
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");   
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");   
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");   
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");   
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");   
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");   
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");   
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");   
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");   
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");   
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");   
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");   
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");   
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");   
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");   
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
            repeat(5) @(negedge clk);
            $finish;
        end

        if ( i<OUT_NUM ) begin
            your_complete = inf.complete;
            your_info     = inf.out_info;
            your_err_msg  = inf.err_msg;
            i=i+1;
        end
       
        out_lat = out_lat + 1;
        @(negedge clk);
    end

    if (out_lat<OUT_NUM) begin     
        $display("                                                                                ");   
        $display("                                                   ./+oo+/.                     ");   
        $display("    Out cycles is less than 1                     /s:-----+s`     at %-12d ps   ",$time*1000);   
        $display("                                                  y/-------:y                   ");   
        $display("                                             `.-:/od+/------y`                  ");   
        $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");   
        $display("                              -m+:::::::---------------------::o+.              ");   
        $display("                             `hod-------------------------------:o+             ");   
        $display("                       ./++/:s/-o/--------------------------------/s///::.      ");   
        $display("                      /s::-://--:--------------------------------:oo/::::o+     ");   
        $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");   
        $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");   
        $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");   
        $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");   
        $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");   
        $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");   
        $display("                 s:----------------/s+///------------------------------o`       ");   
        $display("           ``..../s------------------::--------------------------------o        ");   
        $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");   
        $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");   
        $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");   
        $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");   
        $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");   
        $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");   
        $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");   
        $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");   
        $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");   
        $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");   
        $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");   
        $display("  `s+--------------------------------------:syssssssssssssssyo                  ");   
        $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");   
        $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");   
        $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");   
        $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");   
        $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");   
        $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");   
        $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");   
        $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");   
        $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");   
        $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");   
        $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
        repeat(5) @(negedge clk);
        $finish;
    end

    if ( your_complete !== gold_complete || your_info !== gold_info || your_err_msg !== gold_err_msg ) begin
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
        $display("    Out is not correct!!!!!                       /s:-----+s`     at %-12d ps   ",$time*1000);
        $display("                                                  y/-------:y                   ");
        $display("                                             `.-:/od+/------y`                  ");
        $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
        $display("                              -m+:::::::---------------------::o+.              ");
        $display("                             `hod-------------------------------:o+             ");
        $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
        $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
        $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
        $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
        $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
        $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
        $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
        $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
        $display("                 s:----------------/s+///------------------------------o`       ");
        $display("           ``..../s------------------::--------------------------------o        ");
        $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
        $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
        $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
        $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
        $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
        $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
        $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
        $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
        $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
        $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
        $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
        $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
        $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
        $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
        $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
        $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
        $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
        $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
        $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
        $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
        $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
        $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
        $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
        //display_player_task(player1_id, player1_info);
        //if(player1_act == Attack)
        //    display_player_task(player2_id, player2_info);
        display_act_task;
        if(player1_act != Attack) begin
			
            display_player_task(player1_id, player1_old_info);
            display_gold_task;
        end
        else begin
            $display("\033[41m[Attack Player       ]\033[0m");
            display_player_task(player1_id, player1_old_info);
            $display("\033[41m[Defender Player     ]\033[0m");
            display_player_task(player2_id, player2_old_info);
            display_gold_task;
        end
        repeat(5) @(negedge clk);
        $finish;
    end
    total_lat = total_lat + exe_lat;
end endtask


//**************************************************************************************************************************************************************
//      Pass Task
//**************************************************************************************************************************************************************
task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o                                                                                      ");
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    $display("=======================================================================================================================================");
    $display("Total Latency : %-1d", total_lat);
    $display("=======================================================================================================================================");

    repeat (5) @(negedge clk);
    $finish;
end endtask

endprogram

//pragma protect end