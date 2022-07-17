module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic 
//================================================================
parameter S_IDLE = 4'd0;
parameter S_R_READY = 4'd1;
parameter S_R_VALID = 4'd2;
parameter S_W_READY = 4'd3;
parameter S_W_VALID = 4'd4;
parameter S_DONE = 4'd5;



logic [3:0] state_cs,state_ns;


//================================================================
// design 
//================================================================

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		state_cs<=S_IDLE;
	else 
		state_cs<=state_ns;
end

always_comb begin
	case(state_cs)
		S_IDLE : begin
			if(inf.C_in_valid)begin
				if(inf.C_r_wb)
					state_ns = S_R_READY;
				else
					state_ns = S_W_READY;
			end
			else
				state_ns = S_IDLE;
		end
		S_R_READY:state_ns = (inf.AR_READY)?S_R_VALID:S_R_READY;
		S_R_VALID:state_ns = (inf.R_VALID)?S_DONE:S_R_VALID;
		S_W_READY:state_ns = (inf.AW_READY)?S_W_VALID:S_W_READY;
		S_W_VALID:state_ns = (inf.B_VALID)?S_DONE:S_W_VALID;
		S_DONE:state_ns = S_IDLE;
		default:state_ns = state_cs;
	endcase
end

// write data
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.AW_ADDR<=0;
	else if(state_cs==S_W_READY && state_ns==S_W_VALID)
		inf.AW_ADDR<=0;
	else if(state_cs==S_IDLE && state_ns==S_W_READY)
		inf.AW_ADDR<=40'h10000+(inf.C_addr*8);
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.AW_VALID<=0;
	else if(state_cs==S_W_READY && state_ns==S_W_VALID)
		inf.AW_VALID<=0;
	else if(state_cs==S_IDLE && state_ns==S_W_READY)
		inf.AW_VALID<=1;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.W_DATA<=0;
	else if(state_ns==S_IDLE)
		inf.W_DATA<=0;
	else if(state_ns==S_W_READY)
		inf.W_DATA<=inf.C_data_w;
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.W_VALID<=0;
	else if(inf.W_READY)
		inf.W_VALID<=0;
	else if(state_cs==S_W_READY && state_ns==S_W_VALID)
		inf.W_VALID<=1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n)	inf.B_READY <= 0 ;
	else 			inf.B_READY <= 1 ;
end	

// read data

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.AR_ADDR<=0;
	else if(state_cs==S_R_READY && state_ns==S_R_VALID)
		inf.AR_ADDR<=0;
	else if(state_cs==S_IDLE && state_ns==S_R_READY)
		inf.AR_ADDR<=40'h10000+(inf.C_addr*8);
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.AR_VALID<=0;
	else if(state_cs==S_R_READY && state_ns==S_R_VALID)
		inf.AR_VALID<=0;
	else if(state_cs==S_IDLE && state_ns==S_R_READY)
		inf.AR_VALID<=1;
end



/*
always_comb begin
	if(!inf.C_in_valid)
		inf.AR_ADDR<=0;
	else if(state_cs==S_IDLE && state_ns==S_R_READY)
		inf.AR_ADDR<=40'h10000+(inf.C_addr*8);
end

always_comb begin
	if(state_ns==S_R_READY)
		inf.AR_VALID = inf.C_in_valid;
	else
		inf.AR_VALID = 0;
end
*/
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.R_READY<=0;
	else if(state_ns==S_DONE)
		inf.R_READY<=0;
	else if(state_ns==S_R_VALID)
		inf.R_READY<=1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) 	
		inf.C_out_valid <= 0 ;
	else begin
		if (state_ns==S_DONE)	
			inf.C_out_valid <= 1 ;
		else 							
			inf.C_out_valid <= 0 ;
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	
		inf.C_data_r <= 0 ;
	else begin
		if (inf.R_VALID==1) 	
			inf.C_data_r <= inf.R_DATA ;
		else 					
			inf.C_data_r <= 0 ;
	end
end


endmodule