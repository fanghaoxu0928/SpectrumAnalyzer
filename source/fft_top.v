module fft_top (
    input           i_aclk,         // 时钟信号
    input           i_aresetn,      // 异步复位（低有效）
    input  [15:0]   i_real_data,    // 输入实部（8位）
    input           i_data_valid,   // 输入数据有效
    input           i_data_last,    // 输入数据帧结束（1024点最后一个数据）
    output [63:0]   o_fft_data,     // FFT输出数据（48位：实部24位+虚部24位）
    output          o_fft_valid,    // FFT输出有效
    output          o_fft_last,     // FFT输出帧结束
    output [23:0]   o_fft_user,     // FFT用户信号（通常为频谱索引）
    output [2:0]    o_alm,          // 告警信号
    output          o_stat          // 状态信号
);

// ------------------------------------------------------
// 信号格式转换：8位实部 + 8位虚部（补0）→ 16位AXI4S数据
// ------------------------------------------------------
reg [31:0] axi4s_data_tdata;
reg        axi4s_data_tvalid;
reg        axi4s_data_tlast;

always @(posedge i_aclk or negedge i_aresetn) begin
    if (!i_aresetn) begin
        axi4s_data_tdata  <= 32'd0;
        axi4s_data_tvalid <= 1'b0;
        axi4s_data_tlast  <= 1'b0;
    end else begin
        // 虚部补0，实部扩展到8位（输入已为8位，直接拼接）
        axi4s_data_tdata  <= {16'd0, i_real_data};  // [31:16]虚部=0，[15:0]实部=输入
        axi4s_data_tvalid <= i_data_valid;          // 传递输入有效信号
        axi4s_data_tlast  <= i_data_last;           // 传递帧结束信号
    end
end

// ------------------------------------------------------
// 实例化1024点FFT IP核（根据IP生成的模板修改）
// ------------------------------------------------------
fft u_fft (
    .i_axi4s_data_tdata  (axi4s_data_tdata),   // 输入数据：16位（虚部8位+实部8位）
    .i_axi4s_data_tvalid (axi4s_data_tvalid),  // 输入有效
    .i_axi4s_data_tlast  (axi4s_data_tlast),   // 输入帧结束
    .o_axi4s_data_tready (),                   // 输出就绪（未使用，假设始终就绪）
    .i_axi4s_cfg_tdata   ( 'd0),               // 配置数据（默认0，使用IP核默认配置）
    .i_axi4s_cfg_tvalid  (1'b0),               // 配置有效（默认0，不动态配置）
    .i_aclk              (i_aclk),             // 时钟
    .o_axi4s_data_tdata  (o_fft_data),         // 输出数据：48位（虚部24位+实部24位）
    .o_axi4s_data_tvalid (o_fft_valid),        // 输出有效
    .o_axi4s_data_tlast  (o_fft_last),         // 输出帧结束
    .o_axi4s_data_tuser  (o_fft_user),         // 输出索引（0~1023）
    .o_alm               (o_alm),              // 告警
    .o_stat              (o_stat)              // 状态
);

endmodule