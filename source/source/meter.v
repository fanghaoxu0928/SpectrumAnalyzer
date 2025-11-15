`timescale 1ns/1ps

module meter(
    input clk,
    input rst_n,
    input [15:0] data_in,
    input [15:0] peak,
    output [2:0] result
   );
    wire ad_clk;
    wire cclk;
    wire [63:0] quotient1   ;
    wire done;

    meter_pll pll_0 (
      .clkin1(clk),        // input
      .pll_lock(),    // output
      .clkout0(cclk)       // output
    );

    assign ad_clk = clk;

    parameter CNT_MAX = 'd50_000_000;

    wire [16:0] data_clean;  // 扩展位宽至17位，避免溢出
    assign data_clean = (data_in > 'd32767) ? (data_in - 'd32767) : ('d32767 - data_in);

    //时间单元：关键时间点设置
    reg        rd_flag ;
    reg        vld_flag;

    //存储单元：电压值总和、时长计算
    reg [63:0] time_cnt;
    reg [63:0] dat_pool;
    reg [15:0] peak_rec;

    //计算单元：抓取
    reg [63:0] time_cal;
    reg [63:0] pool_cal;
    reg [15:0] peak_cal;/* synthesis PAP_MARK_DEBUG="true" */
    reg [31:0] sqrt_cal;/* synthesis PAP_MARK_DEBUG="true" */

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            time_cnt <= 'd0;
        else if (time_cnt == CNT_MAX)
            time_cnt <= 'd0; 
        else
            time_cnt <= time_cnt + 'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            dat_pool <= 'd0;
        else if(time_cnt == CNT_MAX)
            dat_pool <= 'd0;
        else
            dat_pool <= dat_pool + data_clean * data_clean ;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            peak_rec <= 'd0;
        else if(time_cnt == CNT_MAX)
            peak_rec <= 'd0;
        else if(data_clean > peak_rec)
            peak_rec <= data_clean;
        else
            peak_rec <= peak_rec;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            rd_flag <= 1'b0;
        else if(time_cnt == CNT_MAX - 'd1)
            rd_flag <= 1'b1;
        else
            rd_flag <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            time_cal <= 'd0;
        else if(rd_flag == 1'b1)
            time_cal <= time_cnt;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            pool_cal <= 'd0;
        else if(rd_flag == 1'b1)
            pool_cal <= dat_pool;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            peak_cal <= 'd0;
        else if(rd_flag == 1'b1)
            peak_cal <= peak_rec;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            vld_flag <= 1'b0;
        else if(rd_flag)
            vld_flag <= 1'b1;
        else
            vld_flag <= 1'b0;
    end

    wire        busy_o      ;
    wire [31:0] sqrt_o      ;
    wire        busy_edge   ;


    div64 u_div64(
	  .CLK(clk),		    //ϵͳʱ��64MHZ
	  .CCLK(cclk),		//��������ʱ��128MHz
	  .RST_N(rst_n),      //ȫ�ָ�λ
	
	  .Start(vld_flag),			//������ʼ
	  .iDividend(pool_cal),		//������
	  .iDivisor(time_cal),		//����
	
	  .Quotient(quotient1),		//��
	  .Reminder(),		//����
	  .Done(done)		        //�������
	);

sqrt #(
    .DW(64) 						//输入数据位宽
)
u_sqrt
(
    .clk(clk),					    //时钟
    .rst_n(rst_n),						//低电平复位，异步复位同步释放
    .din_i(quotient1),				    //开方数据输入
    .din_valid_i(!done),    			//数据输入有效
    .busy_o(busy_o),		    		//sqrt单元繁忙
    .sqrt_o(sqrt_o),	                //开方结果输出
    .rem_o()
);

//检测busy下降边沿

edge_spy u_edge_spy(
      .clk(clk),
	  .rst_n(rst_n),
      .data(busy_o),
		
      .pos_edge(),    //上升沿
	  .neg_edge(busy_edge),    //下降沿  
	  .data_edge(),  //数据边沿
		
	  .D()      
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        sqrt_cal <= 'd0;
    else if(busy_edge)
        sqrt_cal <= sqrt_o;
end

wire [7:0] quotient2;/* synthesis PAP_MARK_DEBUG="true" */

assign quotient2 = (sqrt_cal * 100) / peak;

assign result = (quotient2 >= 75 ? 3'b001 : (quotient2 >= 60) ? 3'b010 : 3'b100);

endmodule