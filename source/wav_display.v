module wav_display(
	input                       rst_n,   
	input                       pclk,
	input[23:0]                 wave_color,
    input                       ad_clk ,
	input[15:0]                 ad_data_1,
    input[15:0]                 ad_data_2,
    output[31:0]                thd/* synthesis PAP_MARK_DEBUG="true" */,
	input                       i_hs,    
	input                       i_vs,    
	input                       i_de,	
	input[23:0]                 i_data,  
	output                      o_hs/* synthesis PAP_MARK_DEBUG="true" */,    
	output                      o_vs/* synthesis PAP_MARK_DEBUG="true" */,    
	output                      o_de/* synthesis PAP_MARK_DEBUG="true" */,    
	output[23:0]                o_data/* synthesis PAP_MARK_DEBUG="true" */
);

wire       chnl;
wire[15:0] ad_data_in;

wire[11:0] pos_x;
wire[11:0] pos_y;
wire       pos_hs;
wire       pos_vs;
wire       pos_de;
wire[23:0] pos_data;
reg [23:0] v_data;

reg [ 9:0] rdaddress_1;
reg [ 9:0] rdaddress_2;
wire[31:0] out_1;
wire[31:0] out_2;
reg        region_active_1;
reg        region_active_2;

assign o_data = v_data;
assign o_hs = pos_hs;
assign o_vs = pos_vs;
assign o_de = pos_de;

always@(posedge pclk)
begin
	if(pos_y >= 12'd1 && pos_y <= 12'd513 && pos_x >= 12'd480 && pos_x <= 12'd1509)
		region_active_1 <= 1'b1;
	else
		region_active_1 <= 1'b0;
end

always@(posedge pclk)
begin
	if(pos_y >= 12'd567 && pos_y <= 12'd1079 && pos_x >= 12'd480 && pos_x <= 12'd1509)
		region_active_2 <= 1'b1;
	else
		region_active_2 <= 1'b0;
end

always@(posedge pclk)
begin
	if(region_active_1 == 1'b1 && pos_de == 1'b1)
		rdaddress_1 <= rdaddress_1 + 'd1;
	else
		rdaddress_1 <= 'd0;
end

always@(posedge pclk)
begin
	if(region_active_2 == 1'b1 && pos_de == 1'b1)
		rdaddress_2 <= rdaddress_2 + 'd1;
	else
		rdaddress_2 <= 'd0;
end

always@(posedge pclk)
begin
	if((region_active_1 == 1'b1 && (12'd513 - pos_y) <= (out_1[25:17])) || (region_active_2 == 1'b1 && (12'd1079 - pos_y) <= (out_2[25:17])))	
		v_data <= wave_color;
    else
        v_data <= pos_data;
end

//fft处理部分

wire [15:0] data_1;
wire [15:0] data_2;

data_process chnl1(
    .ad_data_in(ad_data_1),
    .ad_data_out(data_1)
);

data_process chnl2(
    .ad_data_in(ad_data_2),
    .ad_data_out(data_2)
);

reg  [23:0] cnt         ;
reg         i_valid     ;
reg         i_last      ;

always @ (posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= 'd0;
    else if(cnt == 'd2_950_000)
        cnt <= 'd0;
    else
        cnt <= cnt + 'd1;
end

always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        i_valid <= 1'b0;
    else if(cnt == 'd5 || cnt == 'd500005)
        i_valid <= 1'b1;
    else if(cnt == 'd2053 || cnt == 'd502053)
        i_valid <= 'd0;
    else
        i_valid <= i_valid;
end

always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        i_last <= 1'b0;        
    else if(cnt == 'd2052 || cnt == 'd502052)
        i_last <= 1'b1;
    else
        i_last <= 1'b0;
end

assign chnl = (cnt <= 'd500000) ? 1'b1 : 1'b0 ;
assign ad_data_in = chnl ? data_1 : data_2 ;

wire [63:0] fft_data_1  ;
wire [63:0] fft_data_2  ;
wire        o_valid     ;
wire        o_last      ;

fft_process u_fft_process (   //时序调整基本完毕
  .clk        (ad_clk    ),   //采样时钟
  .rst_n      (rst_n     ),   //重置
  .ad_data_in (ad_data_in),   //采集信号数据
  .i_valid    (i_valid   ),
  .i_last     (i_last    ),
  .o_fft_data (fft_data_1),   //输出幅频数据
  .o_valid    (o_valid   ),   //已经经过延迟
  .o_last     (o_last    )
);

wire         wr_cmd      ;
reg          rd_cmd      ;
wire         full        ;
wire         empty       ;

assign wr_cmd = o_valid; //写入侧逻辑

always @ (posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        rd_cmd <= 1'b0;
    else if(((cnt > 'd50000) && (cnt < 459800) && !(cnt % 'd200)) || ((cnt > 'd550000) && (cnt < 959800) && !(cnt % 'd200))) //每组开根处理分配200个时钟周期裕量
        rd_cmd <= 1'b1;
    else
        rd_cmd <= 1'b0;
end

fft_fifo u_fft_fifo (
  .clk(ad_clk),                   // input
  .rst(~rst_n),                   // input
  .wr_en(wr_cmd),                 // input
  .wr_data(fft_data_1),           // input [63:0]
  .wr_full(full),                 // output
  .almost_full(),                 // 空置
  .rd_en(rd_cmd),                 // input
  .rd_data(fft_data_2),           // output [63:0]
  .rd_empty(empty),               // output
  .almost_empty()                 // 空置
);

wire [47:0]  sqrt_data   ;
wire         busy_data   ;
wire         busy_edge   ;

sqrt #(
    .DW(64) 						//输入数据位宽
)
u_sqrt
(
    .clk(ad_clk),					    //时钟
    .rst_n(rst_n),						//低电平复位，异步复位同步释放
    .din_i(fft_data_2),				    //开方数据输入
    .din_valid_i(rd_cmd),    			//数据输入有效
    .busy_o(busy_data),		    		//sqrt单元繁忙
    .sqrt_o(sqrt_data),	                //开方结果输出
    .rem_o()				            //空置
);

//检测busy下降边沿

edge_spy u_edge_spy(
      .clk(ad_clk),
	  .rst_n(rst_n),
      .data(busy_data),
		
      .pos_edge(),    //上升沿
	  .neg_edge(busy_edge),    //下降沿  
	  .data_edge(),  //数据边沿
		
	  .D()      
);

wire [31:0]  magnitude_1 ;
wire [31:0]  magnitude_2 ;
wire busy_edge_1;
wire busy_edge_2;
reg [10:0] wr_addr_1;
reg [10:0] wr_addr_2;

assign magnitude_1 = chnl ? sqrt_data[31:0] : 'd0;
assign magnitude_2 = chnl ? 'd0 : sqrt_data[31:0];
assign busy_edge_1 = chnl ? busy_edge : 1'b0;
assign busy_edge_2 = chnl ? 1'b0 : busy_edge;

always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        wr_addr_1 <= 'd0;
    else if(wr_addr_1 == 'd2047 && busy_edge_1)
        wr_addr_1 <= 'd0;
    else if(busy_edge)
        wr_addr_1 <= wr_addr_1 + 'd1;        
end

always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        wr_addr_2 <= 'd0;
    else if(wr_addr_2 == 'd2047 && busy_edge_2)
        wr_addr_2 <= 'd0;
    else if(busy_edge)
        wr_addr_2 <= wr_addr_2 + 'd1;        
end

reg [10:0] thd_adrs;
wire thd_valid;
wire thd_last;
wire [31:0] thd_data;

always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        thd_adrs <= 'd0;
    else if(cnt >= 'd460000 && cnt <= 'd461022)
        thd_adrs <= thd_adrs + 'd1;
    else
        thd_adrs <= 'd0;
end

assign thd_valid = (cnt >= 'd460000 && cnt <= 'd461023) ? 1'b1 : 1'b0;
assign thd_last = (cnt == 'd461023) ? 1'b1 : 1'b0;

thd_ram ram_0 (
  .wr_data(magnitude_1),    // input [31:0]
  .wr_addr(wr_addr_1),    // input [10:0]
  .wr_en(busy_edge_1),        // input
  .wr_clk(ad_clk),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(thd_adrs),    // input [10:0]
  .rd_data(thd_data),    // output [31:0]
  .rd_clk(ad_clk),      // input
  .rd_rst(~rst_n)       // input
);

fft_ram ram_1 (
  .wr_data(magnitude_1),        // input [31:0]
  .wr_addr(wr_addr_1),          // input [9:0]
  .wr_en(busy_edge_1),          // input 
  .wr_clk(ad_clk),            // input
  .wr_rst(~rst_n),            // input
  .rd_addr(rdaddress_1[9:0]),   // input [9:0]
  .rd_data(out_1),            // output [31:0]
  .rd_clk(pclk),              // input
  .rd_rst(~rst_n)             // input
);

fft_ram ram_2 (
  .wr_data(magnitude_2),        // input [31:0]
  .wr_addr(wr_addr_2),          // input [9:0]
  .wr_en(busy_edge_2),          // input 
  .wr_clk(ad_clk),            // input
  .wr_rst(~rst_n),            // input
  .rd_addr(rdaddress_2[9:0]),   // input [9:0]
  .rd_data(out_2),            // output [31:0]
  .rd_clk(pclk),              // input
  .rd_rst(~rst_n)             // input
);

timing_gen_xy timing_gen_xy_m0(
	.rst_n    (rst_n    ),
	.clk      (pclk     ),
	.i_hs     (i_hs     ),
	.i_vs     (i_vs     ),
	.i_de     (i_de     ),
	.i_data   (i_data   ),
	.o_hs     (pos_hs   ),
	.o_vs     (pos_vs   ),
	.o_de     (pos_de   ),
	.o_data   (pos_data ),
	.x        (pos_x    ),
	.y        (pos_y    )
);

thd u_thd(
    .clk(ad_clk),
    .rst_n(rst_n),
    .wdata(thd_data[24:16]),
    .wvalid(thd_valid),
    .wlast(thd_last),
    .thd(thd) 
);
 
endmodule