`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"
`define End_CYCLE  5000
program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
integer i, cycles, total_cycles,y;
integer patcount;
integer a;
int test_id,test_id2;
parameter PATNUM = 5000;
parameter SEED = 999;
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
logic golden_complete;

logic [7:0] last_id,curr_id,attack_id,defend_id;
logic [7:0] golden_DRAM[('h10000):('h107ff)];
logic [14:0] tmp_add_money;
integer first_time;
reg [14:0] cycle_counter;
//================================================================
//  class
//================================================================
class rand_id;
	rand int id;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit {id inside {[0:255]};}
endclass

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

class rand_change_id;	
	rand int change_id;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { change_id inside {[1:10]}; }
endclass

class rand_action;
	rand Action action;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { action inside {Buy, Sell, Deposit, Use_item,Check,Attack}; }
endclass

class rand_PI;
	rand int pi;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { pi inside {[0:1]};}
endclass

class rand_pkm_type;
	rand PKM_Type pkm_type;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { pkm_type inside {Grass, Fire, Water, Electric,Normal}; }
endclass

class rand_item;
	rand Item item;
	function new (int seed);
		this.srandom(seed);		
	endfunction 
	constraint limit { item inside {Berry, Medicine, Candy, Bracer,Water_stone,Fire_stone,Thunder_stone}; }
endclass

class rand_money;
	rand int money;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { money inside {[0:16383]};}
endclass

//================================================================
//  cycle count
//================================================================



//================================================================
//  initial
//================================================================
int test_rand;
rand_id 		r_id 		= new(SEED);
rand_gap 		r_gap 		= new(SEED);
rand_gap2 		r_gap2 		= new(SEED);
rand_action 	r_action 	= new(SEED);
rand_PI 		r_pi 		= new(SEED);
rand_pkm_type 	r_pkm_type 	= new(SEED);
rand_item 		r_item 		= new(SEED);
rand_money 		r_money		= new(SEED);
rand_change_id 	r_change_id = new(SEED);
initial begin
	// read initial DRAM data
	$readmemh(DRAM_p_r, golden_DRAM);
	//$display("%h",golden_DRAM['h10000]);
	a = r_id.randomize();
	last_id = r_id.id;
	// reset signal
	idle_signal;
	first_time = 0;
	//reset
	//total_cycles = 0;
	reset_task;
	repeat(4)@(negedge clk);
	for(patcount = 0; patcount<PATNUM;patcount+=1)begin
		load_id;
		load_act;
		/*
		if(curr_id==233)begin
		$display("=============================HERE!!!!!!!!!!!!!!!!!!!!!!!!!====================================== %2d",patcount);
		$display("%2h%2h%2h%2h%2h%2h%2h%2h",golden_DRAM[20'h10000+(curr_id*8)],golden_DRAM[20'h10000+(curr_id*8+1)],
						golden_DRAM[20'h10000+(curr_id*8+2)],golden_DRAM[20'h10000+(curr_id*8+3)],
						golden_DRAM[20'h10000+(curr_id*8+4)],golden_DRAM[20'h10000+(curr_id*8+5)],
						golden_DRAM[20'h10000+(curr_id*8+6)],golden_DRAM[20'h10000+(curr_id*8+7)]);
		$display("=============================HERE!!!!!!!!!!!!!!!!!!!!!!!!!======================================");
		end
		if(defend_id==233) begin
		$display("=============================HERE!!!!!!!!!!!!!!!!!!!!!!!!!====================================== %2d",patcount);
		$display("%2h%2h%2h%2h%2h%2h%2h%2h",golden_DRAM[20'h10000+(defend_id*8)],golden_DRAM[20'h10000+(defend_id*8+1)],
						golden_DRAM[20'h10000+(defend_id*8+2)],golden_DRAM[20'h10000+(defend_id*8+3)],
						golden_DRAM[20'h10000+(defend_id*8+4)],golden_DRAM[20'h10000+(defend_id*8+5)],
						golden_DRAM[20'h10000+(defend_id*8+6)],golden_DRAM[20'h10000+(defend_id*8+7)]);
		$display("=============================HERE!!!!!!!!!!!!!!!!!!!!!!!!!======================================");
		end
		*/
		compute_golden;
		write_back_dram;
		check_answer;
		last_id = curr_id;
		defend_id = 0;
		first_time = 1;
		a = r_gap2.randomize();
		//$display("%d",r_gap2.gap2);
		repeat(r_gap2.gap2) @(negedge clk);
	end
	//repeat(10) @(negedge clk);
	pass_task;
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
		if(r_pi.pi==0)begin
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
			if(r_item.item==Berry && golden_player_info.bag_info.berry_num==0)begin
				//$display("Do not have item (2) ");
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(r_item.item==Medicine && golden_player_info.bag_info.medicine_num==0)begin
				//$display("Do not have item (2) ");
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(r_item.item==Candy && golden_player_info.bag_info.candy_num==0)begin
				//$display("Do not have item (2) ");
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(r_item.item==Bracer && golden_player_info.bag_info.bracer_num==0)begin
				//$display("Do not have item (2) ");
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(r_item.item==Water_stone && golden_player_info.bag_info.stone!=W_stone)begin
				//$display("Do not have item (2) ");
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(r_item.item==Fire_stone && golden_player_info.bag_info.stone!=F_stone)begin
				//$display("Do not have item (2) ");
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else if(r_item.item==Thunder_stone && golden_player_info.bag_info.stone!=T_stone)begin
				//$display("Do not have item (2) ");
				golden_err_msg =Not_Having_Item;
				golden_player_info = 0;
			end
			else 
				case(r_item.item)
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
		if(16383-golden_player_info.bag_info.money<=r_money.money)
			golden_player_info.bag_info.money = 16383;
		else
			golden_player_info.bag_info.money = golden_player_info.bag_info.money + r_money.money;
	end
	else if(golden_act==Use_item)begin
		if(golden_player_info.pkm_info==0)begin
			//$display("Do not have a Pokemon (1)");
			golden_err_msg = Not_Having_PKM;
			golden_player_info = 0;
		end
		else if(r_item.item==Berry && golden_player_info.bag_info.berry_num==0)begin
			//$display("Do not have item (2)");
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
		end
		else if(r_item.item==Medicine && golden_player_info.bag_info.medicine_num==0)begin
			//$display("Do not have item (2)");
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
		end
		else if(r_item.item==Candy && golden_player_info.bag_info.candy_num==0)begin
			//$display("Do not have item (2)");
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
		end
		else if(r_item.item==Bracer && golden_player_info.bag_info.bracer_num==0)begin
			//$display("Do not have item (2)");
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
		end
		else if((r_item.item==Water_stone && golden_player_info.bag_info.stone!=W_stone) ||
				(r_item.item==Thunder_stone && golden_player_info.bag_info.stone!=T_stone) ||
				(r_item.item==Fire_stone && golden_player_info.bag_info.stone!=F_stone))begin
			//$display("Do not have item (2)");
			golden_err_msg = Not_Having_Item;
			golden_player_info = 0;
			end
		else
			case(r_item.item)
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
		if(r_pi.pi==0)begin
			if(r_pkm_type.pkm_type == Grass && golden_player_info.bag_info.money<100)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(r_pkm_type.pkm_type == Fire && golden_player_info.bag_info.money<90)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(r_pkm_type.pkm_type == Water && golden_player_info.bag_info.money<110)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(r_pkm_type.pkm_type == Electric && golden_player_info.bag_info.money<120)begin
				//$display("Out of money (1) ");
				golden_player_info = 0;
				golden_err_msg = Out_of_money;
			end
			else if(r_pkm_type.pkm_type == Normal && golden_player_info.bag_info.money<130)begin
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
				case(r_pkm_type.pkm_type)
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
			case(r_item.item)
				Berry: begin 
					if(golden_player_info.bag_info.money<16)begin
						//$display("Out of money (1) ");
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.berry_num==15)begin
						//$display("Bag is full (3)  ");
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
						golden_err_msg = Out_of_money;
						golden_player_info = 0;
					end
					else if(golden_player_info.bag_info.medicine_num==15)begin
						//$display("Bag is full (3)  ");
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
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.candy_num==15)begin
						//$display("Bag is full (3)  ");
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
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.bracer_num==15)begin
						//$display("Bag is full (3)  ");
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
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.stone!=No_stone)begin
						//$display("Bag is full (3)  ");
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
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.stone!=No_stone)begin
						//$display("Bag is full (3)  ");
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
						golden_player_info = 0;
						golden_err_msg = Out_of_money;
					end
					else if(golden_player_info.bag_info.stone!=No_stone)begin
						//$display("Bag is full (3)  ");
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
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d, using item",patcount,golden_act,r_item.item);
				$display ("                                                  Correct Answer = %h, Your Answer = %h		 					                       ",golden_player_info,inf.out_info);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				$finish;
			end
			else if(inf.err_msg!==golden_err_msg)begin
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",patcount,golden_act);
				$display ("                                                  Correct ERR Answer = %h, Your ERR Answer = %h		 					                       ",golden_err_msg,inf.err_msg);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				$finish;
			end
			else if((golden_err_msg!==No_Err && inf.complete==1)||(golden_err_msg==No_Err && inf.complete==0))begin
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",patcount,golden_act);
				$display ("                                                  Your Complete is Wrong		 					                       ");
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				$finish;
			end
			else begin
				$display("pass pattern No.%2d, current action %d",patcount,golden_act);
			end
		end
		else if(golden_act==Attack)begin
			if(inf.out_info!=={attacker_info.pkm_info,defender_info.pkm_info})begin
				//$display("%d",attacker_info.pkm_info.atk);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",patcount,golden_act);
				$display ("                                                  Correct Answer = %h, Your Answer = %h		 					                       ",{attacker_info.pkm_info,defender_info.pkm_info},inf.out_info);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				$finish;
			end
			else if(inf.err_msg!==golden_err_msg)begin
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",patcount,golden_act);
				$display ("                                                  Correct ERR Answer = %h, Your ERR Answer = %h		 					                       ",golden_err_msg,inf.err_msg);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				$finish;
			end
			else if((golden_err_msg!==No_Err && inf.complete==1)||(golden_err_msg==No_Err && inf.complete==0))begin
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display("                                                   fail pattern No.%2d, current action %d",patcount,golden_act);
				$display ("                                                  Your Complete is Wrong		 					                       ");
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				//#(100);
				$finish;
			end
			else begin
				$display("pass pattern No.%2d, current action %d",patcount,golden_act);
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
	a = r_change_id.randomize();
	
	a = r_id.randomize();
	if(r_change_id.change_id<=1 || first_time==0)begin
		curr_id = r_id.id;
		//curr_id = 0;
	end
	
	a = r_gap.randomize();
	if(last_id!=curr_id)begin
		inf.id_valid = 1'b1;
		inf.D = curr_id;
		@(negedge clk);
		idle_signal;
		a = r_gap.randomize();
		repeat(r_gap.gap)@(negedge clk);
	end
	
end endtask

integer no_overflow;

task load_act; begin
	//
	tmp_player_info = {golden_DRAM[20'h10000+(curr_id*8)],golden_DRAM[20'h10000+(curr_id*8+1)],
						golden_DRAM[20'h10000+(curr_id*8+2)],golden_DRAM[20'h10000+(curr_id*8+3)],
						golden_DRAM[20'h10000+(curr_id*8+4)],golden_DRAM[20'h10000+(curr_id*8+5)],
						golden_DRAM[20'h10000+(curr_id*8+6)],golden_DRAM[20'h10000+(curr_id*8+7)]};
	//
	a = r_action.randomize();
	while(16383-tmp_player_info.bag_info.money<12 && r_action.action==Sell)begin
		a = r_action.randomize();
	end
	a = r_gap.randomize();
	inf.act_valid = 1'b1;
	inf.D = r_action.action;
	golden_act = r_action.action;
	@(negedge clk);
	idle_signal;
	
	if(golden_act==Check)begin
	
	end
	else begin
		repeat(r_gap.gap) @(negedge clk);
		if(golden_act==Sell)begin
			no_overflow = 0;
			while(no_overflow==0)begin
				a =r_pi.randomize();
				if(r_pi.pi==0)begin //pkm
					case(tmp_player_info.pkm_info.pkm_type)
						Grass:begin
							if(tmp_player_info.pkm_info.stage==Lowest)
								no_overflow = 1;
							else if(tmp_player_info.pkm_info.stage==Middle)
								if(16383-tmp_player_info.bag_info.money>=510)
									no_overflow = 1;
							else
								if(16383-tmp_player_info.bag_info.money>=1100)
									no_overflow = 1;
						end
						Fire:begin
							if(tmp_player_info.pkm_info.stage==Lowest)
								no_overflow = 1;
							else if(tmp_player_info.pkm_info.stage==Middle)
								if(16383-tmp_player_info.bag_info.money>=450)
									no_overflow = 1;
							else
								if(16383-tmp_player_info.bag_info.money>=1000)
									no_overflow = 1;
						end
						Water:begin
							if(tmp_player_info.pkm_info.stage==Lowest)
								no_overflow = 1;
							else if(tmp_player_info.pkm_info.stage==Middle)
								if(16383-tmp_player_info.bag_info.money>=500)
									no_overflow = 1;
							else
								if(16383-tmp_player_info.bag_info.money>=1200)
									no_overflow = 1;
						end
						Electric:begin
							if(tmp_player_info.pkm_info.stage==Lowest)
								no_overflow = 1;
							else if(tmp_player_info.pkm_info.stage==Middle)
								if(16383-tmp_player_info.bag_info.money>=550)
									no_overflow = 1;
							else
								if(16383-tmp_player_info.bag_info.money>=1300)
									no_overflow = 1;
						end
						Normal:begin
							no_overflow = 1;
						end
						No_type: no_overflow = 1;
					endcase
				end
				else if(r_pi.pi==1)begin // item
					a = r_item.randomize();
					if(r_item.item==Berry && (16383-tmp_player_info.bag_info.money>=12))
						no_overflow = 1;
					else if(r_item.item==Medicine && (16383-tmp_player_info.bag_info.money>=96))
						no_overflow = 1;
					else if(r_item.item==Candy && (16383-tmp_player_info.bag_info.money>=225))
						no_overflow = 1;
					else if(r_item.item==Bracer && (16383-tmp_player_info.bag_info.money>=48))
						no_overflow = 1;
					else if(r_item.item==Water_stone && (16383-tmp_player_info.bag_info.money>=600))
						no_overflow = 1;
					else if(r_item.item==Fire_stone && (16383-tmp_player_info.bag_info.money>=600))
						no_overflow = 1;
					else if(r_item.item==Thunder_stone && (16383-tmp_player_info.bag_info.money>=600))
						no_overflow = 1;

				end
			end
			//a =r_pi.randomize();
			if(r_pi.pi==0)begin //pkm
				inf.type_valid = 1'b1;
				inf.D = 0;
			end
			else if(r_pi.pi==1)begin // item
				inf.item_valid = 1'b1;
				inf.D = r_item.item;
			end
		end
		else if(golden_act==Buy)begin
			a = r_pi.randomize();
			if(r_pi.pi==0)begin //pkm
				a = r_pkm_type.randomize();
				inf.type_valid = 1'b1;
				inf.D = r_pkm_type.pkm_type;
			end
			else if(r_pi.pi==1)begin // item
				a = r_item.randomize();
				inf.item_valid = 1'b1;
				inf.D = r_item.item;
			end
		end
		else if(golden_act==Deposit)begin
			a = r_money.randomize();
			while(16383-tmp_player_info.bag_info.money<r_money.money)begin
				a = r_money.randomize();
			end
			inf.amnt_valid = 1;
			inf.D = r_money.money;
		end
		else if(golden_act==Use_item)begin
			a = r_item.randomize();
			inf.item_valid = 1'b1;
			inf.D = r_item.item;
		end

		else if(golden_act==Attack)begin
			//attack_id = r_id.id;
			attack_id = curr_id;
			a = r_id.randomize();
			
			while(r_id.id==attack_id)begin
				a = r_id.randomize();
			end
			defend_id = r_id.id;
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
        $display ("                                                                SPEC 3 FAIL!                                                                ");
        $display ("                                   All output signals should be reset after the reset signal is asserted.                                   ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
	end
	#(2.0);	inf.rst_n = 1 ;
end endtask

task pass_task;
/*
    $display("                                                             \033[33m`-                                                                            ");        
    $display("                                                             /NN.                                                                           ");        
    $display("                                                            sMMM+                                                                           ");        
    $display(" .``                                                       sMMMMy                                                                           ");        
    $display(" oNNmhs+:-`                                               oMMMMMh                                                                           ");        
    $display("  /mMMMMMNNd/:-`                                         :+smMMMh                                                                           ");        
    $display("   .sNMMMMMN::://:-`                                    .o--:sNMy                                                                           ");        
    $display("     -yNMMMM:----::/:-.                                 o:----/mo                                                                           ");        
    $display("       -yNMMo--------://:.                             -+------+/                                                                           ");        
    $display("         .omd/::--------://:`                          o-------o.                                                                           ");        
    $display("           `/+o+//::-------:+:`                       .+-------y                                                                            ");        
    $display("              .:+++//::------:+/.---------.`          +:------/+                                                                            ");        
    $display("                 `-/+++/::----:/:::::::::::://:-.     o------:s.          \033[37m:::::----.           -::::.          `-:////:-`     `.:////:-.    \033[33m");        
    $display("                    `.:///+/------------------:::/:- `o-----:/o          \033[37m.NNNNNNNNNNds-       -NNNNNd`       -smNMMMMMMNy   .smNNMMMMMNh    \033[33m");        
    $display("                         :+:----------------------::/:s-----/s.          \033[37m.MMMMo++sdMMMN-     `mMMmMMMs      -NMMMh+///oys  `mMMMdo///oyy    \033[33m");        
    $display("                        :/---------------------------:++:--/++           \033[37m.MMMM.   `mMMMy     yMMM:dMMM/     +MMMM:      `  :MMMM+`     `    \033[33m");        
    $display("                       :/---///:-----------------------::-/+o`           \033[37m.MMMM.   -NMMMo    +MMMs -NMMm.    .mMMMNdo:.     `dMMMNds/-`      \033[33m");        
    $display("                      -+--/dNs-o/------------------------:+o`            \033[37m.MMMMyyyhNMMNy`   -NMMm`  sMMMh     .odNMMMMNd+`   `+dNMMMMNdo.    \033[33m");        
    $display("                     .o---yMMdsdo------------------------:s`             \033[37m.MMMMNmmmdho-    `dMMMdooosMMMM+      `./sdNMMMd.    `.:ohNMMMm-   \033[33m");        
    $display("                    -yo:--/hmmds:----------------//:------o              \033[37m.MMMM:...`       sMMMMMMMMMMMMMN-  ``     `:MMMM+ ``      -NMMMs   \033[33m");        
    $display("                   /yssy----:::-------o+-------/h/-hy:---:+              \033[37m.MMMM.          /MMMN:------hMMMd` +dy+:::/yMMMN- :my+:::/sMMMM/   \033[33m");        
    $display("                  :ysssh:------//////++/-------sMdyNMo---o.              \033[37m.MMMM.         .mMMMs       .NMMMs /NMMMMMMMMmh:  -NMMMMMMMMNh/    \033[33m");        
    $display("                  ossssh:-------ddddmmmds/:----:hmNNh:---o               \033[37m`::::`         .::::`        -:::: `-:/++++/-.     .:/++++/-.      \033[33m");        
    $display("                  /yssyo--------dhhyyhhdmmhy+:---://----+-                                                                                  ");        
    $display("                  `yss+---------hoo++oosydms----------::s    `.....-.                                                                       ");        
    $display("                   :+-----------y+++++++oho--------:+sssy.://:::://+o.                                                                      ");        
    $display("                    //----------y++++++os/--------+yssssy/:--------:/s-                                                                     ");        
    $display("             `..:::::s+//:::----+s+++ooo:--------+yssssy:-----------++                                                                      ");        
    $display("           `://::------::///+/:--+soo+:----------ssssys/---------:o+s.``                                                                    ");        
    $display("          .+:----------------/++/:---------------:sys+----------:o/////////::::-...`                                                        ");        
    $display("          o---------------------oo::----------::/+//---------::o+--------------:/ohdhyo/-.``                                                ");        
    $display("          o---------------------/s+////:----:://:---------::/+h/------------------:oNMMMMNmhs+:.`                                           ");        
    $display("          -+:::::--------------:s+-:::-----------------:://++:s--::------------::://sMMMMMMMMMMNds/`                                        ");        
    $display("           .+++/////////////+++s/:------------------:://+++- :+--////::------/ydmNNMMMMMMMMMMMMMMmo`                                        ");        
    $display("             ./+oo+++oooo++/:---------------------:///++/-   o--:///////::----sNMMMMMMMMMMMMMMMmo.                                          ");        
    $display("                o::::::--------------------------:/+++:`    .o--////////////:--+mMMMMMMMMMMMMmo`                                            ");        
    $display("               :+--------------------------------/so.       +:-:////+++++///++//+mMMMMMMMMMmo`                                              ");        
    $display("              .s----------------------------------+: ````` `s--////o:.-:/+syddmNMMMMMMMMMmo`                                                ");        
    $display("              o:----------------------------------s. :s+/////--//+o-       `-:+shmNNMMMNs.                                                  ");        
    $display("             //-----------------------------------s` .s///:---:/+o.               `-/+o.                                                    ");        
    $display("            .o------------------------------------o.  y///+//:/+o`                                                                          ");        
    $display("            o-------------------------------------:/  o+//s//+++`                                                                           ");        
    $display("           //--------------------------------------s+/o+//s`                                                                                ");        
    $display("          -+---------------------------------------:y++///s                                                                                 ");        
    $display("          o-----------------------------------------oo/+++o                                                                                 ");        
    $display("         `s-----------------------------------------:s   ``                                                                                 ");        
    $display("          o-:::::------------------:::::-------------o.                                                                                     ");        
    $display("          .+//////////::::::://///////////////:::----o`                                                                                     ");        
    $display("          `:soo+///////////+++oooooo+/////////////:-//                                                                                      ");        
    $display("       -/os/--:++/+ooo:::---..:://+ooooo++///////++so-`                                                                                     ");        
    $display("      syyooo+o++//::-                 ``-::/yoooo+/:::+s/.                                                                                  ");        
    $display("       `..``                                `-::::///:++sys:                                                                                ");        
    $display("                                                    `.:::/o+  \033[37m                                                                              ");	
	*/
    $display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("********************************************************************");
    $finish;
endtask

task fail_task; 
/*
    $display("\033[33m	                                                         .:                                                                                         ");      
    $display("                                                   .:                                                                                                 ");
    $display("                                                  --`                                                                                                 ");
    $display("                                                `--`                                                                                                  ");
    $display("                 `-.                            -..        .-//-                                                                                      ");
    $display("                  `.:.`                        -.-     `:+yhddddo.                                                                                    ");
    $display("                    `-:-`             `       .-.`   -ohdddddddddh:                                                                                   ");
    $display("                      `---`       `.://:-.    :`- `:ydddddhhsshdddh-                       \033[31m.yhhhhhhhhhs       /yyyyy`       .yhhy`   +yhyo           \033[33m");
    $display("                        `--.     ./////:-::` `-.--yddddhs+//::/hdddy`                      \033[31m-MMMMNNNNNNh      -NMMMMMs       .MMMM.   sMMMh           \033[33m");
    $display("                          .-..   ////:-..-// :.:oddddho:----:::+dddd+                      \033[31m-MMMM-......     `dMMmhMMM/      .MMMM.   sMMMh           \033[33m");
    $display("                           `-.-` ///::::/::/:/`odddho:-------:::sdddh`                     \033[31m-MMMM.           sMMM/.NMMN.     .MMMM.   sMMMh           \033[33m");
    $display("             `:/+++//:--.``  .--..+----::://o:`osss/-.--------::/dddd/             ..`     \033[31m-MMMMysssss.    /MMMh  oMMMh     .MMMM.   sMMMh           \033[33m");
    $display("             oddddddddddhhhyo///.-/:-::--//+o-`:``````...------::dddds          `.-.`      \033[31m-MMMMMMMMMM-   .NMMN-``.mMMM+    .MMMM.   sMMMh           \033[33m");
    $display("            .ddddhhhhhddddddddddo.//::--:///+/`.````````..``...-:ddddh       `.-.`         \033[31m-MMMM:.....`  `hMMMMmmmmNMMMN-   .MMMM.   sMMMh           \033[33m");
    $display("            /dddd//::///+syhhdy+:-`-/--/////+o```````.-.......``./yddd`   `.--.`           \033[31m-MMMM.        oMMMmhhhhhhdMMMd`  .MMMM.   sMMMh```````    \033[33m");
    $display("            /dddd:/------:://-.`````-/+////+o:`````..``     `.-.``./ym.`..--`              \033[31m-MMMM.       :NMMM:      .NMMMs  .MMMM.   sMMMNmmmmmms    \033[33m");
    $display("            :dddd//--------.`````````.:/+++/.`````.` `.-      `-:.``.o:---`                \033[31m.dddd`       yddds        /dddh. .dddd`   +ddddddddddo    \033[33m");
    $display("            .ddddo/-----..`........`````..```````..  .-o`       `:.`.--/-      ``````````` \033[31m ````        ````          ````   ````     ``````````     \033[33m");
    $display("             ydddh/:---..--.````.`.-.````````````-   `yd:        `:.`...:` `................`                                                         ");
    $display("             :dddds:--..:.     `.:  .-``````````.:    +ys         :-````.:...```````````````..`                                                       ");
    $display("              sdddds:.`/`      ``s.  `-`````````-/.   .sy`      .:.``````-`````..-.-:-.````..`-                                                       ");
    $display("              `ydddd-`.:       `sh+   /:``````````..`` +y`   `.--````````-..---..``.+::-.-``--:                                                       ");
    $display("               .yddh``-.        oys`  /.``````````````.-:.`.-..`..```````/--.`      /:::-:..--`                                                       ");
    $display("                .sdo``:`        .sy. .:``````````````````````````.:```...+.``       -::::-`.`                                                         ");
    $display(" ````.........```.++``-:`        :y:.-``````````````....``.......-.```..::::----.```  ``                                                              ");
    $display("`...````..`....----:.``...````  ``::.``````.-:/+oosssyyy:`.yyh-..`````.:` ````...-----..`                                                             ");
    $display("                 `.+.``````........````.:+syhdddddddddddhoyddh.``````--              `..--.`                                                          ");
    $display("            ``.....--```````.```````.../ddddddhhyyyyyyyhhhddds````.--`             ````   ``                                                          ");
    $display("         `.-..``````-.`````.-.`.../ss/.oddhhyssssooooooossyyd:``.-:.         `-//::/++/:::.`                                                          ");
    $display("       `..```````...-::`````.-....+hddhhhyssoo+++//////++osss.-:-.           /++++o++//s+++/                                                          ");
    $display("     `-.```````-:-....-/-``````````:hddhsso++/////////////+oo+:`             +++::/o:::s+::o            \033[31m     `-/++++:-`                              \033[33m");
    $display("    `:````````./`  `.----:..````````.oysso+///////////////++:::.             :++//+++/+++/+-            \033[31m   :ymMMMMMMMMms-                            \033[33m");
    $display("    :.`-`..```./.`----.`  .----..`````-oo+////////////////o:-.`-.            `+++++++++++/.             \033[31m `yMMMNho++odMMMNo                           \033[33m");
    $display("    ..`:..-.`.-:-::.`        `..-:::::--/+++////////////++:-.```-`            +++++++++o:               \033[31m hMMMm-      /MMMMo  .ssss`/yh+.syyyyyyyyss. \033[33m");
    $display("     `.-::-:..-:-.`                 ```.+::/++//++++++++:..``````:`          -++++++++oo                \033[31m:MMMM:        yMMMN  -MMMMdMNNs-mNNNNNMMMMd` \033[33m");
    $display("        `   `--`                        /``...-::///::-.`````````.: `......` ++++++++oy-                \033[31m+MMMM`        +MMMN` -MMMMh:--. ````:mMMNs`  \033[33m");
    $display("           --`                          /`````````````````````````/-.``````.::-::::::/+                 \033[31m:MMMM:        yMMMm  -MMMM`       `oNMMd:    \033[33m");
    $display("          .`                            :```````````````````````--.`````````..````.``/-                 \033[31m dMMMm:`    `+MMMN/  -MMMN       :dMMNs`     \033[33m");
    $display("                                        :``````````````````````-.``.....````.```-::-.+                  \033[31m `yNMMMdsooymMMMm/   -MMMN     `sMMMMy/////` \033[33m");
    $display("                                        :.````````````````````````-:::-::.`````-:::::+::-.`             \033[31m   -smNMMMMMNNd+`    -NNNN     hNNNNNNNNNNN- \033[33m");
    $display("                                `......../```````````````````````-:/:   `--.```.://.o++++++/.           \033[31m      .:///:-`       `----     ------------` \033[33m");
    $display("                              `:.``````````````````````````````.-:-`      `/````..`+sssso++++:                                                        ");
    $display("                              :`````.---...`````````````````.--:-`         :-````./ysoooss++++.                                                       ");
    $display("                              -.````-:/.`.--:--....````...--:/-`            /-..-+oo+++++o++++.                                                       ");
    $display("             `:++/:.`          -.```.::      `.--:::::://:::::.              -:/o++++++++s++++                                                        ");
    $display("           `-+++++++++////:::/-.:.```.:-.`              :::::-.-`               -+++++++o++++.                                                        ");
    $display("           /++osoooo+++++++++:`````````.-::.             .::::.`-.`              `/oooo+++++.                                                         ");
    $display("           ++oysssosyssssooo/.........---:::               -:::.``.....`     `.:/+++++++++:                                                           ");
    $display("           -+syoooyssssssyo/::/+++++/+::::-`                 -::.``````....../++++++++++:`                                                            ");
    $display("             .:///-....---.-..-.----..`                        `.--.``````````++++++/:.                                                               ");
    $display("                                                                   `........-:+/:-.`                                                            \033[37m      ");
	*/
endtask

endprogram

