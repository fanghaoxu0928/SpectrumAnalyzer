module yibiao_1
(
input wire sys_clk , 
input wire sys_rst_n , 
input wire [15:0] ad_data , 
input wire [15:0] ad_data2,
input wire phase_flag,//"1"phase_on"0"phase_off
output reg [23:0] freq,/* synthesis PAP_MARK_DEBUG="true" */
output reg [2:0] peak_int,
output reg [6:0] peak_dec,
output reg [15:0] peak,/* synthesis PAP_MARK_DEBUG="true" */
output reg [7:0] phase_diff,
output reg [6:0] duty_cycle_int,
output reg [3:0] duty_cycle_dec,
output reg [23:0] freq2,/* synthesis PAP_MARK_DEBUG="true" */
output reg [2:0] peak2_int,
output reg [6:0] peak2_dec,
output reg [15:0] peak2,/* synthesis PAP_MARK_DEBUG="true" */
output reg [6:0] duty_cycle2_int,
output reg [3:0] duty_cycle2_dec
);
//********************************************************************//
//******************Parameter And Internal Signal ********************//
//********************************************************************//
//parameter define

wire [15:0] duty_cycle;/* synthesis PAP_MARK_DEBUG="true" */
wire [15:0] duty_cycle2;
parameter DATA_MEDIAN  = 'd 32_767;

parameter HYSTERESIS = 'd 15;  // 滞回阈值(需要后续更改)

reg [15:0] volt_reg ; 
reg [15:0] volt_reg2 ; 

//********************************************************************//
//***************************** Main Code ****************************//
//*******************************************************************//

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
volt_reg <= 'd0;
else if((ad_data > (DATA_MEDIAN -HYSTERESIS )) && (ad_data < (DATA_MEDIAN + HYSTERESIS)))
volt_reg <= 'd0;
else if(ad_data < DATA_MEDIAN) 
volt_reg <= (DATA_MEDIAN - ad_data);
else if(ad_data > DATA_MEDIAN) 
volt_reg <= (ad_data - DATA_MEDIAN);
else
volt_reg <= 'd0;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
volt_reg2 <= 'd0;
else if((ad_data2 > (DATA_MEDIAN -HYSTERESIS )) && (ad_data2 < (DATA_MEDIAN + HYSTERESIS)))
volt_reg2 <= 'd0;
else if(ad_data2 < DATA_MEDIAN) 
volt_reg2 <= (DATA_MEDIAN - ad_data2);
else if(ad_data2 > DATA_MEDIAN) 
volt_reg2 <= (ad_data2 - DATA_MEDIAN);
else
volt_reg2 <= 'd0;


//********************************************************************//
//***************************** More Code ****************************//
//********************************************************************//

reg        trigger   ;/* synthesis PAP_MARK_DEBUG="true" */
reg        trigger2;  /* synthesis PAP_MARK_DEBUG="true" */
reg [15:0] ad_data_prev;    // 第一路AD数据上一时刻值
reg [15:0] ad_data2_prev;   // 第二路AD数据上一时刻值
reg [23:0] time_diff;  /* synthesis PAP_MARK_DEBUG="true" */
reg [7:0] phase_diff_reg; // 相位差寄存器
reg        spy_1     ;
reg        spy_2     ;
reg [15:0] cnt_5    ;
reg [15:0] cnt_5_2    ;


reg [23:0] time_cnt  ;
reg [23:0] time_cnt_diff;
reg [23:0] time_str  ;/* synthesis PAP_MARK_DEBUG="true" */
reg [23:0] time_cnt2  ;
reg [23:0] time_str2  ;
reg [31:0] wait_cnt;

always @ (posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        wait_cnt <= 'd0;
    else if(wait_cnt == 'd59_000_000)
        wait_cnt <= 'd0;
    else
        wait_cnt <= wait_cnt + 'd1;
end

reg [15:0] peak_rec;
reg [15:0] peak_str;
reg [15:0] peak_rec2;
reg [15:0] peak_str2;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
peak_rec <= 'd0;
else if(trigger)
peak_rec <= 'd0;
else if(volt_reg > peak_rec) 
peak_rec <= volt_reg;
else
peak_rec <= peak_rec;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
peak_str <= 'd0;
else if(trigger)
peak_str <= peak_rec;
else
peak_str <= peak_str;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
peak_rec2 <= 'd0;
else if(trigger2)
peak_rec2 <= 'd0;
else if(volt_reg2 > peak_rec2) 
peak_rec2 <= volt_reg2;
else
peak_rec2 <= peak_rec2;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
peak_str2 <= 'd0;
else if(trigger2)
peak_str2 <= peak_rec2;
else
peak_str2 <= peak_str2;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
begin
trigger <= 1'b0;
end
else if(((ad_data_prev<DATA_MEDIAN)&&(ad_data>DATA_MEDIAN)&& (spy_1==0))||((ad_data_prev>DATA_MEDIAN)&&(ad_data<DATA_MEDIAN)&& (spy_1==0)))
begin
trigger <= 1'b1;
end
else
begin
trigger <= 1'b0;
end

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
begin
trigger2<=1'b0;
end
else if(((ad_data2_prev<DATA_MEDIAN)&&(ad_data2>DATA_MEDIAN)&& (spy_2==0))||((ad_data2_prev>DATA_MEDIAN)&&(ad_data2<DATA_MEDIAN)&& (spy_2==0)))
begin
trigger2 <= 1'b1;
end
else
begin
trigger2<=1'b0;
end

always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
        ad_data_prev <= 'd0;
        ad_data2_prev <= 'd0;
    end else begin
        ad_data_prev <= ad_data;    // 延迟一拍保存第一路数据
        ad_data2_prev <= ad_data2;  // 延迟一拍保存第二路数据
    end
end

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
time_cnt_diff <= 'd0;
else if(trigger&&(ad_data_prev>DATA_MEDIAN))
time_cnt_diff <= 'd0;
else
time_cnt_diff <= time_cnt_diff + 'd1;

always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) 

        time_diff <= 'd0;
   else if(trigger2&&(ad_data2_prev>DATA_MEDIAN)) 
        time_diff <= time_cnt_diff;  // 上升沿处记录第二路触发时间
end

always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
        phase_diff_reg <= 'd0;
    end else begin
        if(time_str != 'd0) begin  // avoid divide zero
            phase_diff_reg <= (time_diff * 360) / time_str;
        end else begin
            phase_diff_reg <= 'd0;
        end
    end
end

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
spy_1 <= 1'b0;
else if(((ad_data_prev<DATA_MEDIAN)&&(ad_data>DATA_MEDIAN))||((ad_data_prev>DATA_MEDIAN)&&(ad_data<DATA_MEDIAN)))
spy_1<=1'b1;
else if(cnt_5 > 'd2)
spy_1 <= 1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt_5 <= 'd0;
else if(spy_1)
cnt_5 <= cnt_5 + 'd1;
else if(cnt_5 > 'd2)
cnt_5 <= 'd0;
else
cnt_5<='d0;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
spy_2 <= 1'b0;
else if(((ad_data2_prev<DATA_MEDIAN)&&(ad_data2>DATA_MEDIAN))||((ad_data2_prev>DATA_MEDIAN)&&(ad_data2<DATA_MEDIAN)))
spy_2<=1'b1;
else if(cnt_5_2 > 'd2)
spy_2 <= 1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt_5_2 <= 'd0;
else if(spy_2)
cnt_5_2 <= cnt_5_2 + 'd1;
else if(cnt_5_2 > 'd2)
cnt_5_2 <= 'd0;
else
cnt_5_2<='d0;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
time_cnt <= 'd0;
else if(trigger&&(ad_data_prev>DATA_MEDIAN))
time_cnt <= 'd0;
else
time_cnt <= time_cnt + 'd1;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
time_str <= 'd0;
else if(trigger&&(ad_data_prev>DATA_MEDIAN))
time_str <= time_cnt;
else
time_str <= time_str;//周期

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
time_cnt2 <= 'd0;
else if(trigger2&&(ad_data2_prev>DATA_MEDIAN))
time_cnt2 <= 'd0;
else
time_cnt2 <= time_cnt2 + 'd1;

always@(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
time_str2 <= 'd0;
else if(trigger2&&(ad_data2_prev>DATA_MEDIAN))
time_str2 <= time_cnt2;
else
time_str2 <= time_str2;//周期

reg [23:0]  cnt1_1;
reg [23:0]  cnt2_1;
reg [23:0]  cnt1_2;/* synthesis PAP_MARK_DEBUG="true" */
reg [23:0]  cnt2_2;/* synthesis PAP_MARK_DEBUG="true" */

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt1_1 <= 'd0;
else if(trigger&&(ad_data_prev > DATA_MEDIAN))
cnt1_1 <= 'd0;
else if(ad_data < DATA_MEDIAN) 
cnt1_1 <= cnt1_1 + 'd1;

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt2_1 <= 'd0;
else if(trigger&&(ad_data_prev < DATA_MEDIAN) )
cnt2_1 <= 'd0;
else if(ad_data > DATA_MEDIAN) 
cnt2_1 <= cnt2_1 + 'd1;

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt1_2 <= 'd0;
else if(trigger&&(cnt1_1>0)&&(ad_data_prev > DATA_MEDIAN))
cnt1_2 <= cnt1_1;

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt2_2 <= 'd0;
else if(trigger&&(cnt2_1>0)&&(ad_data_prev < DATA_MEDIAN))
cnt2_2 <= cnt2_1;

assign duty_cycle = (cnt1_2 && cnt2_2) ? (((cnt1_2)*1000)/ (cnt1_2+cnt2_2)): ('d0);

reg [23:0]  cnt3_1;
reg [23:0]  cnt4_1;
reg [23:0]  cnt3_2;
reg [23:0]  cnt4_2;

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt3_1 <= 'd0;
else if(trigger2&&(ad_data2_prev > DATA_MEDIAN))
cnt3_1 <= 'd0;
else if(ad_data2 < DATA_MEDIAN) 
cnt3_1 <= cnt3_1 + 'd1;

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt4_1 <= 'd0;
else if(trigger2&&(ad_data2_prev < DATA_MEDIAN) )
cnt4_1 <= 'd0;
else if(ad_data2 > DATA_MEDIAN) 
cnt4_1 <= cnt4_1 + 'd1;

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt3_2 <= 'd0;
else if(trigger2&&(cnt3_1>0)&&(ad_data2_prev > DATA_MEDIAN))
cnt3_2 <= cnt3_1;

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n == 1'b0)
cnt4_2 <= 'd0;
else if(trigger2&&(cnt4_1>0)&&(ad_data2_prev < DATA_MEDIAN))
cnt4_2 <= cnt4_1;

assign duty_cycle2 = (cnt3_2 && cnt4_2) ? (((cnt3_2)*1000)/ (cnt3_2+cnt4_2)): ('d0);

always @(posedge sys_clk or negedge sys_rst_n)
if(sys_rst_n==1'b0)
begin
phase_diff<='d0;
duty_cycle_int<='d0;
duty_cycle_dec<='d0;
freq<='d0;
peak_dec<='d0;
peak_int<='d0;
freq2<='d0;
peak2_dec<='d0;
peak2_int<='d0;
duty_cycle2_int<='d0;
duty_cycle2_dec<='d0;
end
else if(wait_cnt==0)
begin
phase_diff <=(phase_flag==1)? phase_diff_reg:'d0;
duty_cycle_int<=duty_cycle/10;
duty_cycle_dec<=duty_cycle%10;
freq <= (time_str == 'd0) ? ('d0):(('d29_500_000) / (time_str));
peak <= peak_str;
peak_dec<=((peak*9*100)/131070)%100;
peak_int<=(peak*9)/131070;
freq2 <= (time_str2 == 'd0) ? ('d0):(('d29_500_000) / (time_str2));
peak2 <= peak_str2;
peak2_dec<=((peak2*9*100)/131070)%100;
peak2_int<=(peak2*9)/131070;
duty_cycle2_int<=duty_cycle2/10;
duty_cycle2_dec<=duty_cycle2%10;
end

endmodule