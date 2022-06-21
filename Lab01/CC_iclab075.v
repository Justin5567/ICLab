module CC(
	in_n0,
	in_n1, 
	in_n2, 
	in_n3, 
    in_n4, 
	in_n5, 
	opt,
    equ,
	out_n
);
input [3:0]in_n0;
input [3:0]in_n1;
input [3:0]in_n2;
input [3:0]in_n3;
input [3:0]in_n4;
input [3:0]in_n5;
input [2:0] opt;
input equ;
output [9:0] out_n;
//==================================================================
// reg & wire
//==================================================================

integer i;
integer j;

reg [9:0]out_n;
reg signed [4:0] n [5:0];
reg signed [4:0] n2 [5:0];
reg signed [7:0] temp_val;
reg signed [12:0] temp;

always@(*) begin
	n2[0]=(opt[0])? {in_n0[3],in_n0}:{1'b0,in_n0};
    n2[1]=(opt[0])? {in_n1[3],in_n1}:{1'b0,in_n1};
    n2[2]=(opt[0])? {in_n2[3],in_n2}:{1'b0,in_n2};
    n2[3]=(opt[0])? {in_n3[3],in_n3}:{1'b0,in_n3};
    n2[4]=(opt[0])? {in_n4[3],in_n4}:{1'b0,in_n4};
    n2[5]=(opt[0])? {in_n5[3],in_n5}:{1'b0,in_n5};
	
	if(opt[1])
    begin
	{n[0],n[1],n[2],n[3],n[4],n[5]} = sort_out(n2[0],n2[1],n2[2],n2[3],n2[4],n2[5]);
    end
	else begin
	{n[5],n[4],n[3],n[2],n[1],n[0]} = sort_out(n2[0],n2[1],n2[2],n2[3],n2[4],n2[5]);
    end
	
    if(!opt[2])begin
		n[1]=n[1]-n[0];
        n[3]=n[3]-n[0];
        n[4]=n[4]-n[0];
        n[5]=n[5]-n[0];
        n[0]=0;

    end
	else begin
		n[1]=((n[0]<<1)+n[1])/3;
		n[2]=((n[1]<<1)+n[2])/3;
		n[3]=((n[2]<<1)+n[3])/3;
		n[4]=((n[3]<<1)+n[4])/3;
		n[5]=((n[4]<<1)+n[5])/3;
	end
	temp_val=(equ)?(n[1]-n[0]):(n[4]<<2)+n[3];
	temp = temp_val * n[5];
	
    out_n=(equ==0)? (temp)/3:
                     (temp[12])? ~temp+1:
                        temp;

end


function [29:0] sort_out;
	input signed[4:0] in0, in1, in2, in3, in4, in5;
	reg signed[4:0] out0, out1, out2, out3, out4, out5;
	reg signed[4:0] a[0:3], b[0:2], c[0:3], d[0:2], e[0:5], f[0:3], g[0:1];
	begin
		// group1
		if(in0>in1)begin
			a[0] = in0;
			a[1] = in1;
		end
		else begin
			a[0] = in1;
			a[1] = in0;
		end
		 
		if(a[1]>in2)begin
			a[2] = a[1];
			a[3] = in2;
		end
		else begin
			a[2] = in2;
			a[3] = a[1];
		end
		 
		if(a[0]>a[2])begin
			b[0] = a[0];
			b[1] = a[2];
		end
		else begin
			b[0] = a[2];
			b[1] = a[0];
		end
		b[2] = a[3];	
		// group2
		if(in3>in4)begin
			c[0] = in3;
			c[1] = in4;
		end
		else begin
			c[0] = in4;
			c[1] = in3;
		end
		if(c[1]>in5)begin
			c[2] = c[1];
			c[3] = in5;
		end
		else begin
			c[2] = in5;
			c[3] = c[1];
		end
		if(c[0]>c[2])begin
			d[0] = c[0];
			d[1] = c[2];
		end
		else begin
			d[0] = c[2];
			d[1] = c[0];
		end
		d[2] = c[3];

		// merge group1 and group2 and output head and tail
		if(b[0]>d[0])begin
			e[0] = b[0];
			e[1] = d[0];
		end
		else begin
			e[0] = d[0];
			e[1] = b[0];
		end
		if(b[1]>d[1]) begin
			e[2] = b[1];
			e[3] = d[1];
		end
		else begin
			e[2] = d[1];
			e[3] = b[1];
		end
		if(b[2]>d[2])begin
			e[4] = b[2];
			e[5] = d[2];
		end
		else begin
			e[4] = d[2];
			e[5] = b[2];
		end
		out0 = e[0] ;
		out5 = e[5] ;
		// compare inside value and output head and tail
		if(e[1]>e[2])begin
			f[0] = e[1];
			f[1] = e[2];
		end
		else begin
			f[0] = e[2];
			f[1] = e[1];
		end
		if(e[3]>e[4])begin
			f[2] = e[3];
			f[3] = e[4];
		end
		else begin
			f[2] = e[4];
			f[3] = e[3];
		end
		out1 = f[0] ;
		out4 = f[3] ;
		// compare inside value and output head and tail
		if(f[1]>f[2])begin
			g[0] = f[1];
			g[1] = f[2];
		end
		else begin
			g[0] = f[2];
			g[1] = f[1];
		end
		out2 = g[0] ;
		out3 = g[1] ;	
		 sort_out={out0,out1,out2,out3,out4,out5};
	end
endfunction

endmodule


