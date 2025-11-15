module receive (
    input             clk,
    input             rst_n,
    input             rx_data,
    output reg [23:0] freq_threshold
   );

localparam    FACTOR = 'd2025; 

wire         rd_cmd;
wire [7:0] rcv_data;
reg  [7:0] reg_data;

serial_port_rx u_serial_port_rx (
	.sys_clk(clk)      ,
	.sys_rst_n(rst_n)  ,
	.rx_data(rx_data)  ,
	
	.data_value()      ,
    .rd_cmd(rd_cmd)    ,
	.rcv_data(rcv_data)
);

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)
        reg_data <= 'd0;
    else if(rd_cmd)
        reg_data <= rcv_data;
    else
        reg_data <= reg_data;
end

always @(*) begin
    case(reg_data)
        'h00: freq_threshold <= 'd10000;    // 10kHz
        'h01: freq_threshold <= 'd20000;    // 20kHz
        'h02: freq_threshold <= 'd30000;    // 30kHz
        'h03: freq_threshold <= 'd40000;    // 40kHz
        'h04: freq_threshold <= 'd50000;    // 50kHz
        'h05: freq_threshold <= 'd60000;    // 60kHz
        'h06: freq_threshold <= 'd70000;    // 70kHz
        'h07: freq_threshold <= 'd80000;    // 80kHz
        'h08: freq_threshold <= 'd90000;    // 90kHz
        'h09: freq_threshold <= 'd100000;   // 100kHz
        
        // 每增加0x10，频率翻倍
        'h10: freq_threshold <= 'd200000;   // 200kHz
        'h20: freq_threshold <= 'd400000;   // 400kHz
        'h30: freq_threshold <= 'd800000;   // 800kHz
        'h40: freq_threshold <= 'd1000000;  // 1MHz
        'h50: freq_threshold <= 'd1200000;  // 1.2MHz
        'h60: freq_threshold <= 'd1400000;  // 1.4MHz
        'h70: freq_threshold <= 'd1600000;  // 1.6MHz
        'h80: freq_threshold <= 'd1700000;  // 1.7MHz
        'h90: freq_threshold <= 'd1800000;  // 1.8MHz
        'ha0: freq_threshold <= 'd1900000;  // 1.9MHz
        
        // 中间值可以线性递增
        'hb0: freq_threshold <= 'd1920000;
        'hc0: freq_threshold <= 'd1940000;
        'hd0: freq_threshold <= 'd1960000;
        'he0: freq_threshold <= 'd1980000;
        'hf0: freq_threshold <= 'd2000000;  // 2MHz
        
        // 其他值可以按比例分配
        default: freq_threshold <= 'd10000; // 默认值
    endcase
end

endmodule