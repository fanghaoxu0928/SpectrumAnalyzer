module fft_process (
    input              clk        ,
    input              rst_n      ,
 
    // 外部数据接口
    input      [15:0]  ad_data_in ,   //写信号数据
    input              i_valid    ,
    input              i_last     ,
    output     [63:0]  o_fft_data ,   //输出幅频数据
    output reg         o_valid    ,
    output reg         o_last
   );

wire         w_o_valid     ;
wire         w_o_last      ;

wire [63:0]  magnitude_raw ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        o_valid <= 1'b0;
    else
        o_valid <= w_o_valid;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        o_last <= 1'b0;
    else
        o_last <= w_o_last;
end

fft_top u_fft_top (
    .i_aclk         (clk            ),
    .i_aresetn      (rst_n          ),
    .i_real_data    (ad_data_in     ),
    .i_data_valid   (i_valid        ),
    .i_data_last    (i_last         ),
    .o_fft_data     (magnitude_raw  ),
    .o_fft_valid    (w_o_valid      ),
    .o_fft_last     (w_o_last       ),
    .o_fft_user     (               ),
    .o_alm          (               ),
    .o_stat         (               )
);

square u_square(
    .clk(clk),
    .rst_n(rst_n),
    .source_real(magnitude_raw[31:0]),
    .source_imag(magnitude_raw[63:32]),
    .source_data(o_fft_data)
);

endmodule