module pokemon(input clk, INF.pokemon_inf inf);
import usertype::*;

//================================================================
// logic 
//================================================================
State_Machine state_cs,state_ns;
Item item;
Action action;
PKM_Type pkm_type;
Stage pkm_stage;
Stone stone;

Player_Info curr_player_info,defend_player_info;
Player_Info last_player_info;

logic[13:0] curr_money;

logic item_or_pokemon;
logic start_op;
logic done_input;
logic done_read;
logic done_start;
logic start_op2;
logic WR_DONE;
logic ready_get_seconde_info;
logic same_id;
logic [7:0] curr_id;
logic [7:0] last_id;
logic [7:0] defender_id;
//logic [7:0] counter;
logic [1:0] read_counter;
logic first_time;
logic last_data_write;
//================================================================
// design 
//================================================================

// Finite State Machine
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		state_cs<=S_IDLE;
	else
		state_cs<=state_ns;
end

always_comb begin
	case(state_cs)
		S_ID : state_ns = S_IDLE;
		S_IDLE : begin 
			if(inf.id_valid)
				state_ns = S_ID;
			else if(inf.act_valid)begin
				case(inf.D)
					4'b0001: state_ns = S_BUY;
					4'b0010: state_ns = S_SELL;
					4'b0110: state_ns = S_USE;
					4'b1010: state_ns = S_ATTACK;
					4'b0100: state_ns = S_DEPOSIT;
					4'b1000: state_ns = S_CHECK;
					default: state_ns = state_cs;
				endcase
			end
			else 
				state_ns = S_IDLE;
		end
		S_BUY: begin
			if(!start_op && done_start)
				state_ns = S_WR;
			else
				state_ns = S_BUY;
		end
		S_SELL: begin
			if(!start_op && done_start)
				state_ns = S_WR;
			else
				state_ns = S_SELL;
		end
		S_USE: begin
			if(!start_op && done_start)
				state_ns = S_WR;
			else
				state_ns = S_USE;
		end
		S_ATTACK: begin
			if(!start_op2 && !start_op && done_start)
				state_ns = S_WR_ATK;
			else
				state_ns = S_ATTACK;
		end
		S_DEPOSIT: begin
			if(!start_op && done_start)
				state_ns = S_WR;
			else
				state_ns = S_DEPOSIT;
		end
		S_CHECK: begin
			if(!start_op && done_start)
				state_ns = S_WR;
			else
				state_ns = S_CHECK;
		end
		S_WR:begin
			if(inf.out_valid==1)
				state_ns = S_IDLE;
			else
				state_ns = S_WR;
		end
		S_WR_ATK:begin
			if(inf.C_out_valid==1)
				state_ns = S_WR;
			else
				state_ns = S_WR_ATK;
		end
		default:state_ns = state_cs;
	endcase
end

// control signal



always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		first_time<=0;
	else if(inf.out_valid)
		first_time<=1;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		start_op<=0;
	else if(state_ns==S_IDLE)
		start_op<=0;
	else if(done_start)
		start_op<=0;
	else if(done_input && done_read)
		start_op<=1;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		done_start<=0;
	else if(state_ns==S_IDLE)
		done_start<=0;
	else if(done_input && done_read)
		done_start<=1;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		start_op2<=0;
	else if(start_op2)
		start_op2<=0;
	else if(start_op)
		start_op2<=1;
end

always_comb begin
	if((state_cs==S_BUY || state_cs==S_SELL || state_cs==S_USE || state_cs==S_CHECK || state_cs==S_DEPOSIT) &&  (same_id||read_counter==1))
		done_read = 1;
	else if(state_cs==S_ATTACK && read_counter==2)
		done_read = 1;
	else
		done_read = 0;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		done_input<=0;
	else if(state_ns==S_IDLE)
		done_input<=0;
	else if(state_ns==S_DEPOSIT && inf.amnt_valid)
		done_input<=1;
	else if(state_ns==S_SELL && (inf.type_valid || inf.item_valid))
		done_input<=1;
	else if(state_ns==S_BUY && (inf.type_valid || inf.item_valid))
		done_input<=1;
	else if(state_ns==S_CHECK)
		done_input<=1;
	else if(state_ns==S_USE && inf.item_valid)
		done_input<=1;
	else if(state_ns==S_ATTACK && inf.id_valid)
		done_input<=1;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		ready_get_seconde_info<=0;
	else if(state_ns==S_IDLE)
		ready_get_seconde_info<=0;
	else if(same_id)
		ready_get_seconde_info<=1;
	else if(state_ns==S_ATTACK)begin
		if(inf.C_out_valid)
			ready_get_seconde_info<=1;
	end
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		pkm_type<=No_type;
	else if(state_ns==S_IDLE)
		pkm_type<=No_type;
	else if(inf.type_valid)
		pkm_type<=inf.D;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		item<=No_item;
	else if(state_ns==S_IDLE)
		item<=No_item;
	else if(inf.item_valid)
		item<=inf.D;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		curr_money<=0;
	else if(state_ns==S_IDLE)
		curr_money<=0;
	else if(inf.amnt_valid)
		curr_money<=inf.D;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		item_or_pokemon<=0;
	else if(state_ns==S_IDLE)
		item_or_pokemon<=0;
	else if(state_ns!=S_IDLE && inf.item_valid)
		item_or_pokemon<=1;
end

// reg
logic [8:0]tmp_hp;
logic [8:0]tmp_exp;
always_comb begin
	if(start_op && state_cs==S_USE)begin
		if(item == Berry)begin
			tmp_hp = curr_player_info.pkm_info.hp+32;
		end
		else
			tmp_hp = 0;
	end
	else
		tmp_hp = 0;
end

always_comb begin
	if(start_op && state_cs==S_USE)begin
		if(item == Candy)begin
			tmp_exp = curr_player_info.pkm_info.exp+15;
		end
		else
			tmp_exp = 0;
	end
	else
		tmp_exp = 0;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		defend_player_info<=0;
	else if(state_ns==S_IDLE)
		defend_player_info<=0;
	else if(inf.C_out_valid && read_counter==1)begin
		if(last_id==defender_id)begin
			defend_player_info<=last_player_info;
		end
		else begin
		defend_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],inf.C_data_r[55:48],
						inf.C_data_r[63:56]};
		end
	end
	else if(start_op && state_ns==S_ATTACK)begin // calculate exp first
		if(curr_player_info.pkm_info==0 || defend_player_info.pkm_info==0)begin
				
		end
		else if(curr_player_info.pkm_info.hp==0 || defend_player_info.pkm_info.hp==0)begin
		
		end
		else
		case(defend_player_info.pkm_info.pkm_type)
			Grass:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>32)begin
								defend_player_info.pkm_info.exp <= 32;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>32)begin
								defend_player_info.pkm_info.exp <= 32;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>32)begin
								defend_player_info.pkm_info.exp <= 32;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defend_player_info.pkm_info.stage==Middle)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>63)begin
								defend_player_info.pkm_info.exp <= 63;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>63)begin
								defend_player_info.pkm_info.exp <= 63;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>63)begin
								defend_player_info.pkm_info.exp <= 63;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defend_player_info.pkm_info.stage==Highest)begin
					defend_player_info.pkm_info.exp <= 0;
				end
			end
			Fire:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>30)begin
								defend_player_info.pkm_info.exp <= 30;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>30)begin
								defend_player_info.pkm_info.exp <= 30;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>30)begin
								defend_player_info.pkm_info.exp <= 30;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defend_player_info.pkm_info.stage==Middle)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>59)begin
								defend_player_info.pkm_info.exp <= 59;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>59)begin
								defend_player_info.pkm_info.exp <= 59;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>59)begin
								defend_player_info.pkm_info.exp <= 59;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defend_player_info.pkm_info.stage==Highest)begin
					defend_player_info.pkm_info.exp  <= 0;
				end
			end
			Water:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>28)begin
								defend_player_info.pkm_info.exp <= 28;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>28)begin
								defend_player_info.pkm_info.exp <= 28;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>28)begin
								defend_player_info.pkm_info.exp <= 28;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defend_player_info.pkm_info.stage==Middle)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>55)begin
								defend_player_info.pkm_info.exp <= 55;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>55)begin
								defend_player_info.pkm_info.exp <= 55;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>55)begin
								defend_player_info.pkm_info.exp <= 55;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defend_player_info.pkm_info.stage==Highest)begin
					defend_player_info.pkm_info.exp  <= 0;
				end
			end
			Electric:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>26)begin
								defend_player_info.pkm_info.exp <= 26;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>26)begin
								defend_player_info.pkm_info.exp <= 26;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>26)begin
								defend_player_info.pkm_info.exp <= 26;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defend_player_info.pkm_info.stage==Middle)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>51)begin
								defend_player_info.pkm_info.exp <= 51;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>51)begin
								defend_player_info.pkm_info.exp <= 51;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>51)begin
								defend_player_info.pkm_info.exp <= 51;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
				else if(defend_player_info.pkm_info.stage==Highest)begin
					defend_player_info.pkm_info.exp  <= 0;
				end
			end
			Normal:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					case(curr_player_info.pkm_info.stage)
						Lowest:begin
							if(defend_player_info.pkm_info.exp+8>29)begin
								defend_player_info.pkm_info.exp <= 29;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 8;
							end
						end
						Middle:begin
							if(defend_player_info.pkm_info.exp+12>29)begin
								defend_player_info.pkm_info.exp <= 29;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 12;
							end
						end
						Highest:begin
							if(defend_player_info.pkm_info.exp+16>29)begin
								defend_player_info.pkm_info.exp <= 29;
							end
							else begin
								defend_player_info.pkm_info.exp <= defend_player_info.pkm_info.exp + 16;
							end
						end
					endcase
				end
			end
		endcase
	end
	else if(start_op2 && state_cs==S_ATTACK)begin // decide evolve or calculate hp
		if(curr_player_info.pkm_info==0 || defend_player_info.pkm_info==0)begin
		
		end
		else if(curr_player_info.pkm_info.hp==0 || defend_player_info.pkm_info.hp==0)begin
		
		end
		else
		case(defend_player_info.pkm_info.pkm_type)
			Grass:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					if(defend_player_info.pkm_info.exp==32)begin
						defend_player_info.pkm_info.stage <= Middle;
						defend_player_info.pkm_info.hp <= 192;
						defend_player_info.pkm_info.atk <= 94;
						defend_player_info.pkm_info.exp <= 0;
					end
					else begin
						defend_player_info.pkm_info.atk <= 63;
						if(curr_player_info.pkm_info.pkm_type==Fire)begin //2
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
						end
						else if(curr_player_info.pkm_info.pkm_type==Normal)begin //1
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
						else begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
					end
				end
				else if(defend_player_info.pkm_info.stage==Middle)begin
					if(defend_player_info.pkm_info.exp==63)begin
						defend_player_info.pkm_info.stage <= Highest;
						defend_player_info.pkm_info.hp <= 254;
						defend_player_info.pkm_info.atk <= 123;
						defend_player_info.pkm_info.exp <= 0;
					end
					else begin
						defend_player_info.pkm_info.atk <= 94;
						if(curr_player_info.pkm_info.pkm_type==Fire)begin //2
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
						end
						else if(curr_player_info.pkm_info.pkm_type==Normal)begin //1
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
						else begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
					end
				end
				else if(defend_player_info.pkm_info.stage==Highest)begin
					defend_player_info.pkm_info.exp  <= 0;
					defend_player_info.pkm_info.atk <= 123;
					if(curr_player_info.pkm_info.pkm_type==Fire)begin //2
						if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
							defend_player_info.pkm_info.hp <= 0;
						else
							defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
					end
					else if(curr_player_info.pkm_info.pkm_type==Normal)begin //1
						if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
							defend_player_info.pkm_info.hp <= 0;
						else
							defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
					end
					else begin
						if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
							defend_player_info.pkm_info.hp <= 0;
						else
							defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
					end
				end
			end
			Fire:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					if(defend_player_info.pkm_info.exp==30)begin
						defend_player_info.pkm_info.stage <= Middle;
						defend_player_info.pkm_info.hp <= 177;
						defend_player_info.pkm_info.atk <= 96;
						defend_player_info.pkm_info.exp <= 0;
					end
					else begin
						defend_player_info.pkm_info.atk <= 64;
						if(curr_player_info.pkm_info.pkm_type==Water)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
						end
						else if(curr_player_info.pkm_info.pkm_type==Electric || curr_player_info.pkm_info.pkm_type==Normal)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
						else begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
					
					end
				end
				else if(defend_player_info.pkm_info.stage==Middle)begin
					if(defend_player_info.pkm_info.exp==59)begin
						defend_player_info.pkm_info.stage <= Highest;
						defend_player_info.pkm_info.hp <= 225;
						defend_player_info.pkm_info.atk <= 127;
						defend_player_info.pkm_info.exp <= 0;
					end
					else begin
						defend_player_info.pkm_info.atk <= 96;
						if(curr_player_info.pkm_info.pkm_type==Water)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
						end
						else if(curr_player_info.pkm_info.pkm_type==Electric || curr_player_info.pkm_info.pkm_type==Normal)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
						else begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
					end
				end
				else if(defend_player_info.pkm_info.stage==Highest)begin
					defend_player_info.pkm_info.exp  <= 0;
					defend_player_info.pkm_info.atk <= 127;
					if(curr_player_info.pkm_info.pkm_type==Water)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
						end
						else if(curr_player_info.pkm_info.pkm_type==Electric || curr_player_info.pkm_info.pkm_type==Normal)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
						else begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
				end
			end
			Water:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					if(defend_player_info.pkm_info.exp==28)begin
						defend_player_info.pkm_info.stage <= Middle;
						defend_player_info.pkm_info.hp <= 187;
						defend_player_info.pkm_info.atk <= 89;
						defend_player_info.pkm_info.exp <= 0;
					end
					else begin
						defend_player_info.pkm_info.atk <= 60;
						if(curr_player_info.pkm_info.pkm_type==Grass || curr_player_info.pkm_info.pkm_type==Electric)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
						end
						else if(curr_player_info.pkm_info.pkm_type==Normal)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
						else begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
						
					end
				end
				else if(defend_player_info.pkm_info.stage==Middle)begin
					if(defend_player_info.pkm_info.exp==55)begin
						defend_player_info.pkm_info.stage <= Highest;
						defend_player_info.pkm_info.hp <= 245;
						defend_player_info.pkm_info.atk <= 113;
						defend_player_info.pkm_info.exp <= 0;
					end
					else begin
						defend_player_info.pkm_info.atk <= 89;
						if(curr_player_info.pkm_info.pkm_type==Grass || curr_player_info.pkm_info.pkm_type==Electric)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
						end
						else if(curr_player_info.pkm_info.pkm_type==Normal)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
						else begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
					end
				end
				else if(defend_player_info.pkm_info.stage==Highest)begin
					defend_player_info.pkm_info.exp  <= 0;
					defend_player_info.pkm_info.atk <= 113;
					if(curr_player_info.pkm_info.pkm_type==Grass || curr_player_info.pkm_info.pkm_type==Electric)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*2;
						end
						else if(curr_player_info.pkm_info.pkm_type==Normal)begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
						else begin
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
				end
			end
			Electric:begin
				if(defend_player_info.pkm_info.stage==Lowest)begin
					if(defend_player_info.pkm_info.exp==26)begin
						defend_player_info.pkm_info.stage <= Middle;
						defend_player_info.pkm_info.hp <= 182;
						defend_player_info.pkm_info.atk <= 97;
						defend_player_info.pkm_info.exp <= 0;
					end
					else begin
						defend_player_info.pkm_info.atk <= 65;
						if(curr_player_info.pkm_info.pkm_type==Electric)begin // 0.5
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
						else begin //1
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
					end
				end
				else if(defend_player_info.pkm_info.stage==Middle)begin
					if(defend_player_info.pkm_info.exp==51)begin
						defend_player_info.pkm_info.stage <= Highest;
						defend_player_info.pkm_info.hp <= 235;
						defend_player_info.pkm_info.atk <= 124;
						defend_player_info.pkm_info.exp <= 0;
					end
					else begin
						defend_player_info.pkm_info.atk <= 97;
						if(curr_player_info.pkm_info.pkm_type==Electric)begin // 0.5
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
						else begin //1
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
					end
				end
				else if(defend_player_info.pkm_info.stage==Highest)begin
					defend_player_info.pkm_info.exp  <= 0;
					defend_player_info.pkm_info.atk <= 124;
					if(curr_player_info.pkm_info.pkm_type==Electric)begin // 0.5
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk/2)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk/2;
						end
						else begin //1
							if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
								defend_player_info.pkm_info.hp <= 0;
							else
								defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
						end
				end
			end
			Normal:begin
					defend_player_info.pkm_info.atk <= 62;
					if(defend_player_info.pkm_info.hp<=curr_player_info.pkm_info.atk*1)
						defend_player_info.pkm_info.hp <= 0;
					else
						defend_player_info.pkm_info.hp <= defend_player_info.pkm_info.hp - curr_player_info.pkm_info.atk*1;
			end
		endcase	
	end
		
end


always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		last_player_info<=0;
	else if(state_cs==S_ATTACK && state_ns==S_WR_ATK && defender_id==last_id)
		last_player_info<=defend_player_info;
	else if(state_ns==S_ID && inf.id_valid && curr_id!=inf.D)
		last_player_info<=curr_player_info;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		curr_player_info<=0;
	else if(inf.C_out_valid && read_counter==0)begin
		case(inf.C_data_r[39:32])
			8'h11:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd63,
						inf.C_data_r[63:56]};
			end
			8'h21:
			begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd94,
						inf.C_data_r[63:56]};
			end
			8'h41:
			begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd123,
						inf.C_data_r[63:56]};
			end
			8'h12:
			begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd64,
						inf.C_data_r[63:56]};
			end
			8'h22:
			begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd96,
						inf.C_data_r[63:56]};
			end
			8'h42:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd127,
						inf.C_data_r[63:56]};
			end
			8'h14:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd60,
						inf.C_data_r[63:56]};
			end
			8'h24:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd89,
						inf.C_data_r[63:56]};
			end
			8'h44:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd113,
						inf.C_data_r[63:56]};
			end
			8'h18:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd65,
						inf.C_data_r[63:56]};
			end
			8'h28:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd97,
						inf.C_data_r[63:56]};
			end
			8'h48:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd124,
						inf.C_data_r[63:56]};
			end
			8'h15:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						inf.C_data_r[39:32],
						inf.C_data_r[47:40],8'd62,
						inf.C_data_r[63:56]};
			end
			default:begin
				curr_player_info<={inf.C_data_r[7:4],inf.C_data_r[3:0],
						inf.C_data_r[15:12],inf.C_data_r[11:8],
						inf.C_data_r[23:16],inf.C_data_r[31:24],
						32'd0};
			end
		endcase

	end
	else if(start_op)begin
		case(state_cs)
			S_SELL:begin
				if(item_or_pokemon)begin
					if(item == Berry && curr_player_info.bag_info.berry_num==0)begin
						//curr_player_info<=0;
					end
					else if( item == Medicine && curr_player_info.bag_info.medicine_num==0)begin
						//curr_player_info<=0;
					end
					else if( item == Candy && curr_player_info.bag_info.candy_num==0)begin
						//curr_player_info<=0;
					end
					else if( item == Bracer && curr_player_info.bag_info.bracer_num==0)begin
						//curr_player_info<=0;
					end
					else if( item == Water_stone && curr_player_info.bag_info.stone!=W_stone)begin
						//curr_player_info<=0;
					end
					else if( item == Fire_stone && curr_player_info.bag_info.stone!=F_stone)begin
						//curr_player_info<=0;
					end
					else if( item == Thunder_stone && curr_player_info.bag_info.stone!=T_stone)begin
						//curr_player_info<=0;
					end
					// normal case
					else
						case(item)
							Berry: begin 
								curr_player_info.bag_info.berry_num<=curr_player_info.bag_info.berry_num-1;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money+12;
							end
							Medicine:begin
								curr_player_info.bag_info.medicine_num<=curr_player_info.bag_info.medicine_num-1;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money+96;
							end
							Candy: begin 
								curr_player_info.bag_info.candy_num<=curr_player_info.bag_info.candy_num-1;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money+225;
							end
							Bracer: begin 
								curr_player_info.bag_info.bracer_num<=curr_player_info.bag_info.bracer_num-1;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money+48;
							end
							
							Water_stone:begin
								curr_player_info.bag_info.stone<=No_stone;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money+600;
							end
							Fire_stone:begin
								curr_player_info.bag_info.stone<=No_stone;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money+600;
							end	
							Thunder_stone:begin
								curr_player_info.bag_info.stone<=No_stone;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money+600;
							end	
						endcase
				end
				else begin
					if(curr_player_info.pkm_info.stage==No_stage)begin
						//curr_player_info <= 0;
					end
					else if(curr_player_info.pkm_info.stage==Lowest)begin
						//curr_player_info <= 0;
					end
					
					else begin
						curr_player_info.pkm_info<=0;
						case(curr_player_info.pkm_info.pkm_type)
							Grass:begin
								if(curr_player_info.pkm_info.stage==Middle)begin
									if(~curr_player_info.bag_info.money<=510)begin
										curr_player_info.bag_info.money<=14'd16383;
									end
									else
										curr_player_info.bag_info.money<=curr_player_info.bag_info.money+510;
								end
								else if(curr_player_info.pkm_info.stage==Highest)begin
									if(~curr_player_info.bag_info.money<=1100)begin
										curr_player_info.bag_info.money<=14'd16383;
									end
									else
										curr_player_info.bag_info.money<=curr_player_info.bag_info.money+1100;
								end
							end
							Fire:begin
								if(curr_player_info.pkm_info.stage==Middle)begin
									if(~curr_player_info.bag_info.money<=450)begin
										curr_player_info.bag_info.money<=14'd16383;
									end
									else
										curr_player_info.bag_info.money<=curr_player_info.bag_info.money+450;
								end
								else if(curr_player_info.pkm_info.stage==Highest)begin
									if(~curr_player_info.bag_info.money<=1000)begin
										curr_player_info.bag_info.money<=14'd16383;
									end
									else
										curr_player_info.bag_info.money<=curr_player_info.bag_info.money+1000;
								end
							end
							Water:begin
								if(curr_player_info.pkm_info.stage==Middle)begin
									if(~curr_player_info.bag_info.money<=500)begin
										curr_player_info.bag_info.money<=14'd16383;
									end
									else
										curr_player_info.bag_info.money<=curr_player_info.bag_info.money+500;
								end
								else if(curr_player_info.pkm_info.stage==Highest)begin
									if(~curr_player_info.bag_info.money<=1200)begin
										curr_player_info.bag_info.money<=14'd16383;
									end
									else
										curr_player_info.bag_info.money<=curr_player_info.bag_info.money+1200;
								end
							end
							Electric:begin
								if(curr_player_info.pkm_info.stage==Middle)begin
									if(~curr_player_info.bag_info.money<=550)begin
										curr_player_info.bag_info.money<=14'd16383;
									end
									else
										curr_player_info.bag_info.money<=curr_player_info.bag_info.money+550;
								end
								else if(curr_player_info.pkm_info.stage==Highest)begin
									if(~curr_player_info.bag_info.money<=1300)begin
										curr_player_info.bag_info.money<=14'd16383;
									end
									else
										curr_player_info.bag_info.money<=curr_player_info.bag_info.money+1300;
								end
							end
							Normal:begin
							
							end
						endcase
					end
				end
			end
			S_BUY:begin
				if(item_or_pokemon==0)begin
					if(pkm_type == Grass && curr_player_info.bag_info.money<100)begin
						//curr_player_info <=0;
					end
					else if(pkm_type == Fire && curr_player_info.bag_info.money<90)begin
						//curr_player_info <=0;
					end
					else if(pkm_type == Water && curr_player_info.bag_info.money<110)begin
						//curr_player_info <=0;
					end
					else if(pkm_type == Electric && curr_player_info.bag_info.money<120)begin
						//curr_player_info <=0;
					end
					else if(pkm_type == Normal && curr_player_info.bag_info.money<130)begin
						//curr_player_info <=0;
					end
					else if(curr_player_info.pkm_info.stage!=No_stage)begin
						//curr_player_info <=0;
					end
					else begin
						case(pkm_type)
							Grass:begin
								curr_player_info.pkm_info.stage <= Lowest;
								curr_player_info.pkm_info.pkm_type <= Grass;
								curr_player_info.pkm_info.hp <= 128;
								curr_player_info.pkm_info.atk <= 63;
								curr_player_info.pkm_info.exp <= 0;
								curr_player_info.bag_info.money <= curr_player_info.bag_info.money-100;
							end
							Fire:begin
								curr_player_info.pkm_info.stage <= Lowest;
								curr_player_info.pkm_info.pkm_type <= Fire;
								curr_player_info.pkm_info.hp <= 119;
								curr_player_info.pkm_info.atk <= 64;
								curr_player_info.pkm_info.exp <= 0;
								curr_player_info.bag_info.money <= curr_player_info.bag_info.money-90;
							end
							Water:begin
								curr_player_info.pkm_info.stage <= Lowest;
								curr_player_info.pkm_info.pkm_type <= Water;
								curr_player_info.pkm_info.hp <= 125;
								curr_player_info.pkm_info.atk <= 60;
								curr_player_info.pkm_info.exp <= 0;
								curr_player_info.bag_info.money <= curr_player_info.bag_info.money-110;
							end
							Electric:begin
								curr_player_info.pkm_info.stage <= Lowest;
								curr_player_info.pkm_info.pkm_type <= Electric;
								curr_player_info.pkm_info.hp <= 122;
								curr_player_info.pkm_info.atk <= 65;
								curr_player_info.pkm_info.exp <= 0;
								curr_player_info.bag_info.money <= curr_player_info.bag_info.money-120;
							end
							Normal:begin
								curr_player_info.pkm_info.stage <= Lowest;
								curr_player_info.pkm_info.pkm_type <= Normal;
								curr_player_info.pkm_info.hp <= 124;
								curr_player_info.pkm_info.atk <= 62;
								curr_player_info.pkm_info.exp <= 0;
								curr_player_info.bag_info.money <= curr_player_info.bag_info.money-130;
							end
						endcase
					end
				end
				else if(item_or_pokemon==1)begin
					case(item)
						Berry: begin 
							if(curr_player_info.bag_info.money<16)begin
								//$display("Out of money (1) ");
								//curr_player_info<=0;
							end
							else if(curr_player_info.bag_info.berry_num==15)begin
								//$display("Bag is full (3)  ");
								//curr_player_info<=0;
							end
							else begin
								curr_player_info.bag_info.berry_num<=curr_player_info.bag_info.berry_num+1;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money-16;
							end
							
						end
						Medicine:begin
							if(curr_player_info.bag_info.money<128)begin
								//$display("Out of money (1) ");
								//curr_player_info<=0;
							end
							else if(curr_player_info.bag_info.medicine_num==15)begin
								//$display("Bag is full (3)  ");
								//curr_player_info<=0;
							end
							else begin
								curr_player_info.bag_info.medicine_num<=curr_player_info.bag_info.medicine_num+1;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money-128;
							end
						end
						Candy: begin 
							if(curr_player_info.bag_info.money<300)begin
								//$display("Out of money (1) ");
								//curr_player_info<=0;
							end
							else if(curr_player_info.bag_info.candy_num==15)begin
								//$display("Bag is full (3)  ");
								//curr_player_info<=0;
							end
							else begin
								curr_player_info.bag_info.candy_num<=curr_player_info.bag_info.candy_num+1;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money-300;
							end
						end
						Bracer: begin 
							if(curr_player_info.bag_info.money<64)begin
								//$display("Out of money (1) ");
								//curr_player_info<=0;
							end
							else if(curr_player_info.bag_info.bracer_num==15)begin
								//$display("Bag is full (3)  ");
								//curr_player_info<=0;
							end
							else begin
								curr_player_info.bag_info.bracer_num<=curr_player_info.bag_info.bracer_num+1;
								curr_player_info.bag_info.money<=curr_player_info.bag_info.money-64;
							end
						end
						Water_stone: begin
							if(curr_player_info.bag_info.money<800)begin
								//$display("Out of money (1) ");
								//curr_player_info <= 0;
							end
							else if(curr_player_info.bag_info.stone!=No_stone)begin
								//$display("Bag is full (3)  ");
								//curr_player_info <= 0;
							end
							else begin
								curr_player_info.bag_info.stone <= W_stone;
								curr_player_info.bag_info.money <= curr_player_info.bag_info.money - 800;
							end
						end
						Fire_stone: begin
							if(curr_player_info.bag_info.money<800)begin
								//$display("Out of money (1) ");
								//curr_player_info<=0;
							end
							else if(curr_player_info.bag_info.stone!=No_stone)begin
								//$display("Bag is full (3)  ");
								//curr_player_info<=0;
							end
							else begin
								curr_player_info.bag_info.stone <= F_stone;
								curr_player_info.bag_info.money <= curr_player_info.bag_info.money - 800;
							end
						end
						Thunder_stone: begin
							if(curr_player_info.bag_info.money<800)begin
								//$display("Out of money (1) ");
								//curr_player_info<=0;
							end
							else if(curr_player_info.bag_info.stone!=No_stone)begin
								//$display("Bag is full (3)  ");
								//curr_player_info<=0;
							end
							else begin
								curr_player_info.bag_info.stone <= T_stone;
								curr_player_info.bag_info.money <= curr_player_info.bag_info.money - 800;
							end
						end
					endcase
				end
			end
			S_DEPOSIT:begin
				curr_player_info.bag_info.money<=curr_player_info.bag_info.money + curr_money;
			end
			S_USE:begin
				if(curr_player_info.pkm_info==0)begin
					//curr_player_info<=0;
				end
				else if(item==Berry && curr_player_info.bag_info.berry_num==0)begin
					//curr_player_info<=0;
				end
				else if(item==Medicine && curr_player_info.bag_info.medicine_num==0)begin
					//curr_player_info<=0;
				end
				else if(item==Candy && curr_player_info.bag_info.candy_num==0)begin
					//curr_player_info<=0;
				end
				else if(item==Bracer && curr_player_info.bag_info.bracer_num==0)begin
					//curr_player_info<=0;
				end
				else if((item==Water_stone && curr_player_info.bag_info.stone!=W_stone) ||
						(item==Thunder_stone && curr_player_info.bag_info.stone!=T_stone) ||
						(item==Fire_stone && curr_player_info.bag_info.stone!=F_stone)) begin
					//curr_player_info<=0;
				end
				
				else begin
					case(item)
						Berry: begin
							curr_player_info.bag_info.berry_num <= curr_player_info.bag_info.berry_num - 1;
							case(curr_player_info.pkm_info.pkm_type)
								Grass:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin
										if(tmp_hp>=128)
											curr_player_info.pkm_info.hp <= 128;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(tmp_hp>=192)
											curr_player_info.pkm_info.hp <= 192;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
									else begin
										if(tmp_hp>=254)
											curr_player_info.pkm_info.hp <= 254;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
								end
								Fire:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin
										if(tmp_hp>=119)
											curr_player_info.pkm_info.hp <= 119;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(tmp_hp>=177)
											curr_player_info.pkm_info.hp <= 177;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
									else begin
										if(tmp_hp>=225)
											curr_player_info.pkm_info.hp <= 225;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
								end
								Water:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin
										if(tmp_hp>=125)
											curr_player_info.pkm_info.hp <= 125;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(tmp_hp>=187)
											curr_player_info.pkm_info.hp <= 187;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
									else begin
										if(tmp_hp>=245)
											curr_player_info.pkm_info.hp <= 245;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
								end
								Electric:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin
										if(tmp_hp>=122)
											curr_player_info.pkm_info.hp <= 122;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(tmp_hp>=182)
											curr_player_info.pkm_info.hp <= 182;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
									else begin
										if(tmp_hp>=235)
											curr_player_info.pkm_info.hp <= 235;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
								end
								Normal:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin
										if(tmp_hp>=124)
											curr_player_info.pkm_info.hp <= 124;
										else
											curr_player_info.pkm_info.hp <= tmp_hp;
									end
								end
							endcase
						end
						Medicine:begin
							curr_player_info.bag_info.medicine_num <= curr_player_info.bag_info.medicine_num-1;
							case(curr_player_info.pkm_info.pkm_type)
								Grass:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										curr_player_info.pkm_info.hp <= 128;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										curr_player_info.pkm_info.hp <= 192;
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										curr_player_info.pkm_info.hp <= 254;
									end
								end
								Fire:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										curr_player_info.pkm_info.hp <= 119;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										curr_player_info.pkm_info.hp <= 177;
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										curr_player_info.pkm_info.hp <= 225;
									end
								end
								Water:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										curr_player_info.pkm_info.hp <= 125;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										curr_player_info.pkm_info.hp <= 187;
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										curr_player_info.pkm_info.hp <= 245;
									end
								end
								Electric:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										curr_player_info.pkm_info.hp <= 122;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										curr_player_info.pkm_info.hp <= 182;
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										curr_player_info.pkm_info.hp <= 235;
									end
								end
								Normal:begin
									curr_player_info.pkm_info.hp <= 124;
								end
							endcase
						end
						Candy:begin
							curr_player_info.bag_info.candy_num <= curr_player_info.bag_info.candy_num -1;
							case(curr_player_info.pkm_info.pkm_type)
								Grass:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(tmp_exp>=32)begin
											curr_player_info.pkm_info.stage <= Middle;
											curr_player_info.pkm_info.hp <= 192;
											curr_player_info.pkm_info.atk <= 94;
											curr_player_info.pkm_info.exp <= 0;
											
										end
										else
											curr_player_info.pkm_info.exp <= tmp_exp;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(tmp_exp>=63)begin
											curr_player_info.pkm_info.stage <= Highest;
											curr_player_info.pkm_info.hp <= 254;
											curr_player_info.pkm_info.atk <= 123;
											curr_player_info.pkm_info.exp <= 0;
										end
										else
											curr_player_info.pkm_info.exp <= tmp_exp;
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										curr_player_info.pkm_info.exp <= 0;
							end
								end
								Fire:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(tmp_exp>=30)begin
											curr_player_info.pkm_info.stage <= Middle;
											curr_player_info.pkm_info.hp <= 177;
											curr_player_info.pkm_info.atk <= 96;
											curr_player_info.pkm_info.exp <= 0;
										end
										else
											curr_player_info.pkm_info.exp <= tmp_exp;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(tmp_exp>=59)begin
											curr_player_info.pkm_info.stage <= Highest;
											curr_player_info.pkm_info.hp <= 225;
											curr_player_info.pkm_info.atk <= 127;
											curr_player_info.pkm_info.exp <= 0;
										end
										else
											curr_player_info.pkm_info.exp <= tmp_exp;
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										curr_player_info.pkm_info.exp <= 0;
							end
								end
								Water:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(tmp_exp>=28)begin
											curr_player_info.pkm_info.stage <= Middle;
											curr_player_info.pkm_info.hp <= 187;
											curr_player_info.pkm_info.atk <= 89;
											curr_player_info.pkm_info.exp <= 0;
										end
										else
											curr_player_info.pkm_info.exp <= tmp_exp;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(tmp_exp>=55)begin
											curr_player_info.pkm_info.stage <= Highest;
											curr_player_info.pkm_info.hp <= 245;
											curr_player_info.pkm_info.atk <= 113;
											curr_player_info.pkm_info.exp <= 0;
										end
										else
											curr_player_info.pkm_info.exp <= tmp_exp;
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										curr_player_info.pkm_info.exp <= 0;
							end
								end
								Electric:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(tmp_exp>=26)begin
											curr_player_info.pkm_info.stage <= Middle;
											curr_player_info.pkm_info.hp <= 182;
											curr_player_info.pkm_info.atk <= 97;
											curr_player_info.pkm_info.exp <= 0;
										end
										else
											curr_player_info.pkm_info.exp <= tmp_exp;
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(tmp_exp>=51)begin
											curr_player_info.pkm_info.stage <= Highest;
											curr_player_info.pkm_info.hp <= 235;
											curr_player_info.pkm_info.atk <= 124;
											curr_player_info.pkm_info.exp <= 0;
										end
										else
											curr_player_info.pkm_info.exp <= tmp_exp;
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										curr_player_info.pkm_info.exp <= 0;
									end
								end
								Normal:begin
									if(tmp_exp>=29)begin
										curr_player_info.pkm_info.exp <= 29;
									end
									else
										curr_player_info.pkm_info.exp <= tmp_exp;
									end
							endcase
						end
						Bracer: begin
							curr_player_info.bag_info.bracer_num <= curr_player_info.bag_info.bracer_num-1;
							case(curr_player_info.pkm_info.pkm_type)
								Grass:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(curr_player_info.pkm_info.atk==63)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(curr_player_info.pkm_info.atk==94)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										if(curr_player_info.pkm_info.atk==123)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
								end
								Fire:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(curr_player_info.pkm_info.atk==64)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(curr_player_info.pkm_info.atk==96)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										if(curr_player_info.pkm_info.atk==127)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
								end
								Water:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(curr_player_info.pkm_info.atk==60)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(curr_player_info.pkm_info.atk==89)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										if(curr_player_info.pkm_info.atk==113)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
								end
								Electric:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(curr_player_info.pkm_info.atk==65)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
									else if(curr_player_info.pkm_info.stage==Middle)begin
										if(curr_player_info.pkm_info.atk==97)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
									else if(curr_player_info.pkm_info.stage==Highest)begin
										if(curr_player_info.pkm_info.atk==124)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
								end
								Normal:begin
									if(curr_player_info.pkm_info.stage==Lowest)begin //stage
										if(curr_player_info.pkm_info.atk==62)begin
											curr_player_info.pkm_info.atk <= curr_player_info.pkm_info.atk+32;
										end
									end
								end
							endcase
						end
						Water_stone:begin
							if(curr_player_info.pkm_info.pkm_type==Normal && curr_player_info.pkm_info.exp==29)begin
								curr_player_info.pkm_info.stage <= Highest;
								curr_player_info.pkm_info.pkm_type <= Water;
								curr_player_info.pkm_info.hp <= 245;
								curr_player_info.pkm_info.atk <= 113;
								curr_player_info.pkm_info.exp <= 0;
								curr_player_info.bag_info.stone <= No_stone;
							end
							else begin
								curr_player_info.bag_info.stone <= No_stone;
							end
						end
						Fire_stone:begin
							if(curr_player_info.pkm_info.pkm_type==Normal && curr_player_info.pkm_info.exp==29)begin
								curr_player_info.pkm_info.stage <= Highest;
								curr_player_info.pkm_info.pkm_type <= Fire;
								curr_player_info.pkm_info.hp <= 225;
								curr_player_info.pkm_info.atk <= 127;
								curr_player_info.pkm_info.exp <= 0;
								curr_player_info.bag_info.stone <= No_stone;
							end
							else begin
								curr_player_info.bag_info.stone <= No_stone;
							end
						end
						Thunder_stone:begin
							if(curr_player_info.pkm_info.pkm_type==Normal && curr_player_info.pkm_info.exp==29)begin
								curr_player_info.pkm_info.stage <= Highest;
								curr_player_info.pkm_info.pkm_type <= Electric;
								curr_player_info.pkm_info.hp <= 235;
								curr_player_info.pkm_info.atk <= 124;
								curr_player_info.pkm_info.exp <= 0;
								curr_player_info.bag_info.stone <= No_stone;
							end
							else begin
								curr_player_info.bag_info.stone <= No_stone;
							end
						end
					endcase
				end
			end
			S_ATTACK:begin // calculate exp first
				if(curr_player_info.pkm_info==0 || defend_player_info.pkm_info==0)begin
				
				end
				else if(curr_player_info.pkm_info.hp==0 || defend_player_info.pkm_info.hp==0)begin
				
				end
				else
					case(curr_player_info.pkm_info.pkm_type)
					Grass:begin
						if(curr_player_info.pkm_info.stage==Lowest)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>32)begin
										curr_player_info.pkm_info.exp <= 32;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>32)begin
										curr_player_info.pkm_info.exp <= 32;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>32)begin
										curr_player_info.pkm_info.exp <= 32;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase
						end
						else if(curr_player_info.pkm_info.stage==Middle)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>63)begin
										curr_player_info.pkm_info.exp <= 63;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>63)begin
										curr_player_info.pkm_info.exp <= 63;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>63)begin
										curr_player_info.pkm_info.exp <= 63;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase
						end
						else if(curr_player_info.pkm_info.stage==Highest)begin
							curr_player_info.pkm_info.exp  <= 0;
						end
					end
					Fire:begin
						if(curr_player_info.pkm_info.stage==Lowest)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>30)begin
										curr_player_info.pkm_info.exp <= 30;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>30)begin
										curr_player_info.pkm_info.exp <= 30;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>30)begin
										curr_player_info.pkm_info.exp <= 30;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase

						end
						else if(curr_player_info.pkm_info.stage==Middle)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>59)begin
										curr_player_info.pkm_info.exp <= 59;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>59)begin
										curr_player_info.pkm_info.exp <= 59;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>59)begin
										curr_player_info.pkm_info.exp <= 59;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase
						end
						else if(curr_player_info.pkm_info.stage==Highest)begin
							curr_player_info.pkm_info.exp  <= 0;
						end
					end
					Water:begin
						if(curr_player_info.pkm_info.stage==Lowest)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>28)begin
										curr_player_info.pkm_info.exp <= 28;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>28)begin
										curr_player_info.pkm_info.exp <= 28;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>28)begin
										curr_player_info.pkm_info.exp <= 28;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase
						end
						else if(curr_player_info.pkm_info.stage==Middle)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>55)begin
										curr_player_info.pkm_info.exp <= 55;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>55)begin
										curr_player_info.pkm_info.exp <= 55;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>55)begin
										curr_player_info.pkm_info.exp <= 55;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase
						end
						else if(curr_player_info.pkm_info.stage==Highest)begin
							curr_player_info.pkm_info.exp <= 0;
						end
					end
					Electric:begin
						if(curr_player_info.pkm_info.stage==Lowest)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>26)begin
										curr_player_info.pkm_info.exp <= 26;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>26)begin
										curr_player_info.pkm_info.exp <= 26;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>26)begin
										curr_player_info.pkm_info.exp <= 26;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase
						end
						else if(curr_player_info.pkm_info.stage==Middle)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>51)begin
										curr_player_info.pkm_info.exp <= 51;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>51)begin
										curr_player_info.pkm_info.exp <= 51;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>51)begin
										curr_player_info.pkm_info.exp <= 51;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase
						end
						else if(curr_player_info.pkm_info.stage==Highest)begin
							curr_player_info.pkm_info.exp  <= 0;
						end
					end
					Normal:begin
						if(curr_player_info.pkm_info.stage==Lowest)begin
							case(defend_player_info.pkm_info.stage)
								Lowest:begin
									if(curr_player_info.pkm_info.exp+16>29)begin
										curr_player_info.pkm_info.exp <= 29;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 16;
									end
								end
								Middle:begin
									if(curr_player_info.pkm_info.exp+24>29)begin
										curr_player_info.pkm_info.exp <= 29;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 24;
									end
								end
								Highest:begin
									if(curr_player_info.pkm_info.exp+32>29)begin
										curr_player_info.pkm_info.exp <= 29;
									end
									else begin
										curr_player_info.pkm_info.exp <= curr_player_info.pkm_info.exp + 32;
									end
								end
							endcase
						end
					end
					endcase
			end
		endcase
	end
	else if(state_cs==S_ATTACK && start_op2)begin // decide evo or calculate hp
		if(curr_player_info.pkm_info==0 || defend_player_info.pkm_info==0)begin
		
		end
		else if(curr_player_info.pkm_info.hp==0 || defend_player_info.pkm_info.hp==0)begin
		
		end
		else
		case(curr_player_info.pkm_info.pkm_type)
			Grass:begin
				if(curr_player_info.pkm_info.stage==Lowest)begin
					if(curr_player_info.pkm_info.exp==32)begin
						curr_player_info.pkm_info.stage <= Middle;
						curr_player_info.pkm_info.hp <= 192;
						curr_player_info.pkm_info.atk <= 94;
						curr_player_info.pkm_info.exp <= 0;
						
					end
					else begin
						curr_player_info.pkm_info.atk <= 63;
					end
				end
				else if(curr_player_info.pkm_info.stage==Middle)begin
					if(curr_player_info.pkm_info.exp==63)begin
						curr_player_info.pkm_info.stage <= Highest;
						curr_player_info.pkm_info.hp <= 254;
						curr_player_info.pkm_info.atk <= 123;
						curr_player_info.pkm_info.exp <= 0;
					end
					else begin
						curr_player_info.pkm_info.atk <= 94;
					end
				end
				else if(curr_player_info.pkm_info.stage==Highest)begin
					curr_player_info.pkm_info.exp  <= 0;
					curr_player_info.pkm_info.atk <= 123;
				end
			end
			Fire:begin
				if(curr_player_info.pkm_info.stage==Lowest)begin
					if(curr_player_info.pkm_info.exp==30)begin
						curr_player_info.pkm_info.stage <= Middle;
						curr_player_info.pkm_info.hp <= 177;
						curr_player_info.pkm_info.atk <= 96;
						curr_player_info.pkm_info.exp <= 0;
					end
					else begin
						curr_player_info.pkm_info.atk <= 64;
					end
				end
				else if(curr_player_info.pkm_info.stage==Middle)begin
					if(curr_player_info.pkm_info.exp==59)begin
						curr_player_info.pkm_info.stage <= Highest;
						curr_player_info.pkm_info.hp <= 225;
						curr_player_info.pkm_info.atk <= 127;
						curr_player_info.pkm_info.exp <= 0;
					end
					else begin
						curr_player_info.pkm_info.atk <= 96;
					end
				end
				else if(curr_player_info.pkm_info.stage==Highest)begin
					curr_player_info.pkm_info.exp  <= 0;
					curr_player_info.pkm_info.atk <= 127;
				end
			end
			Water:begin
				if(curr_player_info.pkm_info.stage==Lowest)begin
					if(curr_player_info.pkm_info.exp==28)begin
						curr_player_info.pkm_info.stage <= Middle;
						curr_player_info.pkm_info.hp <= 187;
						curr_player_info.pkm_info.atk <= 89;
						curr_player_info.pkm_info.exp <= 0;
					end
					else begin
						curr_player_info.pkm_info.atk <= 60;
					end
				end
				else if(curr_player_info.pkm_info.stage==Middle)begin
					if(curr_player_info.pkm_info.exp==55)begin
						curr_player_info.pkm_info.stage <= Highest;
						curr_player_info.pkm_info.atk <= 113;
						curr_player_info.pkm_info.hp <= 245;
						curr_player_info.pkm_info.exp <= 0;
					end
					else begin
						curr_player_info.pkm_info.atk <= 89;
					end
				end
				else if(curr_player_info.pkm_info.stage==Highest)begin
					//$display("enter");
					curr_player_info.pkm_info.exp  <= 0;
					curr_player_info.pkm_info.atk <= 113;
				end
			end
			Electric:begin
				if(curr_player_info.pkm_info.stage==Lowest)begin
					if(curr_player_info.pkm_info.exp==26)begin
						curr_player_info.pkm_info.stage <= Middle;
						curr_player_info.pkm_info.hp <= 182;
						curr_player_info.pkm_info.atk <= 97;
						curr_player_info.pkm_info.exp <= 0;
					end
					else begin
						curr_player_info.pkm_info.atk <= 65;
					end
				end
				else if(curr_player_info.pkm_info.stage==Middle)begin
					if(curr_player_info.pkm_info.exp==51)begin
						curr_player_info.pkm_info.stage <= Highest;
						curr_player_info.pkm_info.hp <= 235;
						curr_player_info.pkm_info.atk <= 124;
						curr_player_info.pkm_info.exp <= 0;
					end
					else begin
						curr_player_info.pkm_info.atk <= 97;
					end
				end
				else if(curr_player_info.pkm_info.stage==Highest)begin
					curr_player_info.pkm_info.exp  <= 0;
					curr_player_info.pkm_info.atk <= 124;
				end
			end
			Normal:begin
				if(curr_player_info.pkm_info.stage==Lowest)begin
					if(curr_player_info.pkm_info.exp==29)begin
						curr_player_info.pkm_info.exp <= 29;
						curr_player_info.pkm_info.atk <= 62;
					end
					else begin
						curr_player_info.pkm_info.atk <= 62;
					end
				end
			end
		endcase
	end
end


always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		defender_id<=0;
	else if(state_ns==S_ATTACK && inf.id_valid)
		defender_id<=inf.D;
end

logic id_valid_have_been_high;

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		id_valid_have_been_high<=0;
	else if(state_cs==S_WR && state_ns==S_IDLE)
		id_valid_have_been_high<=0;
	else if(state_ns==S_ID)
		id_valid_have_been_high<=1;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		same_id<=0;
	else if((state_ns==S_ID && inf.D==curr_id && first_time==1) || (state_cs==S_IDLE && (state_ns==S_BUY || state_ns==S_USE || state_ns==S_SELL || state_ns==S_CHECK || state_ns==S_DEPOSIT || state_ns==S_ATTACK)&& id_valid_have_been_high==0))
		same_id<=1;
	else if(inf.id_valid && inf.D!=curr_id && state_cs!=S_ATTACK)
		same_id<=0;
end


always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		curr_id<=0;
	else if(state_ns==S_ID)
		curr_id<=inf.D;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		last_id<=0;
	else if(first_time && state_ns==S_ID && inf.D!=curr_id )
		last_id<=curr_id;
end


always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		read_counter<=0;
	else if(state_ns==S_IDLE)
		read_counter<=0;
	else if(state_cs==S_IDLE && state_ns==S_ATTACK && (!id_valid_have_been_high || same_id))
		read_counter<=1;
		/*
	else if(state_cs==S_BUY || state_cs==S_SELL || state_cs==S_USE || state_cs==S_CHECK || state_cs==S_DEPOSIT)
		read_counter<=1;
		*/
	else if(inf.C_out_valid)
		read_counter<=read_counter+1;
end

// output

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.err_msg<=No_Err;
	else if(state_ns==S_IDLE)
		inf.err_msg<=No_Err;
	else if(state_cs==S_ATTACK)begin
		if(ready_get_seconde_info && curr_player_info.pkm_info==0)
			inf.err_msg<=Not_Having_PKM;
		else if(done_read && defend_player_info.pkm_info==0)begin
			inf.err_msg<=Not_Having_PKM;
		end
		else if(ready_get_seconde_info && curr_player_info.pkm_info.hp==0 && !done_start)begin
			inf.err_msg<=HP_is_Zero;
		end
		else if(done_read && defend_player_info.pkm_info.hp==0 && !done_start)begin
			inf.err_msg<=HP_is_Zero;
		end
	end
	else if(state_cs==S_BUY&& done_read && done_input && !done_start)begin
		if(item_or_pokemon==0)begin
			if(curr_player_info.bag_info.money<100 && pkm_type==Grass)
				inf.err_msg<=Out_of_money;
			else if(curr_player_info.bag_info.money<90 && pkm_type==Fire)
				inf.err_msg<=Out_of_money;
			else if(curr_player_info.bag_info.money<110 && pkm_type==Water)
				inf.err_msg<=Out_of_money;
			else if(curr_player_info.bag_info.money<120 && pkm_type==Electric)
				inf.err_msg<=Out_of_money;
			else if(curr_player_info.bag_info.money<130 && pkm_type==Normal)
				inf.err_msg<=Out_of_money;
			else if(curr_player_info.pkm_info.stage!=No_stage)
				inf.err_msg<=Already_Have_PKM;
		end
		else begin
			case(item)
				Berry:begin
					if(curr_player_info.bag_info.money<16)
						inf.err_msg<=Out_of_money;
					else if(curr_player_info.bag_info.berry_num==15)
						inf.err_msg<=Bag_is_full;
				end
				Medicine:begin
					if(curr_player_info.bag_info.money<128)
						inf.err_msg<=Out_of_money;
					else if(curr_player_info.bag_info.medicine_num==15)
						inf.err_msg<=Bag_is_full;
				end
				Candy:begin
					if(curr_player_info.bag_info.money<300)
						inf.err_msg<=Out_of_money;
					else if(curr_player_info.bag_info.candy_num==15)
						inf.err_msg<=Bag_is_full;
				end
				Bracer:begin
					if(curr_player_info.bag_info.money<64)
						inf.err_msg<=Out_of_money;
					else if(curr_player_info.bag_info.bracer_num==15)
						inf.err_msg<=Bag_is_full;
				end
				Water_stone:begin
					if(curr_player_info.bag_info.money<800)
						inf.err_msg<=Out_of_money;
					else if(curr_player_info.bag_info.stone!=No_stone)
						inf.err_msg<=Bag_is_full;
				end
				Fire_stone:begin
					if(curr_player_info.bag_info.money<800)
						inf.err_msg<=Out_of_money;
					else if(curr_player_info.bag_info.stone!=No_stone)
						inf.err_msg<=Bag_is_full;
				end
				Thunder_stone:begin
					if(curr_player_info.bag_info.money<800)
						inf.err_msg<=Out_of_money;
					else if(curr_player_info.bag_info.stone!=No_stone)
						inf.err_msg<=Bag_is_full;
				end
			endcase
		end
	end
	else if(state_cs==S_SELL && done_read && done_input && !done_start)begin
		if(item_or_pokemon==0)begin
			if(curr_player_info.pkm_info==0)
				inf.err_msg<=Not_Having_PKM;
			else if(curr_player_info.pkm_info.stage==Lowest)
				inf.err_msg<=Has_Not_Grown;
		end
		else begin
			case(item)
				Berry:begin
					if(curr_player_info.bag_info.berry_num==0)
						inf.err_msg<=Not_Having_Item;
				end
				Medicine:begin
					if(curr_player_info.bag_info.medicine_num==0)
						inf.err_msg<=Not_Having_Item;
				end
				Candy:begin
					if(curr_player_info.bag_info.candy_num==0)
						inf.err_msg<=Not_Having_Item;
				end
				Bracer:begin
					if(curr_player_info.bag_info.bracer_num==0)
						inf.err_msg<=Not_Having_Item;
				end
				Water_stone:begin
					if(curr_player_info.bag_info.stone!=W_stone)
						inf.err_msg<=Not_Having_Item;
				end
				Fire_stone:begin
					if(curr_player_info.bag_info.stone!=F_stone)
						inf.err_msg<=Not_Having_Item;
				end
				Thunder_stone:begin
					if(curr_player_info.bag_info.stone!=T_stone)
						inf.err_msg<=Not_Having_Item;
				end
			endcase
		end
	end	
	else if(state_cs==S_USE && done_read && done_input &&!done_start)begin
		if(curr_player_info.pkm_info==0)begin
			inf.err_msg<=Not_Having_PKM;
		end
		else  begin
			case(item)
				Berry:begin
					if(curr_player_info.bag_info.berry_num==0)
						inf.err_msg<=Not_Having_Item;
				end
				Medicine:begin
					if(curr_player_info.bag_info.medicine_num==0)
						inf.err_msg<=Not_Having_Item;
				end
				Candy:begin
					if(curr_player_info.bag_info.candy_num==0)
						inf.err_msg<=Not_Having_Item;
				end
				Bracer:begin
					if(curr_player_info.bag_info.bracer_num==0)
						inf.err_msg<=Not_Having_Item;
				end
				Water_stone:begin
					if(curr_player_info.bag_info.stone!=W_stone)
						inf.err_msg<=Not_Having_Item;
				end
				Fire_stone:begin
					if(curr_player_info.bag_info.stone!=F_stone)
						inf.err_msg<=Not_Having_Item;
				end
				Thunder_stone:begin
					if(curr_player_info.bag_info.stone!=T_stone)
						inf.err_msg<=Not_Having_Item;
				end
			endcase
		end
	end
end

logic axi_operating;

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		axi_operating<=0;
	else if(inf.C_in_valid)
		axi_operating<=1;
	else if(inf.C_out_valid)
		axi_operating<=0;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.complete<=0;
	else if(state_ns==S_IDLE)
		inf.complete<=0;
		
	else if(start_op && inf.err_msg==No_Err)
		inf.complete<=1;
	else if(state_cs==S_ATTACK)begin
		if(ready_get_seconde_info && curr_player_info.pkm_info==0)
			inf.complete<=0;
		else if(done_read && defend_player_info.pkm_info==0)begin
			inf.complete<=0;
		end
		else if(ready_get_seconde_info && curr_player_info.pkm_info.hp==0 && !done_start)begin
			inf.complete<=0;
		end
		else if(done_read && defend_player_info.pkm_info.hp==0 && !done_start)begin
			inf.complete<=0;
		end
	end
	else if(state_cs==S_SELL && done_read && done_input && !done_start)begin
		if(item_or_pokemon==0)begin
			if(curr_player_info.pkm_info==0)
				inf.complete<=0;
			else if(curr_player_info.pkm_info.stage==Lowest)
				inf.complete<=0;
		end
		else begin
			case(item)
				Berry:begin
					if(curr_player_info.bag_info.berry_num==0)
						inf.complete<=0;
				end
				Medicine:begin
					if(curr_player_info.bag_info.medicine_num==0)
						inf.complete<=0;
				end
				Candy:begin
					if(curr_player_info.bag_info.candy_num==0)
						inf.complete<=0;
				end
				Bracer:begin
					if(curr_player_info.bag_info.bracer_num==0)
						inf.complete<=0;
				end
				Water_stone:begin
					if(curr_player_info.bag_info.stone!=W_stone)
						inf.complete<=0;
				end
				Fire_stone:begin
					if(curr_player_info.bag_info.stone!=F_stone)
						inf.complete<=0;
				end
				Thunder_stone:begin
					if(curr_player_info.bag_info.stone!=T_stone)
						inf.complete<=0;
				end
			endcase
		end
	end	
	else if(state_cs==S_BUY&& done_read && done_input && !done_start)begin
		if(item_or_pokemon==0)begin
			if(curr_player_info.pkm_info.stage==No_stage)
				case(pkm_type)
					Grass:begin
						if(curr_player_info.bag_info.money<100)
							inf.complete<=0;
					end
					Fire:begin
						if(curr_player_info.bag_info.money<90)
							inf.complete<=0;
					end
					Water:begin
						if(curr_player_info.bag_info.money<110)
							inf.complete<=0;
					end
					Electric:begin
						if(curr_player_info.bag_info.money<120)
							inf.complete<=0;
					end
					Normal:begin
						if(curr_player_info.bag_info.money<130)
							inf.complete<=0;
					end
				endcase
			else if(curr_player_info.pkm_info.stage!=No_stage)
				inf.complete<=0;
		end
		else begin
			case(item)
				Berry:begin
					if(curr_player_info.bag_info.money<16)
						inf.complete<=0;
					else if(curr_player_info.bag_info.berry_num==15)
						inf.complete<=0;
				end
				Medicine:begin
					if(curr_player_info.bag_info.money<128)
						inf.complete<=0;
					else if(curr_player_info.bag_info.medicine_num==15)
						inf.complete<=0;
				end
				Candy:begin
					if(curr_player_info.bag_info.money<300)
						inf.complete<=0;
					else if(curr_player_info.bag_info.candy_num==15)
						inf.complete<=0;
				end
				Bracer:begin
					if(curr_player_info.bag_info.money<64)
						inf.complete<=0;
					else if(curr_player_info.bag_info.bracer_num==15)
						inf.complete<=0;
				end
				Water_stone:begin
					if(curr_player_info.bag_info.money<800)
						inf.complete<=0;
					else if(curr_player_info.bag_info.stone!=No_stone)
						inf.complete<=0;
				end
				Fire_stone:begin
					if(curr_player_info.bag_info.money<800)
						inf.complete<=0;
					else if(curr_player_info.bag_info.stone!=No_stone)
						inf.complete<=0;
				end
				Thunder_stone:begin
					if(curr_player_info.bag_info.money<800)
						inf.complete<=0;
					else if(curr_player_info.bag_info.stone!=No_stone)
						inf.complete<=0;
				end
			endcase
		end
	end
	else if(state_cs==S_USE && done_read && done_input &&!done_start)begin
		if(curr_player_info.pkm_info==0)begin
			inf.complete<=0;
		end
		else  begin
			case(item)
				Berry:begin
					if(curr_player_info.bag_info.berry_num==0)
						inf.complete<=0;
				end
				Medicine:begin
					if(curr_player_info.bag_info.medicine_num==0)
						inf.complete<=0;
				end
				Candy:begin
					if(curr_player_info.bag_info.candy_num==0)
						inf.complete<=0;
				end
				Bracer:begin
					if(curr_player_info.bag_info.bracer_num==0)
						inf.complete<=0;
				end
				Water_stone:begin
					if(curr_player_info.bag_info.stone!=W_stone)
						inf.complete<=0;
				end
				Fire_stone:begin
					if(curr_player_info.bag_info.stone!=F_stone)
						inf.complete<=0;
				end
				Thunder_stone:begin
					if(curr_player_info.bag_info.stone!=T_stone)
						inf.complete<=0;
				end
			endcase
		end
	end
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.out_valid<=0;
	else if(state_cs==S_WR_ATK && state_ns==S_WR && (first_time==0 || same_id || defender_id==last_id))
		inf.out_valid<=1;
	else if((first_time==0 || same_id || inf.C_out_valid) && state_ns==S_WR && state_cs!=S_WR_ATK)
		inf.out_valid<=1;
	else
		inf.out_valid<=0;
end



always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.out_info<=0;
	else if(state_ns==S_IDLE)
		inf.out_info<=0;
	else if(inf.err_msg!=No_Err)
		inf.out_info<=0;
	else if(state_cs==S_CHECK && start_op)
		inf.out_info<=curr_player_info;
	else if(state_cs==S_WR_ATK && state_ns==S_WR)
		inf.out_info<={curr_player_info.pkm_info,defend_player_info.pkm_info};
	else if(state_cs!=S_WR && state_ns==S_WR)
		inf.out_info<=curr_player_info;
end


// bridge controller
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.C_addr<=0;
	else if(state_ns==S_WR && same_id==0)
		inf.C_addr<=last_id;
	else if(state_ns==S_ID)
		inf.C_addr<=inf.D;
	else if(state_ns==S_ATTACK && inf.id_valid && (inf.C_out_valid||ready_get_seconde_info))
		inf.C_addr<=inf.D;
	else if(state_ns==S_ATTACK && inf.C_out_valid)
		inf.C_addr<=defender_id;
	else if(state_ns==S_WR_ATK)
		inf.C_addr<=defender_id;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.C_data_w<=0;
		
	else if(state_cs==S_ATTACK && state_ns==S_WR_ATK)
		inf.C_data_w<={defend_player_info[7:0],defend_player_info[15:8],
						defend_player_info[23:16],defend_player_info[31:24],
						defend_player_info[39:32],defend_player_info[47:40],
						defend_player_info[55:48],defend_player_info[63:56]};
	else if(state_ns==S_WR)
		inf.C_data_w<={last_player_info[7:0],last_player_info[15:8],
						last_player_info[23:16],last_player_info[31:24],
						last_player_info[39:32],last_player_info[47:40],
						last_player_info[55:48],last_player_info[63:56]};					
end
logic done_second_valid;

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		done_second_valid<=0;
	else if(state_ns==S_IDLE)
		done_second_valid<=0;
	else if(state_cs==S_ATTACK)
		if(read_counter==1 && inf.C_in_valid==1)
			done_second_valid<=1;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.C_in_valid<=0;
	else if((state_ns==S_ID && (inf.D!=curr_id || first_time==0)))
		inf.C_in_valid<=1;
	else if(state_cs!=S_WR_ATK &&state_cs!=S_WR && state_ns==S_WR && same_id==0 && first_time==1)
		inf.C_in_valid<=1;
	else if(state_cs==S_WR_ATK && state_ns==S_WR && defender_id==last_id && first_time==1)
		inf.C_in_valid<=0;
	else if(state_cs==S_WR_ATK && state_ns==S_WR && (same_id==0) && first_time==1)
		inf.C_in_valid<=1;
	else if(state_ns==S_ATTACK)begin
		if(inf.C_in_valid)
			inf.C_in_valid<=0;
		else if(ready_get_seconde_info && inf.id_valid && axi_operating==0)
			inf.C_in_valid<=1;
		else if(ready_get_seconde_info && done_input && done_second_valid==0 && axi_operating==0)
			inf.C_in_valid<=1;
	end
	else if(state_ns==S_WR_ATK)begin
		if(state_cs==S_ATTACK)
			inf.C_in_valid<=1;
		else 
			inf.C_in_valid<=0;
	end
	
	else
		inf.C_in_valid<=0;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.C_r_wb<=0;
	else if(state_ns==S_IDLE)
		inf.C_r_wb<=1;
	else if(state_ns==S_WR || state_ns==S_WR_ATK)
		inf.C_r_wb<=0;
	else if(state_ns==S_ID)
		inf.C_r_wb<=1;
end


endmodule