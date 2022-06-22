//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : RSA_IP.v
//   Module Name : RSA_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module RSA_IP #(parameter WIDTH = 3) (
    // Input signals
    IN_P, IN_Q, IN_E,
    // Output signals
    OUT_N, OUT_D
);

// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1:0]   IN_P, IN_Q;
input  [WIDTH*2-1:0] IN_E;
output [WIDTH*2-1:0] OUT_N, OUT_D;


// ===============================================================
// Reg Wire Declaration
// ===============================================================
wire  [WIDTH*2-1:0] OUT_N;
wire  signed[WIDTH*2-1:0] OUT_D;
wire [WIDTH-1:0] P;
wire [WIDTH-1:0] Q;
wire [WIDTH*2-1:0] N;
wire signed[WIDTH*2-1:0] Phi;
// ===============================================================
// Soft IP DESIGN
// ===============================================================

assign OUT_N = IN_P*IN_Q;
assign Phi = (IN_P-1)*(IN_Q-1);


//parameter N_level = 2;
wire signed[WIDTH*2-1:0]remainder [1:WIDTH*2];
wire signed[WIDTH*2-1:0]quotient [1:WIDTH*2];
wire checkDone [1:WIDTH*2];
wire signed[WIDTH*2-1:0] A [1:WIDTH*2];
wire signed[WIDTH*2-1:0] B [1:WIDTH*2];

	
genvar level_idx,iter_idx;
genvar iter_idx2;
generate
	for(level_idx = 1; level_idx<=1; level_idx=level_idx+1)begin: level_l
		if(level_idx ==1)begin: if_lv_1
			for(iter_idx = 1 ; iter_idx<=6; iter_idx = iter_idx+1)begin : iter_l
				wire checkOne;
				if(iter_idx==1)begin
					assign remainder[1] = Phi % IN_E;
					assign quotient[1] = Phi / IN_E;
					assign checkOne = remainder[1]==1;
					assign checkDone[1] = 0;
					assign A[1] = (checkOne)?1:B[2];
					assign B[1] = (checkOne)?(-1*quotient[1]):(A[2] + B[2] * -1 *quotient[1]);
					assign OUT_D = (B[1][WIDTH*2-1]==1)? B[1]+Phi:B[1];
				end
				else if(iter_idx==2)begin
					assign remainder[2] = (IN_E) % (remainder[1]);
					assign quotient[2] = (IN_E) / (remainder[1]);
					assign checkOne = remainder[2]==1;
					assign checkDone[2] = (checkDone[1] || level_l[1].if_lv_1.iter_l[1].checkOne);
					assign A[2] = (checkOne)?1:((checkDone[2])?0:B[3]);
					assign B[2] = (checkOne)?(-1*quotient[2]):((checkDone[2])?0:(A[3] + B[3] * -1 *quotient[2]));
				end
				else begin
					assign remainder[iter_idx] = (remainder[iter_idx-2]) % (remainder[iter_idx-1]);
					assign quotient[iter_idx] = (remainder[iter_idx-2]) / (remainder[iter_idx-1]);
					assign checkOne = remainder[iter_idx]==1;
					assign checkDone[iter_idx] = (checkDone[iter_idx-1] || level_l[1].if_lv_1.iter_l[iter_idx-1].checkOne);
					assign A[iter_idx] = (checkOne)?1:((checkDone[iter_idx])?0:B[iter_idx+1]);
					assign B[iter_idx] = (checkOne)?(-1*quotient[iter_idx]):((checkDone[iter_idx])?0:(A[iter_idx+1] + B[iter_idx+1] * -1 *quotient[iter_idx]));
				end
			end
		end
		/*
		else if(level_idx==2)begin : if_lv_2
			for(iter_idx2 = 1 ; iter_idx2<=2*WIDTH-1; iter_idx2 =iter_idx2 + 1)begin : iter_l2
				always@(*)begin
					if (checkDone[iter_idx2])begin
						A[iter_idx2] = 1;
						B[iter_idx2] = -1*quotient[iter_idx2];
					end
					else begin
						A[iter_idx2] = B[iter_idx2+1];
						B[iter_idx2] = A[iter_idx2+1] + B[iter_idx2+1] * -1 *quotient[iter_idx2];
					end
				end
			end
		end
		*/
		/*
		else begin
			always@(*)begin
				if(B[1]<=0)begin
					OUT_D<=B[1] + Phi;
				end
				else begin
					OUT_D<=B[1] ;
				end
			end
		end
		*/
	end
endgenerate



endmodule
