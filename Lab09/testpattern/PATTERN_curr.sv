`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"
`define End_CYCLE  5000
program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
integer i, cycles, total_cycles,y;
integer patcount,k;
integer a;

integer err_Already_Have_PKM;
integer err_Out_of_money;
integer err_Bag_is_full;
integer err_Not_Having_PKM;
integer err_Has_Not_Grown;
integer err_Not_Having_Item;
integer err_HP_is_Zero;

int test_id,test_id2;
//parameter PATNUM = 5000;
parameter SEED = 30;
//52 300
// 86 5000
// 77 5000 => bracer attack case
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
// todo handle amount overflow problem
//================================================================
// wire & registers 
//================================================================
Action golden_act;
PKM_Type golden_pkm_type;
Stage golden_stage;
Item golden_item;
Stone golden_stone;

Player_Info tmp_player_info;
Player_Info golden_player_info;
Player_Info last_player_info;
Player_Info attacker_info,defender_info;
Error_Msg golden_err_msg;

integer curr_pat_count;

logic golden_complete;
logic [13:0]golden_deposit_money;
logic [7:0] golden_id;
logic golden_pi;
logic [7:0] last_id,curr_id,attack_id,defend_id;
logic [7:0] golden_DRAM[('h10000):('h107ff)];
logic [14:0] tmp_add_money;
reg [14:0] cycle_counter;
integer first_time;
//================================================================
//  class
//================================================================
class rand_gap;	
	rand int gap;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { gap inside {[1:5]}; }
endclass

class rand_gap2;	
	rand int gap2;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { gap2 inside {[1:9]}; }
endclass

class rand_item;
	rand Item item;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { item inside {Berry, Medicine, Candy, Bracer,Water_stone,Fire_stone,Thunder_stone}; }
endclass

class rand_id;
	rand int id;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit {id inside {[0:255]};}
endclass


//================================================================
//  cycle count
//================================================================
integer curr_gap1;
logic start_give_money;
integer bracer_test;
integer buy_candy_test;
integer use_stone_test;
integer evv_evo_test;
integer buy_berry,buy_medicine,buy_candy,buy_bracer,buy_ws,buy_fs,buy_ts;
integer sell_berry,sell_medicine,sell_candy,sell_bracer,sell_ws,sell_fs,sell_ts;
integer use_berry,use_medicine,use_candy,use_bracer,use_ws,use_fs,use_ts;
//================================================================
//  initial
//================================================================
int test_rand;

rand_gap 		r_gap 		= new(SEED);
rand_gap2 		r_gap2 		= new(SEED);
rand_item 		r_item 		= new(SEED);
rand_id			r_id		= new(SEED);
initial begin
	// read initial DRAM data
	$readmemh(DRAM_p_r, golden_DRAM);
	//
	buy_berry = 0;
	buy_medicine = 0;
	buy_candy = 0;
	buy_bracer = 0;
	buy_ws = 0;
	buy_fs = 0;
	buy_ts = 0;
	//
	sell_berry = 0;
	sell_medicine = 0;
	sell_candy = 0;
	sell_bracer = 0;
	sell_ws = 0;
	sell_fs = 0;
	sell_ts = 0;
	//
	use_berry = 0;
	use_medicine = 0;
	use_candy = 0;
	use_bracer = 0;
	use_ws = 0;
	use_fs = 0;
	use_ts = 0;
	//
	err_Already_Have_PKM = 0;
	err_Bag_is_full = 0;
	err_HP_is_Zero = 0;
	err_Has_Not_Grown = 0;
	err_Not_Having_Item = 0;
	err_Not_Having_PKM = 0;
	err_Out_of_money = 0;
	start_give_money = 0;
	bracer_test = 0;
	first_time = 0;
	buy_candy_test = 0;
	use_stone_test = 0;
	evv_evo_test = 0;
	curr_pat_count = 0;
	// reset signal
	idle_signal;
	golden_id = 0;
	last_id = 87;
	//reset
	reset_task;
	repeat(1)@(negedge clk);
	for(patcount = 0; patcount<110;patcount+=1)begin
		
			if(patcount%11==0) golden_act = Buy;
		else if(patcount%11==1)golden_act = Check;
		else if(patcount%11==2)golden_act = Sell;
		else if(patcount%11==3)golden_act = Check;
		else if(patcount%11==4)golden_act = Use_item;
		else if(patcount%11==5)golden_act = Check;
		else if(patcount%11==6)golden_act = Deposit;
		else if(patcount%11==7)golden_act = Check;
		else if(patcount%11==8)golden_act = Attack;
		else if(patcount%11==9)golden_act = Check;
		else if(patcount%11==10)golden_act = Check;
		
		curr_id = golden_id;
		load_id;
		
		load_act;
		compute_golden;
		write_back_dram;
		check_answer;
		golden_id = golden_id +1;
		curr_pat_count +=1;
		first_time = 1;
		last_id = curr_id;
		defend_id = 0;
		if(golden_err_msg==Already_Have_PKM)
			err_Already_Have_PKM+=1;
		if(golden_err_msg==Bag_is_full)
			err_Bag_is_full+=1;
		if(golden_err_msg==HP_is_Zero)
			err_HP_is_Zero+=1;
		if(golden_err_msg==Has_Not_Grown)
			err_Has_Not_Grown+=1;
		if(golden_err_msg==Not_Having_Item)
			err_Not_Having_Item+=1;
		if(golden_err_msg==Not_Having_PKM)
			err_Not_Having_PKM+=1;
		if(golden_err_msg==Out_of_money)
			err_Out_of_money+=1;

		a = r_gap2.randomize();
		repeat(1) @(negedge clk);
	end
	
	for( k=0;k<10; k=k+1)begin
		for(patcount = 0; patcount<46;patcount+=1)begin
				if(patcount%46==0) golden_act = Buy; //12
			else if(patcount%46==1)golden_act = Buy; //13
			else if(patcount%46==2)golden_act = Sell;
			else if(patcount%46==3)golden_act = Buy; //15
			else if(patcount%46==4)golden_act = Use_item;
			else if(patcount%46==5)golden_act = Buy; //17
			else if(patcount%46==6)golden_act = Deposit;
			else if(patcount%46==7)golden_act = Buy; //19
			else if(patcount%46==8)golden_act = Attack;
			
			else if(patcount%46==9)golden_act = Sell; 
			else if(patcount%46==11)golden_act = Buy;
			else if(patcount%46==12)golden_act = Sell; 
			else if(patcount%46==13)golden_act = Sell; 
			else if(patcount%46==14)golden_act = Use_item;
			else if(patcount%46==15)golden_act = Sell; 
			else if(patcount%46==16)golden_act = Deposit;
			else if(patcount%46==17)golden_act = Sell; 
			else if(patcount%46==18)golden_act = Attack;
			
			else if(patcount%46==19)golden_act = Use_item;
			else if(patcount%46==20)golden_act = Buy;
			else if(patcount%46==21)golden_act = Use_item;
			else if(patcount%46==22)golden_act = Sell;
			else if(patcount%46==23)golden_act = Use_item;
			else if(patcount%46==24)golden_act = Use_item;
			else if(patcount%46==25)golden_act = Deposit;
			else if(patcount%46==26)golden_act = Use_item;
			else if(patcount%46==27)golden_act = Attack;
			
			else if(patcount%46==28)golden_act = Deposit;
			else if(patcount%46==29)golden_act = Buy;
			else if(patcount%46==30)golden_act = Deposit;
			else if(patcount%46==31)golden_act = Sell;
			else if(patcount%46==32)golden_act = Deposit;
			else if(patcount%46==33)golden_act = Use_item;
			else if(patcount%46==34)golden_act = Deposit;
			else if(patcount%46==35)golden_act = Deposit;
			else if(patcount%46==36)golden_act = Attack;
			
			else if(patcount%46==37)golden_act = Attack;
			else if(patcount%46==38)golden_act = Buy;
			else if(patcount%46==39)golden_act = Attack;
			else if(patcount%46==40)golden_act = Sell;
			else if(patcount%46==41)golden_act = Attack;
			else if(patcount%46==42)golden_act = Use_item;
			else if(patcount%46==43)golden_act = Attack;
			else if(patcount%46==44)golden_act = Deposit;
			else if(patcount%46==45)golden_act = Attack;
			
			curr_id = golden_id;
			
			load_id;
			
			load_act;
			
			compute_golden;
			write_back_dram;
			check_answer;
			golden_id = golden_id +1;
			curr_pat_count +=1;
			if(golden_err_msg==Already_Have_PKM)
				err_Already_Have_PKM+=1;
			if(golden_err_msg==Bag_is_full)
				err_Bag_is_full+=1;
			if(golden_err_msg==HP_is_Zero)
				err_HP_is_Zero+=1;
			if(golden_err_msg==Has_Not_Grown)
				err_Has_Not_Grown+=1;
			if(golden_err_msg==Not_Having_Item)
				err_Not_Having_Item+=1;
			if(golden_err_msg==Not_Having_PKM)
				err_Not_Having_PKM+=1;
			if(golden_err_msg==Out_of_money)
				err_Out_of_money+=1;
			
			last_id = curr_id;
			defend_id = 0;
			a = r_gap2.randomize();
			repeat(1) @(negedge clk);
		end
	end
	
	// check bracer stack
	bracer_test = 1;
	start_give_money = 1;
	for(patcount = 0; patcount<3;patcount+=1)begin
		
			if(patcount==0) golden_act = Use_item;
		else if(patcount==1)golden_act = Use_item;
		else if(patcount==2)golden_act = Attack;

		
		curr_id = 10;
		load_id;
		
		load_act;
		compute_golden;
		write_back_dram;
		check_answer;
		curr_pat_count +=1;
		
		last_id = curr_id;
		defend_id = 0;
		if(golden_err_msg==Already_Have_PKM)
			err_Already_Have_PKM+=1;
		if(golden_err_msg==Bag_is_full)
			err_Bag_is_full+=1;
		if(golden_err_msg==HP_is_Zero)
			err_HP_is_Zero+=1;
		if(golden_err_msg==Has_Not_Grown)
			err_Has_Not_Grown+=1;
		if(golden_err_msg==Not_Having_Item)
			err_Not_Having_Item+=1;
		if(golden_err_msg==Not_Having_PKM)
			err_Not_Having_PKM+=1;
		if(golden_err_msg==Out_of_money)
			err_Out_of_money+=1;

		a = r_gap2.randomize();
		repeat(1) @(negedge clk);
	end
	
	// fulfill bag is full to 20
	buy_candy_test = 1;
	for(patcount = 0; patcount<1;patcount+=1)begin
		
		golden_act = Deposit;
		golden_id = 10;
		
		curr_id = 10;
		load_id;
		load_act;
		compute_golden;
		write_back_dram;
		check_answer;
		curr_pat_count +=1;
		
		last_id = curr_id;
		defend_id = 0;
		if(golden_err_msg==Already_Have_PKM)
			err_Already_Have_PKM+=1;
		if(golden_err_msg==Bag_is_full)
			err_Bag_is_full+=1;
		if(golden_err_msg==HP_is_Zero)
			err_HP_is_Zero+=1;
		if(golden_err_msg==Has_Not_Grown)
			err_Has_Not_Grown+=1;
		if(golden_err_msg==Not_Having_Item)
			err_Not_Having_Item+=1;
		if(golden_err_msg==Not_Having_PKM)
			err_Not_Having_PKM+=1;
		if(golden_err_msg==Out_of_money)
			err_Out_of_money+=1;

		a = r_gap2.randomize();
		repeat(1) @(negedge clk);
	end
	for(patcount = 0; patcount<6;patcount+=1)begin
		
		golden_act = Buy;
		golden_id = 10;
		
		curr_id = 10;
		load_id;
		
		load_act;
		compute_golden;
		write_back_dram;
		check_answer;
		curr_pat_count +=1;
		
		last_id = curr_id;
		defend_id = 0;
		if(golden_err_msg==Already_Have_PKM)
			err_Already_Have_PKM+=1;
		if(golden_err_msg==Bag_is_full)
			err_Bag_is_full+=1;
		if(golden_err_msg==HP_is_Zero)
			err_HP_is_Zero+=1;
		if(golden_err_msg==Has_Not_Grown)
			err_Has_Not_Grown+=1;
		if(golden_err_msg==Not_Having_Item)
			err_Not_Having_Item+=1;
		if(golden_err_msg==Not_Having_PKM)
			err_Not_Having_PKM+=1;
		if(golden_err_msg==Out_of_money)
			err_Out_of_money+=1;

		a = r_gap2.randomize();
		repeat(1) @(negedge clk);
	end
	
	// buy each stone
	use_stone_test = 1;
	buy_candy_test = 0;
	bracer_test = 0;
	for(patcount = 0; patcount<6;patcount+=1)begin
		
		if(patcount==0) golden_act=Sell;
		else if(patcount==1) golden_act=Buy;
		else if(patcount==2) golden_act=Sell;
		else if(patcount==3) golden_act=Buy;
		else if(patcount==4) golden_act=Sell;
		else if(patcount==5) golden_act=Buy;
		golden_id = 10;
		
		curr_id = 10;
		load_id;
		load_act;
		compute_golden;
		write_back_dram;
		check_answer;
		curr_pat_count +=1;
		
		last_id = curr_id;
		defend_id = 0;
		if(golden_err_msg==Already_Have_PKM)
			err_Already_Have_PKM+=1;
		if(golden_err_msg==Bag_is_full)
			err_Bag_is_full+=1;
		if(golden_err_msg==HP_is_Zero)
			err_HP_is_Zero+=1;
		if(golden_err_msg==Has_Not_Grown)
			err_Has_Not_Grown+=1;
		if(golden_err_msg==Not_Having_Item)
			err_Not_Having_Item+=1;
		if(golden_err_msg==Not_Having_PKM)
			err_Not_Having_PKM+=1;
		if(golden_err_msg==Out_of_money)
			err_Out_of_money+=1;

		a = r_gap2.randomize();
		repeat(1) @(negedge clk);
	end
	
	evv_evo_test = 1;
	for(patcount = 0; patcount<5;patcount+=1)begin
			if(patcount==0) golden_act=Deposit;
		//else if(patcount==1) golden_act=Sell;
		else if(patcount==1) golden_act=Buy;
		else if(patcount==2) golden_act=Use_item;
		else if(patcount==3) golden_act=Use_item;
		else if(patcount==4) golden_act=Use_item;
		golden_id = 158;
		
		curr_id = 158;
		load_id;
		load_act;
		compute_golden;
		write_back_dram;
		check_answer;
		curr_pat_count +=1;
		
		last_id = curr_id;
		defend_id = 0;
		if(golden_err_msg==Already_Have_PKM)
			err_Already_Have_PKM+=1;
		if(golden_err_msg==Bag_is_full)
			err_Bag_is_full+=1;
		if(golden_err_msg==HP_is_Zero)
			err_HP_is_Zero+=1;
		if(golden_err_msg==Has_Not_Grown)
			err_Has_Not_Grown+=1;
		if(golden_err_msg==Not_Having_Item)
			err_Not_Having_Item+=1;
		if(golden_err_msg==Not_Having_PKM)
			err_Not_Having_PKM+=1;
		if(golden_err_msg==Out_of_money)
			err_Out_of_money+=1;

		a = r_gap2.randomize();
		repeat(1) @(negedge clk);
	end
	
	/*
	$display ("-------------------------------------------------------------------------------------------------");
	$display("Already_Have_PKM %2d",err_Already_Have_PKM);
	$display("Bag_is_full %2d",err_Bag_is_full);
	$display("HP_is_Zero %2d",err_HP_is_Zero);
	$display("Has_Not_Grown %2d",err_Has_Not_Grown);
	$display("Not_Having_Item %2d",err_Not_Having_Item);
	$display("Not_Having_PKM %2d",err_Not_Having_PKM);
	$display("Out_of_money %2d",err_Out_of_money);
	
	$display ("-------------------------------------------------------------------------------------------------");
	$display("buy_berry %2d",buy_berry);
	$display("buy_medicine %2d",buy_medicine);
	$display("buy_candy %2d",buy_candy);
	$display("buy_bracer %2d",buy_bracer);
	$display("buy_ws %2d",buy_ws);
	$display("buy_fs %2d",buy_fs);
	$display("buy_ts %2d",buy_ts);
	$display ("-------------------------------------------------------------------------------------------------");
	$display("sell_berry %2d",sell_berry);
	$display("sell_medicine %2d",sell_medicine);
	$display("sell_candy %2d",sell_candy);
	$display("sell_bracer %2d",sell_bracer);
	$display("sell_ws %2d",sell_ws);
	$display("sell_fs %2d",sell_fs);
	$display("sell_ts %2d",sell_ts);
	$display ("-------------------------------------------------------------------------------------------------");
	$display("use_berry %2d",use_berry);
	$display("use_medicine %2d",use_medicine);
	$display("use_candy %2d",use_candy);
	$display("use_bracer %2d",use_bracer);
	$display("use_ws %2d",use_ws);
	$display("use_fs %2d",use_fs);
	$display("use_ts %2d",use_ts);
	*/
	//repeat(10) @(negedge clk);
	//pass_task;
	$finish;
end

logic [8:0] tmp_hp_adder;
logic [8:0] tmp_exp_adder;
task compute_golden; begin
	last_player_info = {golden_DRAM[20'h10000+(last_id*8)],golden_DRAM[20'h10000+(last_id*8+1)],
						golden_DRAM[20'h10000+(last_id*8+2)],golden_DRAM[20'h10000+(last_id*8+3)],
						golden_DRAM[20'h10000+(last_id*8+4)],golden_DRAM[20'h10000+(last_id*8+5)],
						golden_DRAM[20'h10000+(last_id*8+6)],golden_DRAM[20'h10000+(last_id*8+7)]};
	if(curr_id!=last_id)begin
		case(last_player_info.pkm_info.pkm_type)
			Grass:begin
				case(last_player_info.pkm_info.stage)
					No_stage:last_player_info.pkm_info.atk = 0;
					Lowest:last_player_info.pkm_info.atk = 63;
					Middle:last_player_info.pkm_info.atk = 94;
					Highest:last_player_info.pkm_info.atk = 123;
				endcase
			end
			Fire:begin
				case(last_player_info.pkm_info.stage)
					No_stage:last_player_info.pkm_info.atk = 0;
					Lowest:last_player_info.pkm_info.atk = 64;
					Middle:last_player_info.pkm_info.atk = 96;
					Highest:last_player_info.pkm_info.atk = 127;
				endcase
			end
			Water:begin
				case(last_player_info.pkm_info.stage)
					No_stage:last_player_info.pkm_info.atk = 0;
					Lowest:last_player_info.pkm_info.atk = 60;
					Middle:last_player_info.pkm_info.atk = 89;
					Highest:last_player_info.pkm_info.atk = 113;
				endcase
			end
			Electric:begin
				case(last_player_info.pkm_info.stage)
					No_stage:last_player_info.pkm_info.atk = 0;
					Lowest:last_player_info.pkm_info.atk = 65;
					Middle:last_player_info.pkm_info.atk = 97;
					Highest:last_player_info.pkm_info.atk = 124;
				endcase
			end
			Normal:last_player_info.pkm_info.atk = 62;
		endcase
		golden_DRAM[20'h10000+(last_id*8)] = last_player_info[63:56];
			golden_DRAM[20'h10000+(last_id*8+1)] = last_player_info[55:48];
			golden_DRAM[20'h10000+(last_id*8+2)] = last_player_info[47:40];
			golden_DRAM[20'h10000+(last_id*8+3)] = last_player_info[39:32];
			golden_DRAM[20'h10000+(last_id*8+4)] = last_player_info[31:24];
			golden_DRAM[20'h10000+(last_id*8+5)] = last_player_info[23:16];
			golden_DRAM[20'h10000+(last_id*8+6)] = last_player_info[15:8];
			golden_DRAM[20'h10000+(last_id*8+7)] = last_player_info[7:0];
	end
	//$display("%h",golden_DRAM[40'h10000+(curr_id*8)]);
	golden_err_msg = No_Err;
	golden_player_info = {golden_DRAM[20'h10000+(curr_id*8)],golden_DRAM[20'h10000+(curr_id*8+1)],
						golden_DRAM[20'h10000+(curr_id*8+2)],golden_DRAM[20'h10000+(curr_id*8+3)],
						golden_DRAM[20'h10000+(curr_id*8+4)],golden_DRAM[20'h10000+(curr_id*8+5)],
						golden_DRAM[20'h10000+(curr_id*8+6)],golden_DRAM[20'h10000+(curr_id*8+7)]};
	
	//$display("Current Player Info %h",golden_player_info);
	if(golden_act==Sell)begin
		if(golden_pi==1)begin
			if(golden_player_info.pkm_info.stage==No_stage)begin
				//$display("Do not have a Pokemon (1)!");
				golden_err_msg = Not_Having_PKM;
				golden_player_info = 0;
			end
			else if(golden_player_info.pkm_info.stage==Lowest)begin
				//$display("Pokemon is in the lowest stage (3)");
				golden_err_msg = Has_Not_Grown;
				golden_player_info = 0;
			end
			else begin
				case(golden_player_info.pkm_info.pkm_type)
					Grass:begin
						if(golden_player_info.pkm_info.stage==Middle)begin
							if(16383-golden_player_info.bag_info.money<=510)
								golden_player_info.bag_info.money = 16383;
							else
								golden_player_info.bag_info.money=golden_player_info.bag_info.money + 510;
						end
						else if(golden_player_info.pkm_info.stage==Highest)begin
							if(16383-golden_player_info.bag_info.money<=1100)
								golden_player_info.bag_info.money = 16383;
							else
								golden_player_info.bag_info.money=golden_player_info.bag_info.money +1100;
						end
					end
					Fire:begin
						if(golden_player_info.pkm_info.stage==Middle)begin
							if(16383-golden_player_info.bag_info.money<=450)
								golden_player_info.bag_info.money = 16383;
							else
								golden_player_info.bag_info.money=golden_player_info.bag_info.money + 450;
						end
						else if(golden_player_info.pkm_info.stage==Highest)begin
							if(16383-golden_player_info.bag_info.money<=1000)
								golden_player_info.bag_info.money = 16383;
							else
								golden_player_info.bag_info.money=golden_player_info.bag_info.money +1000;
						end
					end
					
					Water:begin
						if(golden_player_info.pkm_info.stage==Middle)begin
							if(16383-golden_player_info.bag_info.money<=500)
								golden_player_info.bag_info.money = 16383;
							else
								golden_player_info.bag_info.money=golden_player_info.bag_info.money + 500;
						end
						else if(golden_player_info.pkm_info.stage==Highest)begin
							if(16383-golden_player_info.bag_info.money<=1200)
								golden_player_info.bag_info.money = 16383;
							else
								golden_player_info.bag_info.money=golden_player_info.bag_info.money +1200;
						end
					end
					Electric:begin
						if(golden_player_info.pkm_info.stage==Middle)begin
							if(16383-golden_player_info.bag_info.money<=550)
								golden_player_info.bag_info.money = 16383;
							else
								golden_player_info.bag_info.money=golden_player_info.bag_info.money + 550;
						end
						else if(golden_player_info.pkm_info.stage==Highest)begin
							if(16383-golden_player_info.bag_info.money<=1300)
								golden_player_info.bag_info.money = 16383;
							else
								golden_player_info.bag_info.money=golden_player_info.bag_info.money +1300;
						end
					end
					
					Normal:begin
						
					end
					
				endcase
				golden_player_info.pkm_info = 0;
			end
		end
		else begin
			if(golden_item==Berry && golden_player_info.bag_info.berry_num==0)begin
				//$display("Do not have item (2) ");
				sell_berry -=1;
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(golden_item==Medicine && golden_player_info.bag_info.medicine_num==0)begin
				//$display("Do not have item (2) ");
				sell_medicine-=1;
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(golden_item==Candy && golden_player_info.bag_info.candy_num==0)begin
				//$display("Do not have item (2) ");
				sell_candy-=1;
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(golden_item==Bracer && golden_player_info.bag_info.bracer_num==0)begin
				//$display("Do not have item (2) ");
				sell_bracer-=1;
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(golden_item==Water_stone && golden_player_info.bag_info.stone!=W_stone)begin
				//$display("Do not have item (2) ");
				sell_ws-=1;
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(golden_item==Fire_stone && golden_player_info.bag_info.stone!=F_stone)begin
				//$display("Do not have item (2) ");
				sell_fs-=1;
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(golden_item==Thunder_stone && golden_player_info.bag_info.stone!=T_stone)begin
				//$display("Do not have item (2) ");
				sell_ts-=1;
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else 
				case(golden_item)
					Berry: begin 
						golden_player_info.bag_info.berry_num=golden_player_info.bag_info.berry_num-1;
						if(16383-golden_player_info.bag_info.money<=12)
							golden_player_info.bag_info.money = 16383;
						else
							golden_player_info.bag_info.money=golden_player_info.bag_info.money+12;
					end
					Medicine:begin
						golden_player_info.bag_info.medicine_num=golden_player_info.bag_info.medicine_num-1;
						if(16383-golden_player_info.bag_info.money<=96)
							golden_player_info.bag_info.money = 16383;
						else
							golden_player_info.bag_info.money=golden_player_info.bag_info.money+96;
					end
					Candy: begin 
						golden_player_info.bag_info.candy_num=golden_player_info.bag_info.candy_num-1;
						if(16383-golden_player_info.bag_info.money<=225)
							golden_player_info.bag_info.money = 16383;
						else
							golden_player_info.bag_info.money=golden_player_info.bag_info.money+225;
					end
					Bracer: begin 
						golden_player_info.bag_info.bracer_num=golden_player_info.bag_info.bracer_num-1;
						if(16383-golden_player_info.bag_info.money<=48)
							golden_player_info.bag_info.money = 16383;
						else
							golden_player_info.bag_info.money=golden_player_info.bag_info.money+48;
					end
					Water_stone:begin
						golden_player_info.bag_info.stone=No_stone;
						if(16383-golden_player_info.bag_info.money<=600)
							golden_player_info.bag_info.money = 16383;
						else
							golden_player_info.bag_info.money=golden_player_info.bag_info.money+600;
					end
					Fire_stone:begin
						golden_player_info.bag_info.stone=No_stone;
						if(16383-golden_player_info.bag_info.money<=600)
							golden_player_info.bag_info.money = 16383;
						else
							golden_player_info.bag_info.money=golden_player_info.bag_info.money+600;
					end
					Thunder_stone:begin
						golden_player_info.bag_info.stone=No_stone;
						if(16383-golden_player_info.bag_info.money<=600)
							golden_player_info.bag_info.money = 16383;
						else
							golden_player_info.bag_info.money=golden_player_info.bag_info.money+600;
					end
				endcase
		end
	end
	else if(golden_act==Deposit) begin
		//$display("%h",golden_player_info.bag_info.money);
		if(16383-golden_player_info.bag_info.money<=golden_deposit_money)
			golden_player_info.bag_info.money = 16383;
		else
			golden_player_info.bag_info.money = golden_player_info.bag_info.money + golden_deposit_money;
	end
	else if(golden_act==Use_item)begin
		if(golden_player_info.pkm_info==0)begin
			//$display("Do not have a Pokemon (1)");
			golden_err_msg = Not_Having_PKM;
			golden_player_info = 0;
		end
		else if(golden_item==Berry && golden_player_info.bag_info.berry_num==0)begin
			//$display("Do not have item (2)");
			use_berry-=1;
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
		end
		else if(golden_item==Medicine && golden_player_info.bag_info.medicine_num==0)begin
			//$display("Do not have item (2)");
			use_medicine-=1;
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
		end
		else if(golden_item==Candy && golden_player_info.bag_info.candy_num==0)begin
			//$display("Do not have item (2)");
			use_candy-=1;
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
		end
		else if(golden_item==Bracer && golden_player_info.bag_info.bracer_num==0)begin
			//$display("Do not have item (2)");
			use_bracer-=1;
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
		end
		else if((golden_item==Water_stone && golden_player_info.bag_info.stone!=W_stone) ||
				(golden_item==Thunder_stone && golden_player_info.bag_info.stone!=T_stone) ||
				(golden_item==Fire_stone && golden_player_info.bag_info.stone!=F_stone))begin
			//$display("Do not have item (2)");
			if(golden_item==Water_stone)begin
				use_ws-=1;
			end
			else if(golden_item==Fire_stone)begin
				use_fs-=1;
			end
			else if(golden_item==Thunder_stone)begin
				use_ts-=1;
			end
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
			end
		else
			case(golden_item)
				Berry:begin
					tmp_hp_adder = golden_player_info.pkm_info.hp;
					golden_player_info.bag_info.berry_num = golden_player_info.bag_info.berry_num - 1;
					case(golden_player_info.pkm_info.pkm_type) //type
						Grass:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_hp_adder+32<=128)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 128; 
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(tmp_hp_adder+32<=192)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 192; 
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								if(tmp_hp_adder+32<=254)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 254;
							end
						end
						Fire:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_hp_adder+32<=119)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 119; 
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(tmp_hp_adder+32<=177)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 177; 
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								if(tmp_hp_adder+32<=225)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 225;
							end
						end
						Water:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_hp_adder+32<=125)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 125; 
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(tmp_hp_adder+32<=187)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 187; 
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								if(tmp_hp_adder+32<=245)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 245;
							end
						end
						Electric:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_hp_adder+32<=122)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 122; 
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(tmp_hp_adder+32<=182)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 182; 
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								if(tmp_hp_adder+32<=235)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 235;
							end
						end
						Normal:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_hp_adder+32<=124)
									golden_player_info.pkm_info.hp = golden_player_info.pkm_info.hp+32;
								else
									golden_player_info.pkm_info.hp = 124; 
							end
						end
						
					endcase
				end
				Medicine:begin
					case(golden_player_info.pkm_info.pkm_type)
						Grass:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								golden_player_info.pkm_info.hp = 128;
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								golden_player_info.pkm_info.hp = 192;
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								golden_player_info.pkm_info.hp = 254;
							end
						end
						Fire:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								golden_player_info.pkm_info.hp = 119;
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								golden_player_info.pkm_info.hp = 177;
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								golden_player_info.pkm_info.hp = 225;
							end
						end
						Water:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								golden_player_info.pkm_info.hp = 125;
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								golden_player_info.pkm_info.hp = 187;
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								golden_player_info.pkm_info.hp = 245;
							end
						end
						Electric:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								golden_player_info.pkm_info.hp = 122;
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								golden_player_info.pkm_info.hp = 182;
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								golden_player_info.pkm_info.hp = 235;
							end
						end
						Normal:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								golden_player_info.pkm_info.hp = 124;
							end
						end
					endcase
					golden_player_info.bag_info.medicine_num = golden_player_info.bag_info.medicine_num-1;
				end
				Candy:begin
					tmp_exp_adder = golden_player_info.pkm_info.exp + 15;
					case(golden_player_info.pkm_info.pkm_type)
						Grass:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_exp_adder>=32)begin
									golden_player_info.pkm_info.stage = Middle;
									golden_player_info.pkm_info.hp = 192;
									golden_player_info.pkm_info.atk = 94;
									golden_player_info.pkm_info.exp = 0;
									
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(tmp_exp_adder>=63)begin
									golden_player_info.pkm_info.stage = Highest;
									golden_player_info.pkm_info.hp = 254;
									golden_player_info.pkm_info.atk = 123;
									golden_player_info.pkm_info.exp = 0;
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								golden_player_info.pkm_info.exp = 0;
							end
						end
						Fire:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_exp_adder>=30)begin
									golden_player_info.pkm_info.stage = Middle;
									golden_player_info.pkm_info.hp = 177;
									golden_player_info.pkm_info.atk = 96;
									golden_player_info.pkm_info.exp = 0;
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(tmp_exp_adder>=59)begin
									golden_player_info.pkm_info.stage = Highest;
									golden_player_info.pkm_info.hp = 225;
									golden_player_info.pkm_info.atk = 127;
									golden_player_info.pkm_info.exp = 0;
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								golden_player_info.pkm_info.exp = 0;
							end
						end
						Water:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_exp_adder>=28)begin
									golden_player_info.pkm_info.stage = Middle;
									golden_player_info.pkm_info.hp = 187;
									golden_player_info.pkm_info.atk = 89;
									golden_player_info.pkm_info.exp = 0;
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(tmp_exp_adder>=55)begin
									golden_player_info.pkm_info.stage = Highest;
									golden_player_info.pkm_info.hp = 245;
									golden_player_info.pkm_info.atk = 113;
									golden_player_info.pkm_info.exp = 0;
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								golden_player_info.pkm_info.exp = 0;
							end
						end
						Electric:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_exp_adder>=26)begin
									golden_player_info.pkm_info.stage = Middle;
									golden_player_info.pkm_info.hp = 182;
									golden_player_info.pkm_info.atk = 97;
									golden_player_info.pkm_info.exp = 0;
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(tmp_exp_adder>=51)begin
									golden_player_info.pkm_info.stage = Highest;
									golden_player_info.pkm_info.hp = 235;
									golden_player_info.pkm_info.atk = 124;
									golden_player_info.pkm_info.exp = 0;
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								golden_player_info.pkm_info.exp = 0;
							end
						end
						Normal:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(tmp_exp_adder>=29)begin
									golden_player_info.pkm_info.exp = 29;
								end
								else
									golden_player_info.pkm_info.exp = tmp_exp_adder;
							end
						end
					endcase
					golden_player_info.bag_info.candy_num = golden_player_info.bag_info.candy_num-1;
				end
				Bracer:begin
					case(golden_player_info.pkm_info.pkm_type)
						Grass:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(golden_player_info.pkm_info.atk==63)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(golden_player_info.pkm_info.atk==94)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								if(golden_player_info.pkm_info.atk==123)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
						end
						Fire:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(golden_player_info.pkm_info.atk==64)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(golden_player_info.pkm_info.atk==96)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								if(golden_player_info.pkm_info.atk==127)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
						end
						Water:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(golden_player_info.pkm_info.atk==60)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(golden_player_info.pkm_info.atk==89)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								if(golden_player_info.pkm_info.atk==113)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
						end
						Electric:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(golden_player_info.pkm_info.atk==65)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else if(golden_player_info.pkm_info.stage==Middle)begin
								if(golden_player_info.pkm_info.atk==97)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else if(golden_player_info.pkm_info.stage==Highest)begin
								if(golden_player_info.pkm_info.atk==124)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
						end
						Normal:begin
							if(golden_player_info.pkm_info.stage==Lowest)begin //stage
								if(golden_player_info.pkm_info.atk==62)begin
									golden_player_info.pkm_info.atk = golden_player_info.pkm_info.atk+32;
								end
							end
							else
								$display("normal only can be stage1 please check dram");
						end
					endcase
					golden_player_info.bag_info.bracer_num = golden_player_info.bag_info.bracer_num-1;
				end
				Water_stone:begin
					if(golden_player_info.pkm_info.pkm_type==Normal && golden_player_info.pkm_info.exp==29)begin
						golden_player_info.pkm_info.stage = Highest;
						golden_player_info.pkm_info.pkm_type = Water;
						golden_player_info.pkm_info.hp = 245;
						golden_player_info.pkm_info.atk = 113;
						golden_player_info.pkm_info.exp = 0;
						
						golden_player_info.bag_info.stone = No_stone;
					end
					else begin
						golden_player_info.bag_info.stone = No_stone;
					end
				end
				Fire_stone:begin
					if(golden_player_info.pkm_info.pkm_type==Normal && golden_player_info.pkm_info.exp==29)begin
						golden_player_info.pkm_info.stage = Highest;
						golden_player_info.pkm_info.pkm_type = Fire;
						golden_player_info.pkm_info.hp = 225;
						golden_player_info.pkm_info.atk = 127;
						golden_player_info.pkm_info.exp = 0;

						golden_player_info.bag_info.stone = No_stone;
					end
					else begin
						golden_player_info.bag_info.stone = No_stone;
					end
				end
				Thunder_stone:begin
					if(golden_player_info.pkm_info.pkm_type==Normal && golden_player_info.pkm_info.exp==29)begin
						golden_player_info.pkm_info.stage = Highest;
						golden_player_info.pkm_info.pkm_type = Electric;
						golden_player_info.pkm_info.hp = 235;
						golden_player_info.pkm_info.atk = 124;
						golden_player_info.pkm_info.exp = 0;
						
						golden_player_info.bag_info.stone = No_stone;
					end
					else begin
						golden_player_info.bag_info.stone = No_stone;
					end
				end
			endcase
	end
	else if(golden_act==Attack)begin
		attacker_info = {golden_DRAM[20'h10000+(attack_id*8)],golden_DRAM[20'h10000+(attack_id*8+1)],
						golden_DRAM[20'h10000+(attack_id*8+2)],golden_DRAM[20'h10000+(attack_id*8+3)],
						golden_DRAM[20'h10000+(attack_id*8+4)],golden_DRAM[20'h10000+(attack_id*8+5)],
						golden_DRAM[20'h10000+(attack_id*8+6)],golden_DRAM[20'h10000+(attack_id*8+7)]};
		defender_info = {golden_DRAM[20'h10000+(defend_id*8)],golden_DRAM[20'h10000+(defend_id*8+1)],
						golden_DRAM[20'h10000+(defend_id*8+2)],golden_DRAM[20'h10000+(defend_id*8+3)],
						golden_DRAM[20'h10000+(defend_id*8+4)],golden_DRAM[20'h10000+(defend_id*8+5)],
						golden_DRAM[20'h10000+(defend_id*8+6)],golden_DRAM[20'h10000+(defend_id*8+7)]};
		if(attacker_info.pkm_info.stage == No_stage || defender_info.pkm_info.stage == No_stage)begin
			//$display("Do not have a Pokemon (1)");
			golden_err_msg = Not_Having_PKM;
			attacker_info = 0;
			defender_info = 0;
		end
		else if(attacker_info.pkm_info.hp == 0 || defender_info.pkm_info.hp == 0)begin
			//$display("HP is zero (2) ");
			golden_err_msg = HP_is_Zero;
			attacker_info = 0;
			defender_info = 0;
		end
		else begin
			// compute defender hp first
			case(defender_info.pkm_info.pkm_type)
				Grass:begin
					if(attacker_info.pkm_info.pkm_type==Fire)begin //2
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*2)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*2;
					end
					else if(attacker_info.pkm_info.pkm_type==Normal)begin //1
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*1)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*1;
					end
					else begin
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*0.5)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*0.5;
					end
				end
				Fire:begin
					if(attacker_info.pkm_info.pkm_type==Water)begin
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*2)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*2;
					end
					else if(attacker_info.pkm_info.pkm_type==Electric || attacker_info.pkm_info.pkm_type==Normal)begin
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*1)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*1;
					end
					else begin
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*0.5)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*0.5;
					end
				end
				Water:begin
					if(attacker_info.pkm_info.pkm_type==Grass || attacker_info.pkm_info.pkm_type==Electric)begin
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*2)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*2;
					end
					else if(attacker_info.pkm_info.pkm_type==Normal)begin
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*1)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*1;
					end
					else begin
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*0.5)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*0.5;
					end
				end
				Electric:begin
					if(attacker_info.pkm_info.pkm_type==Electric)begin // 0.5
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*0.5)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*0.5;
					end
					else begin //1
						if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*1)
							defender_info.pkm_info.hp = 0;
						else
							defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*1;
					end
				end
				Normal:begin
					if(defender_info.pkm_info.hp<=attacker_info.pkm_info.atk*1)
						defender_info.pkm_info.hp = 0;
					else
						defender_info.pkm_info.hp = defender_info.pkm_info.hp - attacker_info.pkm_info.atk*1;
				end
			endcase	
			// compute exp
			case(attacker_info.pkm_info.pkm_type)
				Grass:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>32)begin
									attacker_info.pkm_info.exp = 32;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>32)begin
									attacker_info.pkm_info.exp = 32;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>32)begin
									attacker_info.pkm_info.exp = 32;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase
					end
					else if(attacker_info.pkm_info.stage==Middle)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>63)begin
									attacker_info.pkm_info.exp = 63;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>63)begin
									attacker_info.pkm_info.exp = 63;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>63)begin
									attacker_info.pkm_info.exp = 63;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase
					end
					else if(attacker_info.pkm_info.stage==Highest)begin
						attacker_info.pkm_info.exp  = 0;
					end
				end
				Fire:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>30)begin
									attacker_info.pkm_info.exp = 30;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>30)begin
									attacker_info.pkm_info.exp = 30;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>30)begin
									attacker_info.pkm_info.exp = 30;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase

					end
					else if(attacker_info.pkm_info.stage==Middle)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>59)begin
									attacker_info.pkm_info.exp = 59;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>59)begin
									attacker_info.pkm_info.exp = 59;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>59)begin
									attacker_info.pkm_info.exp = 59;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase
					end
					else if(attacker_info.pkm_info.stage==Highest)begin
						attacker_info.pkm_info.exp  = 0;
					end
				end
				Water:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>28)begin
									attacker_info.pkm_info.exp = 28;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>28)begin
									attacker_info.pkm_info.exp = 28;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>28)begin
									attacker_info.pkm_info.exp = 28;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase
					end
					else if(attacker_info.pkm_info.stage==Middle)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>55)begin
									attacker_info.pkm_info.exp = 55;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>55)begin
									attacker_info.pkm_info.exp = 55;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>55)begin
									attacker_info.pkm_info.exp = 55;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase
					end
					else if(attacker_info.pkm_info.stage==Highest)begin
						attacker_info.pkm_info.exp  = 0;
					end
				end
				Electric:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>26)begin
									attacker_info.pkm_info.exp = 26;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>26)begin
									attacker_info.pkm_info.exp = 26;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>26)begin
									attacker_info.pkm_info.exp = 26;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase
					end
					else if(attacker_info.pkm_info.stage==Middle)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>51)begin
									attacker_info.pkm_info.exp = 51;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>51)begin
									attacker_info.pkm_info.exp = 51;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>51)begin
									attacker_info.pkm_info.exp = 51;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase
					end
					else if(attacker_info.pkm_info.stage==Highest)begin
						attacker_info.pkm_info.exp  = 0;
					end
				end
				Normal:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						case(defender_info.pkm_info.stage)
							Lowest:begin
								if(attacker_info.pkm_info.exp+16>29)begin
									attacker_info.pkm_info.exp = 29;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 16;
								end
							end
							Middle:begin
								if(attacker_info.pkm_info.exp+24>29)begin
									attacker_info.pkm_info.exp = 29;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 24;
								end
							end
							Highest:begin
								if(attacker_info.pkm_info.exp+32>29)begin
									attacker_info.pkm_info.exp = 29;
								end
								else begin
									attacker_info.pkm_info.exp = attacker_info.pkm_info.exp + 32;
								end
							end
						endcase
					end
				end
			endcase
			case(defender_info.pkm_info.pkm_type)
			Grass:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>32)begin
								defender_info.pkm_info.exp = 32;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>32)begin
								defender_info.pkm_info.exp = 32;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>32)begin
								defender_info.pkm_info.exp = 32;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defender_info.pkm_info.stage==Middle)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>63)begin
								defender_info.pkm_info.exp = 63;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>63)begin
								defender_info.pkm_info.exp = 63;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>63)begin
								defender_info.pkm_info.exp = 63;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defender_info.pkm_info.stage==Highest)begin
					defender_info.pkm_info.exp  = 0;
				end
			end
			Fire:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>30)begin
								defender_info.pkm_info.exp = 30;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>30)begin
								defender_info.pkm_info.exp = 30;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>30)begin
								defender_info.pkm_info.exp = 30;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defender_info.pkm_info.stage==Middle)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>59)begin
								defender_info.pkm_info.exp = 59;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>59)begin
								defender_info.pkm_info.exp = 59;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>59)begin
								defender_info.pkm_info.exp = 59;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defender_info.pkm_info.stage==Highest)begin
					defender_info.pkm_info.exp  = 0;
				end
			end
			Water:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>28)begin
								defender_info.pkm_info.exp = 28;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>28)begin
								defender_info.pkm_info.exp = 28;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>28)begin
								defender_info.pkm_info.exp = 28;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defender_info.pkm_info.stage==Middle)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>55)begin
								defender_info.pkm_info.exp = 55;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>55)begin
								defender_info.pkm_info.exp = 55;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>55)begin
								defender_info.pkm_info.exp = 55;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defender_info.pkm_info.stage==Highest)begin
					defender_info.pkm_info.exp  = 0;
				end
			end
			Electric:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>26)begin
								defender_info.pkm_info.exp = 26;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>26)begin
								defender_info.pkm_info.exp = 26;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>26)begin
								defender_info.pkm_info.exp = 26;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defender_info.pkm_info.stage==Middle)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>51)begin
								defender_info.pkm_info.exp = 51;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>51)begin
								defender_info.pkm_info.exp = 51;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>51)begin
								defender_info.pkm_info.exp = 51;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defender_info.pkm_info.stage==Highest)begin
					defender_info.pkm_info.exp  = 0;
				end
			end
			Normal:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					case(attacker_info.pkm_info.stage)
						Lowest:begin
							if(defender_info.pkm_info.exp+8>29)begin
								defender_info.pkm_info.exp = 29;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defender_info.pkm_info.exp+12>29)begin
								defender_info.pkm_info.exp = 29;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defender_info.pkm_info.exp+16>29)begin
								defender_info.pkm_info.exp = 29;
							end
							else begin
								defender_info.pkm_info.exp = defender_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
			end
		endcase
			// decide evo or not
			case(attacker_info.pkm_info.pkm_type)
				Grass:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						if(attacker_info.pkm_info.exp==32)begin
							attacker_info.pkm_info.stage = Middle;
							attacker_info.pkm_info.hp = 192;
							attacker_info.pkm_info.atk = 94;
							attacker_info.pkm_info.exp = 0;
							
						end
						else begin
							attacker_info.pkm_info.atk = 63;
						end
					end
					else if(attacker_info.pkm_info.stage==Middle)begin
						if(attacker_info.pkm_info.exp==63)begin
							attacker_info.pkm_info.stage = Highest;
							attacker_info.pkm_info.hp = 254;
							attacker_info.pkm_info.atk = 123;
							attacker_info.pkm_info.exp = 0;
						end
						else begin
							attacker_info.pkm_info.atk = 94;
						end
					end
					else if(attacker_info.pkm_info.stage==Highest)begin
						attacker_info.pkm_info.exp  = 0;
						attacker_info.pkm_info.atk = 123;
					end
				end
				Fire:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						if(attacker_info.pkm_info.exp==30)begin
							attacker_info.pkm_info.stage = Middle;
							attacker_info.pkm_info.hp = 177;
							attacker_info.pkm_info.atk = 96;
							attacker_info.pkm_info.exp = 0;
						end
						else begin
							attacker_info.pkm_info.atk = 64;
						end
					end
					else if(attacker_info.pkm_info.stage==Middle)begin
						if(attacker_info.pkm_info.exp==59)begin
							attacker_info.pkm_info.stage = Highest;
							attacker_info.pkm_info.hp = 225;
							attacker_info.pkm_info.atk = 127;
							attacker_info.pkm_info.exp = 0;
						end
						else begin
							attacker_info.pkm_info.atk = 96;
						end
					end
					else if(attacker_info.pkm_info.stage==Highest)begin
						attacker_info.pkm_info.exp  = 0;
						attacker_info.pkm_info.atk = 127;
					end
				end
				Water:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						if(attacker_info.pkm_info.exp==28)begin
							attacker_info.pkm_info.stage = Middle;
							attacker_info.pkm_info.hp = 187;
							attacker_info.pkm_info.atk = 89;
							attacker_info.pkm_info.exp = 0;
						end
						else begin
							attacker_info.pkm_info.atk = 60;
						end
					end
					else if(attacker_info.pkm_info.stage==Middle)begin
						if(attacker_info.pkm_info.exp==55)begin
							attacker_info.pkm_info.stage = Highest;
							attacker_info.pkm_info.atk = 113;
							attacker_info.pkm_info.hp = 245;
							attacker_info.pkm_info.exp = 0;
						end
						else begin
							attacker_info.pkm_info.atk = 89;
						end
					end
					else if(attacker_info.pkm_info.stage==Highest)begin
						//$display("enter");
						attacker_info.pkm_info.exp  = 0;
						attacker_info.pkm_info.atk = 113;
					end
				end
				Electric:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						if(attacker_info.pkm_info.exp==26)begin
							attacker_info.pkm_info.stage = Middle;
							attacker_info.pkm_info.hp = 182;
							attacker_info.pkm_info.atk = 97;
							attacker_info.pkm_info.exp = 0;
						end
						else begin
							attacker_info.pkm_info.atk = 65;
						end
					end
					else if(attacker_info.pkm_info.stage==Middle)begin
						if(attacker_info.pkm_info.exp==51)begin
							attacker_info.pkm_info.stage = Highest;
							attacker_info.pkm_info.hp = 235;
							attacker_info.pkm_info.atk = 124;
							attacker_info.pkm_info.exp = 0;
						end
						else begin
							attacker_info.pkm_info.atk = 97;
						end
					end
					else if(attacker_info.pkm_info.stage==Highest)begin
						attacker_info.pkm_info.exp  = 0;
						attacker_info.pkm_info.atk = 124;
					end
				end
				Normal:begin
					if(attacker_info.pkm_info.stage==Lowest)begin
						if(attacker_info.pkm_info.exp==29)begin
							attacker_info.pkm_info.exp = 29;
							attacker_info.pkm_info.atk = 62;
						end
						else begin
							attacker_info.pkm_info.atk = 62;
						end
					end
				end
			endcase
			case(defender_info.pkm_info.pkm_type)
			Grass:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					if(defender_info.pkm_info.exp==32)begin
						defender_info.pkm_info.stage = Middle;
						defender_info.pkm_info.hp = 192;
						defender_info.pkm_info.atk = 94;
						defender_info.pkm_info.exp = 0;
					end
					else begin
						defender_info.pkm_info.atk = 63;
					end
				end
				else if(defender_info.pkm_info.stage==Middle)begin
					if(defender_info.pkm_info.exp==63)begin
						defender_info.pkm_info.stage = Highest;
						defender_info.pkm_info.hp = 254;
						defender_info.pkm_info.atk = 123;
						defender_info.pkm_info.exp = 0;
					end
					else begin
						defender_info.pkm_info.atk = 94;
					end
				end
				else if(defender_info.pkm_info.stage==Highest)begin
					defender_info.pkm_info.exp  = 0;
					defender_info.pkm_info.atk = 123;
				end
			end
			Fire:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					if(defender_info.pkm_info.exp==30)begin
						defender_info.pkm_info.stage = Middle;
						defender_info.pkm_info.hp = 177;
						defender_info.pkm_info.atk = 96;
						defender_info.pkm_info.exp = 0;
					end
					else begin
						defender_info.pkm_info.atk = 64;
						
					end
				end
				else if(defender_info.pkm_info.stage==Middle)begin
					if(defender_info.pkm_info.exp==59)begin
						defender_info.pkm_info.stage = Highest;
						defender_info.pkm_info.hp = 225;
						defender_info.pkm_info.atk = 127;
						defender_info.pkm_info.exp = 0;
					end
					else begin
						defender_info.pkm_info.atk = 96;
					end
				end
				else if(defender_info.pkm_info.stage==Highest)begin
					defender_info.pkm_info.exp  = 0;
					defender_info.pkm_info.atk = 127;
				end
			end
			Water:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					if(defender_info.pkm_info.exp==28)begin
						defender_info.pkm_info.stage = Middle;
						defender_info.pkm_info.hp = 187;
						defender_info.pkm_info.atk = 89;
						defender_info.pkm_info.exp = 0;
					end
					else begin
						defender_info.pkm_info.atk = 60;
					end
				end
				else if(defender_info.pkm_info.stage==Middle)begin
					if(defender_info.pkm_info.exp==55)begin
						defender_info.pkm_info.stage = Highest;
						defender_info.pkm_info.hp = 245;
						defender_info.pkm_info.atk = 113;
						defender_info.pkm_info.exp = 0;
					end
					else begin
						defender_info.pkm_info.atk = 89;
					end
				end
				else if(defender_info.pkm_info.stage==Highest)begin
					defender_info.pkm_info.exp  = 0;
					defender_info.pkm_info.atk = 113;
				end
			end
			Electric:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					if(defender_info.pkm_info.exp==26)begin
						defender_info.pkm_info.stage = Middle;
						defender_info.pkm_info.hp = 182;
						defender_info.pkm_info.atk = 97;
						defender_info.pkm_info.exp = 0;
					end
					else begin
						defender_info.pkm_info.atk = 65;
					end
				end
				else if(defender_info.pkm_info.stage==Middle)begin
					if(defender_info.pkm_info.exp==51)begin
						defender_info.pkm_info.stage = Highest;
						defender_info.pkm_info.hp = 235;
						defender_info.pkm_info.atk = 124;
						defender_info.pkm_info.exp = 0;
					end
					else begin
						defender_info.pkm_info.atk = 97;
					end
				end
				else if(defender_info.pkm_info.stage==Highest)begin
					defender_info.pkm_info.exp  = 0;
					defender_info.pkm_info.atk = 124;
				end
			end
			Normal:begin
				if(defender_info.pkm_info.stage==Lowest)begin
					if(defender_info.pkm_info.exp==29)begin
						defender_info.pkm_info.exp = 29;
						defender_info.pkm_info.atk = 62;
					end
					else begin
						defender_info.pkm_info.atk = 62;
					end
				end
			end
		endcase	
		end
	end
	else if(golden_act==Check)begin
	
	end
	else if(golden_act==Buy)begin
		if(golden_pi==1)begin
			if(golden_pkm_type == Grass && golden_player_info.bag_info.money<100)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(golden_pkm_type == Fire && golden_player_info.bag_info.money<90)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(golden_pkm_type == Water && golden_player_info.bag_info.money<110)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(golden_pkm_type == Electric && golden_player_info.bag_info.money<120)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(golden_pkm_type == Normal && golden_player_info.bag_info.money<130)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(golden_player_info.pkm_info.stage!=No_stage)begin
				//$display("Already have a Pokemon (2)");
				golden_player_info = 0;
				golden_err_msg = Already_Have_PKM;
			end
			
			else 
				case(golden_pkm_type)
					Grass:begin
						golden_player_info.pkm_info.stage = Lowest;
						golden_player_info.pkm_info.pkm_type = Grass;
						golden_player_info.pkm_info.hp = 128;
						golden_player_info.pkm_info.atk = 63;
						golden_player_info.pkm_info.exp = 0;
						golden_player_info.bag_info.money = golden_player_info.bag_info.money-100;
					end
					Fire:begin
						golden_player_info.pkm_info.stage = Lowest;
						golden_player_info.pkm_info.pkm_type = Fire;
						golden_player_info.pkm_info.hp = 119;
						golden_player_info.pkm_info.atk = 64;
						golden_player_info.pkm_info.exp = 0;
						golden_player_info.bag_info.money = golden_player_info.bag_info.money-90;
					end
					Water:begin
						golden_player_info.pkm_info.stage = Lowest;
						golden_player_info.pkm_info.pkm_type = Water;
						golden_player_info.pkm_info.hp = 125;
						golden_player_info.pkm_info.atk = 60;
						golden_player_info.pkm_info.exp = 0;
						golden_player_info.bag_info.money = golden_player_info.bag_info.money-110;
					end
					Electric:begin
						golden_player_info.pkm_info.stage = Lowest;
						golden_player_info.pkm_info.pkm_type = Electric;
						golden_player_info.pkm_info.hp = 122;
						golden_player_info.pkm_info.atk = 65;
						golden_player_info.pkm_info.exp = 0;
						golden_player_info.bag_info.money = golden_player_info.bag_info.money-120;
					end
					Normal:begin
						golden_player_info.pkm_info.stage = Lowest;
						golden_player_info.pkm_info.pkm_type = Normal;
						golden_player_info.pkm_info.hp = 124;
						golden_player_info.pkm_info.atk = 62;
						golden_player_info.pkm_info.exp = 0;
						golden_player_info.bag_info.money = golden_player_info.bag_info.money-130;
					end
				endcase
		end
		else begin
			case(golden_item)
				Berry: begin 
					if(golden_player_info.bag_info.money<16)begin
						//$display("Out of money (1) ");
						buy_berry-=1;
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.berry_num==15)begin
						//$display("Bag is full (3)  ");
						buy_berry-=1;
						golden_player_info = 0;
						golden_err_msg = Bag_is_full;
					end
					else begin
						golden_player_info.bag_info.berry_num=golden_player_info.bag_info.berry_num+1;
						golden_player_info.bag_info.money=golden_player_info.bag_info.money-16;
					end
					
				end
				Medicine:begin
					if(golden_player_info.bag_info.money<128)begin
						//$display("Out of money (1) ");
						buy_medicine-=1;
						golden_err_msg = Out_of_money;
						golden_player_info = 0;
					end
					else if(golden_player_info.bag_info.medicine_num==15)begin
						//$display("Bag is full (3)  ");
						buy_medicine-=1;
						golden_err_msg = Bag_is_full;
						golden_player_info = 0;
					end
					else begin
						golden_player_info.bag_info.medicine_num=golden_player_info.bag_info.medicine_num+1;
						golden_player_info.bag_info.money=golden_player_info.bag_info.money-128;
					end
				end
				Candy: begin 
					if(golden_player_info.bag_info.money<300)begin
						//$display("Out of money (1) ");
						buy_candy-=1;
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.candy_num==15)begin
						//$display("Bag is full (3)  ");
						buy_candy-=1;
						golden_err_msg = Bag_is_full;
						golden_player_info = 0;
					end
					else begin
						golden_player_info.bag_info.candy_num=golden_player_info.bag_info.candy_num+1;
						golden_player_info.bag_info.money=golden_player_info.bag_info.money-300;
					end
				end
				Bracer: begin 
					if(golden_player_info.bag_info.money<64)begin
						//$display("Out of money (1) ");
						buy_bracer-=1;
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.bracer_num==15)begin
						//$display("Bag is full (3)  ");
						buy_bracer-=1;
						golden_err_msg = Bag_is_full;
						golden_player_info = 0;
					end
					else begin
						golden_player_info.bag_info.bracer_num=golden_player_info.bag_info.bracer_num+1;
						golden_player_info.bag_info.money=golden_player_info.bag_info.money-64;
					end
				end
				Water_stone: begin
					if(golden_player_info.bag_info.money<800)begin
						//$display("Out of money (1) ");
						buy_ws-=1;
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.stone!=No_stone)begin
						//$display("Bag is full (3)  ");
						buy_ws-=1;
						golden_err_msg = Bag_is_full;
						golden_player_info = 0;
					end
					else begin
						golden_player_info.bag_info.stone = W_stone;
						golden_player_info.bag_info.money = golden_player_info.bag_info.money - 800;
					end
				end
				Fire_stone: begin
					if(golden_player_info.bag_info.money<800)begin
						//$display("Out of money (1) ");
						buy_fs-=1;
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.stone!=No_stone)begin
						//$display("Bag is full (3)  ");
						buy_fs-=1;
						golden_err_msg = Bag_is_full;
						golden_player_info = 0;
					end
					else begin
						golden_player_info.bag_info.stone = F_stone;
						golden_player_info.bag_info.money = golden_player_info.bag_info.money - 800;
					end
				end
				Thunder_stone: begin
					if(golden_player_info.bag_info.money<800)begin
						//$display("Out of money (1) ");
						buy_ts-=1;
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.stone!=No_stone)begin
						//$display("Bag is full (3)  ");
						buy_ts-=1;
						golden_err_msg = Bag_is_full;
						golden_player_info = 0;
					end
					else begin
						golden_player_info.bag_info.stone = T_stone;
						golden_player_info.bag_info.money = golden_player_info.bag_info.money - 800;
					end
				end
			endcase
		end
	end
	//$display("Golden  Player Info %h",golden_player_info);
end endtask

// todo also need to check dram to ensure next op will be right
task check_answer; begin
	while(!inf.out_valid) @(negedge clk);
	while(inf.out_valid) begin
		// normal check
		if(golden_act!=Attack)begin
			if(inf.out_info!==golden_player_info)begin
				/*
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d, using item",curr_pat_count,golden_act,golden_item);
				$display ("                                                  Correct Answer = %h, Your Answer = %h		 					                       ",golden_player_info,inf.out_info);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				*/
				$display("Wrong Answer");
				//#(100);
				$finish;
			end
			else if(inf.err_msg!==golden_err_msg)begin
				/*
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",curr_pat_count,golden_act);
				$display ("                                                  Correct ERR Answer = %h, Your ERR Answer = %h		 					                       ",golden_err_msg,inf.err_msg);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				*/
				$display("Wrong Answer");
				$finish;
			end
			else if((golden_err_msg!==No_Err && inf.complete==1)||(golden_err_msg==No_Err && inf.complete==0))begin
				/*
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",curr_pat_count,golden_act);
				$display ("                                                  Your Complete is Wrong		 					                       ");
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				*/
				$display("Wrong Answer");
				$finish;
			end
			else begin
				//$display("pass pattern No.%2d, current action %d",curr_pat_count,golden_act);
			end
		end
		else if(golden_act==Attack)begin
			if(inf.out_info!=={attacker_info.pkm_info,defender_info.pkm_info})begin
				/*
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",curr_pat_count,golden_act);
				$display ("                                                  Correct Answer = %h, Your Answer = %h		 					                       ",{attacker_info.pkm_info,defender_info.pkm_info},inf.out_info);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				*/
				$display("Wrong Answer");
				$finish;
			end
			else if(inf.err_msg!==golden_err_msg)begin
				/*
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",curr_pat_count,golden_act);
				$display ("                                                  Correct ERR Answer = %h, Your ERR Answer = %h		 					                       ",golden_err_msg,inf.err_msg);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				*/
				$display("Wrong Answer");
				$finish;
			end
			else if((golden_err_msg!==No_Err && inf.complete==1)||(golden_err_msg==No_Err && inf.complete==0))begin
				/*
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",curr_pat_count,golden_act);
				$display ("                                                  Your Complete is Wrong		 					                       ");
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				*/
				$display("Wrong Answer");
				$finish;
			end
			else begin
				//$display("pass pattern No.%2d, current action %d",curr_pat_count,golden_act);
			end
		end
		@(negedge clk);
	end
end endtask

task idle_signal; begin
	inf.id_valid = 1'b0 ;
	inf.act_valid = 1'b0 ;
	inf.item_valid = 1'b0 ;
	inf.type_valid = 1'b0 ;
	inf.amnt_valid = 1'b0 ;
	inf.rst_n = 1;
	inf.D = 'bx;
end endtask

task load_id; begin

	//a = r_gap.randomize();
	if(curr_id!=last_id || first_time==0)begin
		inf.id_valid = 1'b1;
		inf.D = curr_id;
		@(negedge clk);
		idle_signal;
		a = r_gap.randomize();
		repeat(1)@(negedge clk);
	end
	
end endtask

integer no_overflow;
integer now_gap;
task load_act; begin
	//
	tmp_player_info = {golden_DRAM[20'h10000+(curr_id*8)],golden_DRAM[20'h10000+(curr_id*8+1)],
						golden_DRAM[20'h10000+(curr_id*8+2)],golden_DRAM[20'h10000+(curr_id*8+3)],
						golden_DRAM[20'h10000+(curr_id*8+4)],golden_DRAM[20'h10000+(curr_id*8+5)],
						golden_DRAM[20'h10000+(curr_id*8+6)],golden_DRAM[20'h10000+(curr_id*8+7)]};
	//
	a = r_gap.randomize();
	inf.act_valid = 1'b1;
	inf.D = golden_act;
	@(negedge clk);
	idle_signal;
	curr_gap1 = r_gap.gap;
	if(golden_act==Check)begin
	
	end
	else begin
		now_gap = 0;
		repeat(1) begin
		@(negedge clk);
		end
		if(golden_act==Sell)begin
			if(golden_id<=127) begin 
				golden_pi = 0;
			end
			else begin 
				golden_pi = 1;
			end
			
			if(golden_pi)begin //pkm
				inf.type_valid = 1'b1;
				inf.D = 0;
			end
			else if(golden_pi==0)begin // item
				if(use_stone_test==1)begin
					inf.item_valid = 1'b1;
					if(patcount==0)begin
						golden_item = Water_stone;
					end
					else if(patcount==2)begin
						golden_item = Water_stone;
					end
					else if(patcount==4)begin
						golden_item = Fire_stone;
					end
					inf.D = golden_item;
					// check sell item
					case(golden_item)
						Berry: sell_berry+=1;
						Medicine:sell_medicine+=1;
						Candy:sell_candy+=1;
						Bracer:sell_bracer+=1;
						Water_stone:sell_ws+=1;
						Fire_stone:sell_fs+=1;
						Thunder_stone:sell_ts+=1;
					endcase
				end
				else begin
					inf.item_valid = 1'b1;
					a = r_item.randomize();
					golden_item = r_item.item;
					inf.D = golden_item;
					// check sell item
					case(golden_item)
						Berry: sell_berry+=1;
						Medicine:sell_medicine+=1;
						Candy:sell_candy+=1;
						Bracer:sell_bracer+=1;
						Water_stone:sell_ws+=1;
						Fire_stone:sell_fs+=1;
						Thunder_stone:sell_ts+=1;
					endcase
				end
				
				
			end
			
			
			
		end
		else if(golden_act==Buy)begin
			if(golden_id<=127)begin 
				golden_pi = 0;
			end
			else begin 
				golden_pi = 1;
			end
			if(golden_pi==1)begin //pkm
				inf.type_valid = 1'b1;
				golden_pkm_type = Normal;
				inf.D = golden_pkm_type;
			end
			else if(golden_pi==0)begin // item
				if(use_stone_test==1)begin
					if(patcount==1)begin
						golden_item = Water_stone;
					end
					else if(patcount==3)begin
						golden_item = Fire_stone;
					end
					else if(patcount==5)begin
						golden_item = Thunder_stone;
					end
					inf.item_valid = 1'b1;
					inf.D = golden_item;
					// check buy item
					case(golden_item)
						Berry: buy_berry+=1;
						Medicine:buy_medicine+=1;
						Candy:buy_candy+=1;
						Bracer:buy_bracer+=1;
						Water_stone:buy_ws+=1;
						Fire_stone:buy_fs+=1;
						Thunder_stone:buy_ts+=1;
					endcase
				end
				else if(buy_candy_test==1)begin
					inf.item_valid = 1'b1;
					golden_item = Candy;
					inf.D = golden_item;
					// check buy item
					case(golden_item)
						Berry: buy_berry+=1;
						Medicine:buy_medicine+=1;
						Candy:buy_candy+=1;
						Bracer:buy_bracer+=1;
						Water_stone:buy_ws+=1;
						Fire_stone:buy_fs+=1;
						Thunder_stone:buy_ts+=1;
					endcase
				end
				else begin
					inf.item_valid = 1'b1;
					a = r_item.randomize();
					golden_item = r_item.item;
					inf.D = golden_item;
					// check buy item
					case(golden_item)
						Berry: buy_berry+=1;
						Medicine:buy_medicine+=1;
						Candy:buy_candy+=1;
						Bracer:buy_bracer+=1;
						Water_stone:buy_ws+=1;
						Fire_stone:buy_fs+=1;
						Thunder_stone:buy_ts+=1;
					endcase
				end
			end
		end
		else if(golden_act==Deposit)begin
			if(start_give_money==0)begin
				golden_deposit_money = 1;
			end
			else begin
				golden_deposit_money = 2000;
			end
			inf.amnt_valid = 1;
			
			inf.D = golden_deposit_money;
		end
		else if(golden_act==Use_item)begin
			if(bracer_test==1)begin
				inf.item_valid = 1'b1;
				golden_item = Bracer;
				inf.D = golden_item;
			end
			else if(evv_evo_test==1)begin
				inf.item_valid = 1'b1;
				golden_item = Bracer;
				if(patcount==2 || patcount==3)begin
					golden_item = Candy;
				end
				else if(patcount==4)begin
					golden_item = Water_stone;
				end
				inf.D = golden_item;
			end
			else begin
				inf.item_valid = 1'b1;
				a = r_item.randomize();
				golden_item = r_item.item;
				inf.D = golden_item;
				
				// check use item
				case(golden_item)
					Berry: use_berry+=1;
					Medicine:use_medicine+=1;
					Candy:use_candy+=1;
					Bracer:use_bracer+=1;
					Water_stone:use_ws+=1;
					Fire_stone:use_fs+=1;
					Thunder_stone:use_ts+=1;
				endcase
			end
		end
		else if(golden_act==Attack)begin
			attack_id = curr_id;
			
			if(err_HP_is_Zero<20)begin
				defend_id = 0;
				if(defend_id==attack_id)begin
					defend_id = 1;
				end
			end
			else begin
				a = r_id.randomize();
				while(r_id.id==attack_id)begin
					a = r_id.randomize();
				end
			end
			defend_id = r_id.id;
			if(bracer_test==1)begin
				defend_id = 11;
			end
			
			
			inf.D = defend_id;
			inf.id_valid = 1'b1;
		end
		@(negedge clk);
		idle_signal;
	end
end endtask

task write_back_dram;begin
	if(golden_err_msg == No_Err)begin
		if(golden_act!=Attack)begin
			golden_DRAM[20'h10000+(curr_id*8)] = golden_player_info[63:56];
			golden_DRAM[20'h10000+(curr_id*8+1)] = golden_player_info[55:48];
			golden_DRAM[20'h10000+(curr_id*8+2)] = golden_player_info[47:40];
			golden_DRAM[20'h10000+(curr_id*8+3)] = golden_player_info[39:32];
			golden_DRAM[20'h10000+(curr_id*8+4)] = golden_player_info[31:24];
			golden_DRAM[20'h10000+(curr_id*8+5)] = golden_player_info[23:16];
			golden_DRAM[20'h10000+(curr_id*8+6)] = golden_player_info[15:8];
			golden_DRAM[20'h10000+(curr_id*8+7)] = golden_player_info[7:0];
		end
		else begin
			// attacker
			golden_DRAM[20'h10000+(attack_id*8)] = attacker_info[63:56];
			golden_DRAM[20'h10000+(attack_id*8+1)] = attacker_info[55:48];
			golden_DRAM[20'h10000+(attack_id*8+2)] = attacker_info[47:40];
			golden_DRAM[20'h10000+(attack_id*8+3)] = attacker_info[39:32];
			golden_DRAM[20'h10000+(attack_id*8+4)] = attacker_info[31:24];
			golden_DRAM[20'h10000+(attack_id*8+5)] = attacker_info[23:16];
			golden_DRAM[20'h10000+(attack_id*8+6)] = attacker_info[15:8];
			golden_DRAM[20'h10000+(attack_id*8+7)] = attacker_info[7:0];
			// defender
			golden_DRAM[20'h10000+(defend_id*8)] = defender_info[63:56];
			golden_DRAM[20'h10000+(defend_id*8+1)] = defender_info[55:48];
			golden_DRAM[20'h10000+(defend_id*8+2)] = defender_info[47:40];
			golden_DRAM[20'h10000+(defend_id*8+3)] = defender_info[39:32];
			golden_DRAM[20'h10000+(defend_id*8+4)] = defender_info[31:24];
			golden_DRAM[20'h10000+(defend_id*8+5)] = defender_info[23:16];
			golden_DRAM[20'h10000+(defend_id*8+6)] = defender_info[15:8];
			golden_DRAM[20'h10000+(defend_id*8+7)] = defender_info[7:0];
		end
	end
	else begin
	
	end
end endtask




task reset_task ; begin
	#(2.0);	inf.rst_n = 0 ;
	#(3.0);
	if (inf.out_valid!==0 || inf.err_msg!==0 || inf.complete!==0 || inf.out_info!==0) begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                   All output signals should be reset after the reset signal is asserted.                                   ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
	end
	#(2.0);	inf.rst_n = 1 ;
end endtask





endprogram

