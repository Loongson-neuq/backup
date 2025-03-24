module DivCore
(
    input clk,
    input sign,
    input[31:0] A,
    input[31:0] B,
    input       start,
    input       rst,
    

    output                  Data_ready,
    output[63:0]            result,
    output                  Busy
    
);
/**************************************************************************/

//若除数或被除数为负数且为有符号除法,则转换为对应正数
wire[31:0]  Posi_A = (A[31]&sign)?-A:A;
wire[31:0]  Posi_B = (B[31]&sign)?-B:B;

//记录有符号除法中被乘数和乘数的符号位
wire[1:0]   Nega;	//分别表示被除数和除数的符号
assign      Nega[1] = (A[31]&sign),
            Nega[0] = (B[31]&sign);

reg [1:0]   Nega_Buf;	//符号缓冲区

/**************************************************************************/

reg[31:0]   T;  //除法运算进程参考标识

assign      Busy = T[1];    //除法器状态即时量

reg         Busy_Buf;		//状态缓冲区

//由于是非阻塞赋值,所以一个时钟周期开始后,赋值号右边值一起赋给左边,故若赋值结束时除法运算亦结束时,
//Busy会瞬间响应(wire型),值由0变为1;而Busy_Buf(reg型)仍为Busy瞬间响应前的值,等待下一个时钟周期获得新值
//Busy由1突变为0且Busy_Buff仍为1的那个时钟周期即为运算结果准备好的阶段
assign		Data_ready = (Busy_Buf==1'b1 && Busy==1'b0);

/**************************************************************************/

reg [66:0] tmpA,tmpB1,tmpB2,tmpB3;

wire [66:0] sub1 = (tmpA<<2) - tmpB1,
			sub2 = (tmpA<<2) - tmpB2,
			sub3 = (tmpA<<2) - tmpB3;

		//若被除数为负数,则商为暂时结果的相反数
wire[31:0]	Hi = Nega_Buf[1] ? (-tmpA[63:32]):tmpA[63:32],  			
			//若被除数和除数符号不一致,则余为暂时结果的相反数
			Lo = (Nega_Buf[1]^Nega_Buf[0]) ? (-tmpA[31:0]):tmpA[31:0];  
assign result = {Hi,Lo};
/***************************************************************************/

always @ (posedge clk) begin

    if(rst)begin
        T <=0;
        tmpA <= 0;
        tmpB1 <= 0;
        tmpB2 <= 0;
        tmpB3 <= 0;
        Busy_Buf <= 0;
    end
	else if(start) begin
		T <= 32'hffffffff;
		Nega_Buf <= Nega;
		tmpA <= {32'b0,Posi_A};
		tmpB1 <= {Posi_B,32'b0};
		tmpB2 <= {Posi_B,32'b0}+{Posi_B,32'b0};
		tmpB3 <= {Posi_B,33'b0}+{Posi_B,32'b0};

	end
	else if(T[15]&&(tmpA[47:16]<tmpB1[63:32])) begin
		T <= (T>>16);
		tmpA <= (tmpA<<16);
	end
	else if(T[7]&&(tmpA[55:24]<tmpB1[63:32])) begin
		T <= (T>>8);
		tmpA <= (tmpA<<8);
	end
	else if(T[3]&&(tmpA[59:28]<tmpB1[63:32])) begin
		T <= (T>>4);
		tmpA <= (tmpA<<4);
	end
	else if(T[0]) begin
		T <= (T>>2);
		tmpA <= (!sub3[66]) ? sub3 + 3:
				(!sub2[66]) ? sub2 + 2:
				(!sub1[66]) ? sub1 + 1:
										tmpA<<2;
	end
	Busy_Buf <= Busy;
end

endmodule