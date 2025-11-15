module ad_da_hdmi_top(
   input    wire  clk_50M           ,
   input    wire  rst_n             ,
   output   wire  rstn_out          ,
   //HDMI config
   output   wire  iic_tx_scl        ,
   inout    wire  iic_tx_sda        ,
   output   wire  led_int           ,
   //ADDA
   input    wire  [15:0]ad_data_1   ,
   input    wire  [15:0]ad_data_2   ,
   output   wire  ad_clk            ,
   output   wire  ad_clk_2          ,

   input    wire  key_thre_up       ,
   input    wire  key_thre_down     ,
   input    wire  button_phase      ,
   output   wire  led_thre          ,
   output   wire  led_thre_2        ,
   input    wire  uart_rx           ,
   output   wire  uart_tx           ,

   output   wire  vout_hs           ,            
   output   wire  vout_vs           ,            
   output   wire  vout_de           ,            
   output   wire  vout_clk          ,           
   output   wire  [23:0]vout_data           
   );

//wire clk_125M ;
wire lock        ;
wire pll_lock    ;
wire clk_118_8   ;
wire clk_29_7    ;

wire pix_clk           ;
wire [7:0]  hdmi_r_out ; 
wire [7:0]  hdmi_g_out ; 
wire [7:0]  hdmi_b_out ;
wire hdmi_vs_out       ;
wire hdmi_hs_out       ;
wire hdmi_de_out       ;

wire [23:0]  grid_data_out ;
wire grid_vs_out           ;
wire grid_hs_out           ;
wire grid_de_out           ;

assign vout_clk = pix_clk ;

pll_adda u_pll (
  .clkin1(clk_50M),         // input
  .pll_lock(pll_lock),      // output
  .clkout0(clk_118_8),      // output   //118Mhz
  .clkout1(clk_29_7)        // output   //29.5Mhz                                        MODIFIED
);

assign ad_clk = clk_29_7 ;
assign ad_clk_2 = clk_29_7;

//output color bar
hdmi_test  hdmi_color(
   .sys_clk      (clk_50M        ) ,// input system clock 50MHz    
   .rstn_out     (rstn_out       ) ,
   .iic_tx_scl   (iic_tx_scl     ) ,
   .iic_tx_sda   (iic_tx_sda     ) ,
   .led_int      (led_int        ) ,
   .o_pix_clk    (pix_clk        ) ,//pixclk                           
   .vs_out       (hdmi_vs_out    ) , 
   .hs_out       (hdmi_hs_out    ) , 
   .de_out       (hdmi_de_out    ) ,
   .r_out        (hdmi_r_out     ) , 
   .g_out        (hdmi_g_out     ) , 
   .b_out        (hdmi_b_out     ) 
);

wire [15:0]ad_data_1_fil;/* synthesis PAP_MARK_DEBUG="true" */                          //MODIFIED
wire [15:0]ad_data_2_fil;/* synthesis PAP_MARK_DEBUG="true" */

LTC_2208 LTC2208(
    .sys_rst_n      (rst_n                  ), // input  系统复位
    .adc_dci        (ad_clk                 ), // input  ADC输入给FPGA的参考时钟
    .adc_dci_2      (ad_clk_2               ),
    .adc_dai        (ad_data_1              ), // input  ADC输入给FPGA的数据
	.adc_dai2       (ad_data_2              ),
    .adc_data       (ad_data_1_fil          ), // output ADC采样的数据
	.adc_data2      (ad_data_2_fil          )                                           //MODIFIED 
);   

//output grid
grid_display grid_display_1(
	.rst_n      (rst_n      ) ,                              
	.pclk       (pix_clk    ) ,                          
	.i_hs       (hdmi_hs_out) ,                            
	.i_vs       (hdmi_vs_out) ,                           
	.i_de       (hdmi_de_out) ,                          
	.i_data     ({hdmi_r_out[7:0] , hdmi_g_out[7:0] , hdmi_b_out[7:0]}) ,                            
	.o_hs       (grid_hs_out) ,                          
	.o_vs       (grid_vs_out) ,                          
	.o_de       (grid_de_out) ,                          
	.o_data     (grid_data_out)                             
);

wire wave_hs_out            ;
wire wave_vs_out            ;
wire wave_de_out            ;
wire [23:0] wave_data_out   ;
wire [31:0] thd             ;

//output hdmi wave
wav_display wav_display_1(
	.rst_n         (rst_n            ) ,                                      
	.pclk          (pix_clk          ) ,                         
	.wave_color    (24'hff0000       ) ,                         
    .ad_clk        (ad_clk           ) ,                           
	.ad_data_1     (ad_data_1_fil    ) ,                                                     
    .ad_data_2     (ad_data_2_fil    ) ,  
    .thd           (thd              ) ,                      
	.i_hs          (grid_hs_out      ) ,                        
	.i_vs          (grid_vs_out      ) ,                        
	.i_de          (grid_de_out      ) ,                        
	.i_data        (grid_data_out    ) ,                          
	.o_hs          (wave_hs_out      ) ,                        
	.o_vs          (wave_vs_out      ) ,                        
	.o_de          (wave_de_out      ) ,                        
	.o_data        (wave_data_out    )                          
);

wire wave2_hs_out;
wire wave2_vs_out;
wire wave2_de_out;
wire [23:0] wave2_data_out;

char_display #(
    .X_START(240),
    .Y_START(480),
    .X_NUM  (10),
    .Y_NUM  (18)
  )  char_display_0(
	.rst_n      (rst_n      ) ,                              
	.pclk       (pix_clk    ) ,                          
	.i_hs       (wave_hs_out) ,                            
	.i_vs       (wave_vs_out) ,                           
	.i_de       (wave_de_out) ,                          
	.i_data     (wave_data_out) ,
    .i_char_arr({"CHANNEL 1:                                                                                                                                                                CHANNEL 2:"}) ,                            
	.o_hs       (wave2_hs_out) ,                          
	.o_vs       (wave2_vs_out) ,                          
	.o_de       (wave2_de_out) ,                          
	.o_data     (wave2_data_out)
);

reg [9*8-1:0] wavetype;
wire [2:0]cnn_wave;
always @(posedge clk_50M or negedge rst_n)
begin
if(!rst_n)
wavetype<="UNDEFINED";
else if(cnn_wave==3'b100)
wavetype<="TRIANGLE ";
else if(cnn_wave==3'b010)
wavetype<="SINE     ";
else if(cnn_wave==3'b001)
wavetype<="SQUARE   ";
else
wavetype<="UNDEFINED";
end

meter meter_0
(
.clk(ad_clk),
.rst_n(rst_n),
.peak(peak),
.data_in(ad_data_1_fil),
.result(cnn_wave)
);

wire wave3_hs_out;
wire wave3_vs_out;
wire wave3_de_out;
wire [23:0] wave3_data_out;

char_display #(
    .X_START(5),//
    .Y_START(560),//
    .X_NUM  (20),
    .Y_NUM  (3)
  )  char_display_1(
	.rst_n      (rst_n      ) ,                              
	.pclk       (pix_clk    ) ,                          
	.i_hs       (wave2_hs_out) ,                            
	.i_vs       (wave2_vs_out) ,                           
	.i_de       (wave2_de_out) ,                          
	.i_data     (wave2_data_out) ,
    .i_char_arr({"VOLT:",volt2_int_str,".",volt2_dec_str,"V          FREQUENCY:",freq2_str,"HZDUTY CYCLE:",duty2_int_str,".",duty2_dec_str,"%    "}),                            
	.o_hs       (wave3_hs_out) ,                          
	.o_vs       (wave3_vs_out) ,                          
	.o_de       (wave3_de_out) ,                          
	.o_data     (wave3_data_out)
);

wire wave4_hs_out;
wire wave4_vs_out;
wire wave4_de_out;
wire [23:0] wave4_data_out;

char_display #(
    .X_START(464),//
    .Y_START(520),//
    .X_NUM  (70),
    .Y_NUM  (1)
  )  char_display_2(
	.rst_n      (rst_n      ) ,                              
	.pclk       (pix_clk    ) ,                          
	.i_hs       (wave3_hs_out) ,                            
	.i_vs       (wave3_vs_out) ,                           
	.i_de       (wave3_de_out) ,                          
	.i_data     (wave3_data_out) ,
    .i_char_arr({"0   1M   2M  3M   4M  5M  6M   7M  8M  9M  10M  11M 12M  13M 14M  HZ/e"}),                            
	.o_hs       (wave4_hs_out) ,                          
	.o_vs       (wave4_vs_out) ,                          
	.o_de       (wave4_de_out) ,                          
	.o_data     (wave4_data_out)
);

`timescale 1ns / 1ps

uart_drive uart_drive_1(
    .sys_clk(clk_50M)    ,        
    .rst_n(rst_n)      ,                 
    .ad_data(ad_data_1)    ,
    .uart_tx(uart_tx)     
);

wire wave5_hs_out;
wire wave5_vs_out;
wire wave5_de_out;
wire [23:0] wave5_data_out;

char_display #(
    .X_START(420),//
    .Y_START(0),//
    .X_NUM  (3),
    .Y_NUM  (13)
  )  char_display_3(
	.rst_n      (rst_n      ) ,                              
	.pclk       (pix_clk    ) ,                          
	.i_hs       (wave4_hs_out) ,                            
	.i_vs       (wave4_vs_out) ,                           
	.i_de       (wave4_de_out) ,                          
	.i_data     (wave4_data_out) ,
    .i_char_arr({" 1       0.8      0.6      0.4      0.2"}) ,                            
	.o_hs       (wave5_hs_out) ,                          
	.o_vs       (wave5_vs_out) ,                          
	.o_de       (wave5_de_out) ,                          
	.o_data     (wave5_data_out)
);

wire wave6_hs_out;
wire wave6_vs_out;
wire wave6_de_out;
wire [23:0] wave6_data_out;

char_display #(
    .X_START(420),//
    .Y_START(565),//
    .X_NUM  (3),
    .Y_NUM  (13)
  )  char_display_4(
	.rst_n      (rst_n      ) ,                              
	.pclk       (pix_clk    ) ,                          
	.i_hs       (wave5_hs_out) ,                            
	.i_vs       (wave5_vs_out) ,                           
	.i_de       (wave5_de_out) ,                          
	.i_data     (wave5_data_out) ,
    .i_char_arr({" 1       0.8      0.6      0.4      0.2"}) ,                            
	.o_hs       (wave6_hs_out) ,                          
	.o_vs       (wave6_vs_out) ,                          
	.o_de       (wave6_de_out) ,                          
	.o_data     (wave6_data_out)
);

char_display #(
    .X_START(5),//
    .Y_START(5),//
    .X_NUM  (20),
    .Y_NUM  (8)
  )  char_display_5(
	.rst_n      (rst_n      ) ,                              
	.pclk       (pix_clk    ) ,                          
	.i_hs       (wave6_hs_out) ,                            
	.i_vs       (wave6_vs_out) ,                           
	.i_de       (wave6_de_out) ,                          
	.i_data     (wave6_data_out) ,
    .i_char_arr({"FREQ THR:",fre_thre_str,"HZ VOLT THR:",line_int_str,".",line_dec_str,"V      VOLT:",volt_int_str,".",volt_dec_str,"V          FREQUENCY:",freq_str,"HZDUTY CYCLE:",duty_int_str,".",duty_dec_str,"%    PHASE DIFF:",phase_str,"      WAVE TYPE: ",wavetype,"THD:",thd_str,"%            "}) ,                            
	.o_hs       (vout_hs) ,                          
	.o_vs       (vout_vs) ,                          
	.o_de       (vout_de) ,                          
	.o_data     (vout_data)
);

wire[2:0] volt_int;
wire[6:0] volt_dec;
wire[2:0] volt2_int;
wire[6:0] volt2_dec;
wire[15:0] peak;/* synthesis PAP_MARK_DEBUG="true" */
wire[15:0] peak2;
wire[23:0] freq;
wire[23:0] freq2;
wire [23:0] fre_thre;
wire[6:0] duty_cycle_int;
wire[3:0] duty_cycle_dec;
wire[6:0] duty_cycle2_int;
wire[3:0] duty_cycle2_dec;
wire[7:0] phase_diff;

wire[1*8-1:0] volt_int_str;
wire[2*8-1:0] volt_dec_str;
wire[8*8-1:0] freq_str;
wire[1*8-1:0] volt2_int_str;
wire[2*8-1:0] volt2_dec_str;
wire[8*8-1:0] freq2_str;
wire[8*8-1:0] fre_thre_str;
wire[2*8-1:0] duty_int_str;
wire[1*8-1:0] duty_dec_str;
wire[2*8-1:0] duty2_int_str;
wire[1*8-1:0] duty2_dec_str;
wire[3*8-1:0] phase_str;
wire[1*8-1:0] line_int_str;
wire[2*8-1:0] line_dec_str;
wire[3*8-1:0] thd_str;

wire [15:0]line;/* synthesis PAP_MARK_DEBUG="true" */
wire [2:0]line_int;
wire [6:0]line_dec;
assign line_dec=((line*9*100)/131070)%100;
assign line_int=(line*9)/131070;

threshold  #
(.max_base('h7fff),
.min_base('h0000),
.step('h0b50)
)
voltage_threshold (
 .clk(clk_50M),
 .rst_n(rst_n),
 .button_up(key_thre_up),
 .button_down(key_thre_down),
 .line(line)
   );

assign led_thre = (peak >= line) ? 1'b1 : 1'b0;

receive receive (
    .clk(clk_50M),
    .rst_n(rst_n),
    .rx_data(uart_tx),
    .freq_threshold(fre_thre)
);

assign led_thre_2= (freq >= fre_thre) ?1'b1 : 1'b0;

wire flag;
reg phase_flag;/* synthesis PAP_MARK_DEBUG="true" */
key_filter
#(
    .CNT_MAX('d999_999) //计数器计数最大值
)
u_0(
    .sys_clk(clk_50M), 
    .sys_rst_n(rst_n), 
    .key_in(button_phase), 
    .key_flag(flag) 
);

always @(posedge clk_50M or negedge rst_n)
    begin
        if(!rst_n)
            phase_flag <= 1'b0;
        else if(flag&&phase_flag)
            phase_flag <= 1'b0;
        else if(flag&&(!phase_flag))
            phase_flag <= 1'b1;
        else
            phase_flag <= phase_flag;
end

yibiao_1 yibiao_1(
.sys_clk(ad_clk),
.sys_rst_n(rst_n),
.ad_data(ad_data_1_fil),
.ad_data2(ad_data_2_fil),
.phase_flag(phase_flag),
.freq(freq),
.peak_int(volt_int),
.peak_dec(volt_dec),
.peak(peak),
.duty_cycle_int(duty_cycle_int),
.duty_cycle_dec(duty_cycle_dec),
.phase_diff(phase_diff),
.freq2(freq2),
.peak2_int(volt2_int),
.peak2_dec(volt2_dec),
.peak2(peak2),
.duty_cycle2_int(duty_cycle2_int),
.duty_cycle2_dec(duty_cycle2_dec)
);

num2str #(
    .DATA_WIDTH   (3),
    .MAX_NUM      (1),
    .LEADING_ZEROS(1)
  ) u1_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (volt_int),
    .data_out(volt_int_str)
  );
num2str #(
    .DATA_WIDTH   (7),
    .MAX_NUM      (2),
    .LEADING_ZEROS(1)
  ) u2_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (volt_dec),
    .data_out(volt_dec_str)
  );
num2str #(
    .DATA_WIDTH   (24),
    .MAX_NUM      (8),
    .LEADING_ZEROS(1)
  ) u3_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (freq),
    .data_out(freq_str)
  );
num2str #(
    .DATA_WIDTH   (7),
    .MAX_NUM      (2),
    .LEADING_ZEROS(1)
  ) u4_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (duty_cycle_int),
    .data_out(duty_int_str)
  );
num2str #(
    .DATA_WIDTH   (4),
    .MAX_NUM      (1),
    .LEADING_ZEROS(1)
  ) u5_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (duty_cycle_dec),
    .data_out(duty_dec_str)
  );
num2str #(
    .DATA_WIDTH   (8),
    .MAX_NUM      (3),
    .LEADING_ZEROS(1)
  ) u6_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (phase_diff),
    .data_out(phase_str)
  ); 
num2str #(
    .DATA_WIDTH   (3),
    .MAX_NUM      (1),
    .LEADING_ZEROS(1)
  ) u7_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (line_int),
    .data_out(line_int_str)
  ); 
num2str #(
    .DATA_WIDTH   (7),
    .MAX_NUM      (2),
    .LEADING_ZEROS(1)
  ) u8_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (line_dec),
    .data_out(line_dec_str)
  ); 
num2str #(
    .DATA_WIDTH   (24),
    .MAX_NUM      (8),
    .LEADING_ZEROS(1)
  ) u9_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (fre_thre),
    .data_out(fre_thre_str)
  );
num2str #(
    .DATA_WIDTH   (3),
    .MAX_NUM      (1),
    .LEADING_ZEROS(1)
  ) u10_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (volt2_int),
    .data_out(volt2_int_str)
  );
num2str #(
    .DATA_WIDTH   (7),
    .MAX_NUM      (2),
    .LEADING_ZEROS(1)
  ) u11_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (volt2_dec),
    .data_out(volt2_dec_str)
  );
num2str #(
    .DATA_WIDTH   (24),
    .MAX_NUM      (8),
    .LEADING_ZEROS(1)
  ) u12_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (freq2),
    .data_out(freq2_str)
  );
num2str #(
    .DATA_WIDTH   (7),
    .MAX_NUM      (2),
    .LEADING_ZEROS(1)
  ) u13_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (duty_cycle2_int),
    .data_out(duty2_int_str)
  );
num2str #(
    .DATA_WIDTH   (4),
    .MAX_NUM      (1),
    .LEADING_ZEROS(1)
  ) u14_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (duty_cycle2_dec),
    .data_out(duty2_dec_str)
  );
num2str #(
    .DATA_WIDTH   (32),
    .MAX_NUM      (3),
    .LEADING_ZEROS(1)
  ) u15_num2str (
    .clk     (ad_clk),
    .rst_n   (rst_n),
    .data_in (thd),
    .data_out(thd_str)
  );

endmodule