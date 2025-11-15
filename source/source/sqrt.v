module sqrt #(
    parameter DW = 64 						//输入数据位宽
)(
    input wire clk,							//时钟
    input wire rst_n,						//低电平复位，异步复位同步释放

    input wire [DW-1:0] din_i,				//开方数据输入
    input wire din_valid_i,					//数据输入有效

    output wire busy_o,						//sqrt单元繁忙

    output wire [(DW+(DW%2))/2-1:0] sqrt_o,	//开方结果输出
    output wire [DW-2:0] rem_o				//开方余数输出
);
//数据输入位宽，向上扩展到偶数
localparam din_width = DW + (DW%2);
//迭代次数
localparam iteration_number = din_width/2;
//迭代计数器位宽
localparam icnt_width = clogb2(iteration_number);
//开方结果位宽
localparam sqrt_width = iteration_number;

//开方数据输入寄存器
reg [din_width-1:0]din_reg;
//迭代计数器
reg [icnt_width-1:0]icnt;
//开方状态寄存器，1;计算中，0:等待
reg sqrt_en;
//开方结果寄存器
reg [sqrt_width-1:0]sqrt_data;
//开方余数/部分余数寄存器
reg [DW-2:0]rem_data;

//结果左移2位+1
wire [DW:0]sqrt_l2a1 = {sqrt_data, 2'b01};
//部分余数与下个2位合成
wire [DW:0]rem_a2b = {rem_data, din_reg[din_width-1:din_width-2]};
//比较
wire rem_cmp = (rem_a2b>=sqrt_l2a1) ? 1'b1 : 1'b0;
//下一个部分余数
wire [DW-2:0]rem_next = rem_cmp ? (rem_a2b-sqrt_l2a1) : rem_a2b;
//下一个部分结果
wire sqrt_next = rem_cmp;


//状态控制
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sqrt_en <= 1'b0;
        icnt <= iteration_number-1;
    end
    else begin
        case (sqrt_en)
            1'b0 : begin//等待中
                if (din_valid_i) begin//输入有效
                    sqrt_en <= 1'b1;
                    icnt <= iteration_number-1;
                    din_reg <= {{(DW%2){1'b0}}, din_i};//输入数据扩展到偶数
                    sqrt_data <= 0;
                    rem_data <= 0;
                end
            end
            1'b1 : begin//迭代中
                icnt <= icnt-1;
                din_reg <= {din_reg[din_width-3:0], 2'b00};
                sqrt_data <= {sqrt_data[sqrt_width-2:0], sqrt_next};
                rem_data <= rem_next;
                if (icnt==0) begin//结束迭代
                    sqrt_en <= 1'b0;
                end
            end
        endcase
    end
end

assign busy_o = sqrt_en;

assign sqrt_o = sqrt_data;
assign rem_o = rem_data;

//计算log2
function integer clogb2;
    input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
            depth = depth >> 1;
endfunction
endmodule