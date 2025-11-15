module threshold #
(
parameter max_base = 'h7fff,
parameter min_base = 'h0000,
parameter step = 'h05b0
)
(
    input        clk,
    input        rst_n,
    input        button_up,
    input        button_down,
    output       reg [15:0] line

   );

wire up_flag;
wire down_flag;

key_filter
#(
    .CNT_MAX('d999_999) //计数器计数最大值
)
u_1
(
    .sys_clk(clk), 
    .sys_rst_n(rst_n), 
    .key_in(button_up), 
    .key_flag(up_flag) 
);

key_filter
#(
    .CNT_MAX('d999_999) //计数器计数最大值
)
u_2
(
    .sys_clk(clk), 
    .sys_rst_n(rst_n), 
    .key_in(button_down), 
    .key_flag(down_flag) 
);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            line <= min_base;
        else if(up_flag && (line < (max_base - 'd1 - step)))
            line <= line + step;
        else if(down_flag && (line >( min_base + 'd1 + step)))
            line <= line - step;
        else
            line <= line;
    end

endmodule