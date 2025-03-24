module MultCore(
	input	clk, 
	input	[31:0]	A, 
	input	[31:0]	B, 
	input	start, 
	input	sign,

    output	[63:0]	result,
	output	Data_ready,
	output	Busy
    );
/******************************************************************************/

//将有符号乘法的负数转化为相应的正数
wire [31:0] Posi_A = (A[31]&sign)?-A:A,
			Posi_B = (B[31]&sign)?-B:B;

//将被乘数和乘数进行无符号扩展至64位				
wire	[63:0]	A_Ext = {32'b0,Posi_A},
				B_Ext = {32'b0,Posi_B};

//记录有符号乘法中被乘数和乘数的符号位
wire [1:0] Nega;
assign	Nega[1] = (A[31]&sign),
		Nega[0]	= (B[31]&sign);

reg [1:0] Nega_Buf;	//符号缓冲区

/*****************************************************************************/

wire	[63:0]	Wire_0[31:0];

reg		[63:0]	Buf_0[15:0],
				Buf_1[7:0],
				Buf_2[3:0],
				Buf_3[1:0];

wire	[63:0]	Ans_Wire = Buf_3[0] + Buf_3[1];

//被乘数和乘数异号则运算结果转换为其相反数 ; 否则保持不变
assign	result = (^Nega_Buf	?  -Ans_Wire:Ans_Wire);

//assign {Hi,Lo}=C;	//运算结果高32位保存在Hi,低32位保存在Lo

/*******************************************************************************/

reg		[4:0]	T;	//乘法运算进程参考标识

//Busy==0时表示空闲状态,此状态下若执行阶段执行乘法指令,则会将初始数据传入乘法器
//Busy==1表示乘法运算正在进行
assign Busy = T[1];

//Data_ready==0时要么没有进行乘法运算,要么乘法运算正在进行中还没结束
//Data_ready==1时表示一次乘法运算结束,状态持续一个时钟周期
assign	Data_ready = (T[1:0]==2'b01);

/*****************************************************************************/
always @ (posedge clk) begin

	//乘法运算开始时,T赋初值;运算过程每时钟周期右移一位
	T <= start	?	5'b01111 : (T>>1);

	//乘法运算开始时,将被乘数和乘数的符号情况放到缓冲区;其他时候保持值不变
	Nega_Buf <= start ? Nega:Nega_Buf;
end

generate
	genvar i;
	for(i=0;i<32;i=i+1)
	begin:OffsetData
		assign Wire_0[i] = (A_Ext[i]==0) ? 0 : (B_Ext<<i);
	end
	
	for(i=0;i<16;i=i+1)
	begin:Layer_0
		always @ (posedge clk)
			Buf_0[i] <= Wire_0[i] + Wire_0[31-i];
	end
	
	for(i=0;i<8;i=i+1)
	begin:Layer_1
		always @ (posedge clk)
			Buf_1[i] <= Buf_0[i] + Buf_0[15-i];
	end
	
	for(i=0;i<4;i=i+1)
	begin:Layer_2
		always @ (posedge clk)
			Buf_2[i] <= Buf_1[i] + Buf_1[7-i];
	end
	
	for(i=0;i<2;i=i+1)
	begin:Layer_3
		always @ (posedge clk)
			Buf_3[i] <= Buf_2[i] + Buf_2[3-i];
	end
	
endgenerate
	
	
endmodule