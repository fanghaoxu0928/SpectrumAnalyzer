`timescale 1ns/1ps

module tb_ad_da_hdmi_top();

wire GRS_N;

GTP_GRS GRS_INST (
    .GRS_N(1'b1)
);

reg         clk_50M;
reg         rst_n;
reg [15:0]  ad_data_in;

wire        rstn_out;
wire        iic_tx_scl;
wire        iic_tx_sda;
wire        led_int;
wire        ad_clk;
wire        vout_hs;
wire        vout_vs;
wire        vout_de;
wire        vout_clk;
wire [23:0] vout_data;

reg [31:0]  sin_cnt;      
real        sin_value;    
parameter   SIN_AMPLITUDE = 32767.0;  
parameter   SIN_FREQ = 5_000_000;      
parameter   SAMPLE_FREQ = 29_700_000; 

ad_da_hdmi_top u_ad_da_hdmi_top(
    .clk_50M      (clk_50M),
    .rst_n        (rst_n),
    .rstn_out     (rstn_out),
    .iic_tx_scl   (iic_tx_scl),
    .iic_tx_sda   (iic_tx_sda),
    .led_int      (led_int),
    .ad_data_1    (ad_data_in),
    .ad_data_2    (ad_data_in),
    .ad_clk       (ad_clk),
    .ad_clk       (),
    .key_thre_up(),
    .key_thre_down(),
    .button_phase(),
    .led_thre(),
    .led_thre_2(),
    .uatx(),

    .vout_hs      (vout_hs),
    .vout_vs      (vout_vs),
    .vout_de      (vout_de),
    .vout_clk     (vout_clk),
    .vout_data    (vout_data)
);

initial begin
    clk_50M = 1'b0;
    forever #10 clk_50M = ~clk_50M;  
end

initial begin
    rst_n = 1'b0;
    #1000;        
    rst_n = 1'b1;
end

always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n) begin
        sin_cnt <= 32'd0;
        ad_data_in <= 16'd0;
    end
    else begin
        sin_cnt <= sin_cnt + 32'd1;
        sin_value = SIN_AMPLITUDE * $sin(2 * 3.1415926 * SIN_FREQ * sin_cnt / SAMPLE_FREQ);
        ad_data_in <= $rtoi(sin_value + SIN_AMPLITUDE);  
    end
end

initial begin
    ad_data_in = 16'd0;
    #10_000_000;
    $stop;
end

initial begin
    $dumpfile("ad_da_hdmi_top.vcd");
    $dumpvars(0, tb_ad_da_hdmi_top);
end

endmodule