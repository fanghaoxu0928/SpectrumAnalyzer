module thd(
    input clk,
    input rst_n,
    input [8:0] wdata,
    input wvalid,
    input wlast,
    output [31:0] thd 
);

    parameter DIFF = 'd8;

    wire       peak_rec;
    wire [15:0]sqrt_result;
    wire       busy_o  ;
    reg [ 9:0] peak_cnt;
    reg [ 8:0] peak_reg;
    reg        peak_valid;
    reg [31:0] sum;
    reg [ 8:0] wdata_d1;
    reg [ 8:0] wdata_d2;
    reg        wlast_d1;
    reg        base_flag;
    reg [31:0] r_thd;
    reg [ 8:0] data_base;
    reg        out_flag ;

    assign thd = r_thd ;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_flag <= 'd0 ;
        end
        else if(wlast) begin
            base_flag <= 'd0 ;
        end else if (peak_valid) begin
            base_flag <= 'd1 ;
        end
        else begin
            base_flag <= base_flag ;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_base <= 'd0;
        end
        else if (!base_flag&&peak_valid) begin
            data_base <= peak_reg;
        end
        else begin
            data_base <= data_base;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wdata_d1 <= 'd0;
            wdata_d2 <= 'd0;
        end else begin
            wdata_d1 <= wdata;
            wdata_d2 <= wdata_d1; 
        end    
    end

    reg cur_state;
    reg nxt_state;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cur_state <= 1'b0;
        else
            cur_state <= nxt_state;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
           nxt_state <= 1'b0;
        else
            case(nxt_state)
                1'b0:
                    if((wdata_d1 + DIFF < wdata) && (wdata_d1 > 'd8) && (wdata > 'd8))
                        nxt_state <= 1'b1;
                    else
                        nxt_state <= nxt_state;
                1'b1:
                    if((wdata_d1 - DIFF > wdata) && (wdata_d1 > 'd8) && (wdata > 'd8)) //平带状况
                        nxt_state <= 1'b0;
                    else
                        nxt_state <= nxt_state; 
                default:nxt_state <= 1'b0;
            endcase     
    end

    assign peak_rec = (cur_state && !nxt_state) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            peak_cnt <= 'd0;
        else if(peak_rec)
            peak_cnt <= peak_cnt + 'd1;
        else if(!wvalid)
            peak_cnt <= 'd0;
        else
            peak_cnt <= peak_cnt;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            peak_reg <= 'd0;
        else if(peak_rec)
            peak_reg <= wdata_d2;
        else
            peak_reg <= 'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            peak_valid <= 1'b0;
        else if(peak_rec)
            peak_valid <= 1'b1;
        else
            peak_valid <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            sum <= 'd0;
        else if(peak_valid&&base_flag)
            sum <= sum + peak_reg * peak_reg;
        else if(!wvalid)
            sum <= 'd0;
        else
            sum <= sum;
    end 

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            wlast_d1 <= 1'b0;
        else
            wlast_d1 <= wlast;
    end

sqrt #(
    .DW(32) 						    //输入数据位宽
) u_sqrt (
    .clk(clk),							//时钟
    .rst_n(rst_n),						//低电平复位，异步复位同步释放
    .din_i(sum),				        //开方数据输入
    .din_valid_i(wlast_d1),        	    //数据输入有效
    .busy_o(busy_o),	    		    //sqrt单元繁忙
    .sqrt_o(sqrt_result),               //开方结果输出
    .rem_o()        			        //开方余数输出
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_flag <= 'd0;
    end
    else if (busy_o) begin
        out_flag <= 'd1;
    end
    else begin
        out_flag <= out_flag;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_thd <= 'd0 ;
    end
    else if (!busy_o&&out_flag) begin
        r_thd <= sqrt_result * 100 / data_base;
    end
    else begin
        r_thd <= r_thd ;
    end
end

endmodule