`timescale 1ns/1ns

module fsm(
    input           clock           ,
    input           reset           ,
    output reg      write_cmd       ,
    output reg      read_cmd        ,
    output reg      reset_cmd       ,
    output [7:0]    w_st_cur        ,
    output [7:0]    w_st_nxt
);    
    reg [31:0] r_st_cnt;
    reg [ 7:0] r_st_cur;
    reg [ 7:0] r_st_nxt;

    assign w_st_cur = r_st_cur;
    assign w_st_nxt = r_st_nxt;

    localparam  P_ST_IDLE    = 0 ,
                P_ST_WRITE_1 = 1 ,
/*
                P_ST_WRITE_2 = 2 ,
                P_ST_WRITE_3 = 3 ,
                P_ST_WRITE_4 = 4 ,
                P_ST_WRITE_5 = 5 ,
                P_ST_WRITE_6 = 6 ,
*/
                P_ST_READ_1  = 7 ,
/*
                P_ST_READ_2  = 8 ,
                P_ST_READ_3  = 9 ,
                P_ST_READ_4  = 10,
                P_ST_READ_5  = 11,
*/
                P_ST_RESET   = 12;

    always @(posedge clock or negedge reset) begin
        if(!reset)
            r_st_cur <= P_ST_RESET;
        else
            r_st_cur <= r_st_nxt;
    end

    always @(posedge clock or negedge reset) begin
        if(!reset)
            r_st_cnt <= 'd0;
        else if(r_st_cur != r_st_nxt)
            r_st_cnt <= 'd0;
        else
            r_st_cnt <= r_st_cnt + 'd1;
    end

    // 50MHz clock

    always @(*) begin
        case(r_st_cur)
            P_ST_IDLE   :r_st_nxt <=(r_st_cnt == 'd 3_000_000 ? P_ST_WRITE_1 : P_ST_IDLE    );
            P_ST_WRITE_1:r_st_nxt <=(r_st_cnt == 'd       999 ? P_ST_READ_1  : P_ST_WRITE_1 );
/*
            P_ST_WRITE_2:r_st_nxt <=(r_st_cnt == 'd 6_000_000 ? P_ST_WRITE_3 : P_ST_WRITE_2 );
            P_ST_WRITE_3:r_st_nxt <=(r_st_cnt == 'd 6_000_000 ? P_ST_WRITE_4 : P_ST_WRITE_3 );
            P_ST_WRITE_4:r_st_nxt <=(r_st_cnt == 'd 6_000_000 ? P_ST_WRITE_5 : P_ST_WRITE_4 );
            P_ST_WRITE_5:r_st_nxt <=(r_st_cnt == 'd 6_000_000 ? P_ST_WRITE_6 : P_ST_WRITE_5 );
            P_ST_WRITE_6:r_st_nxt <=(r_st_cnt == 'd 6_000_000 ? P_ST_READ_1  : P_ST_WRITE_6 );
*/
            P_ST_READ_1 :r_st_nxt <=(r_st_cnt == 'd 5_000_000 ? P_ST_RESET   : P_ST_READ_1  );
/*
            P_ST_READ_2 :r_st_nxt <=(r_st_cnt == 'd 3_000_000 ? P_ST_READ_3  : P_ST_READ_2  );
            P_ST_READ_3 :r_st_nxt <=(r_st_cnt == 'd 3_000_000 ? P_ST_READ_4  : P_ST_READ_3  );
            P_ST_READ_4 :r_st_nxt <=(r_st_cnt == 'd 3_000_000 ? P_ST_READ_5  : P_ST_READ_4  );
            P_ST_READ_5 :r_st_nxt <=(r_st_cnt == 'd 3_000_000 ? P_ST_RESET   : P_ST_READ_5  );
*/
            P_ST_RESET  :r_st_nxt <=(r_st_cnt == 'd 5_000_000 ? P_ST_IDLE    : P_ST_RESET   );
            default     :r_st_nxt <= P_ST_RESET;
        endcase
    end

    always @(posedge clock or negedge reset) begin
        if(!reset)
            write_cmd <= 1'b0;
        else if(r_st_cur == P_ST_WRITE_1) /*|| (r_st_cur == P_ST_WRITE_1 && r_st_nxt == P_ST_WRITE_2) || (r_st_cur == P_ST_WRITE_2 && r_st_nxt == P_ST_WRITE_3) || (r_st_cur == P_ST_WRITE_3 && r_st_nxt == P_ST_WRITE_4) || (r_st_cur == P_ST_WRITE_4 && r_st_nxt == P_ST_WRITE_5) || (r_st_cur == P_ST_WRITE_5 && r_st_nxt == P_ST_WRITE_6)*/
            write_cmd <= 1'b1;
        else
            write_cmd <= 1'b0;
    end

    always @(posedge clock or negedge reset) begin
        if(!reset)
            read_cmd <= 1'b0;
        else if((r_st_cur == P_ST_READ_1) && (r_st_cnt >= 'd5000) && (r_st_cnt <= 'd5000000) && (r_st_cnt % 5000 == 'd0)) /*|| (r_st_cur == P_ST_READ_1 && r_st_nxt == P_ST_READ_2) || (r_st_cur == P_ST_READ_2 && r_st_nxt == P_ST_READ_3) || (r_st_cur == P_ST_READ_3 && r_st_nxt == P_ST_READ_4) || (r_st_cur == P_ST_READ_4 && r_st_nxt == P_ST_READ_5)*/
            read_cmd <= 1'b1;
        else
            read_cmd <= 1'b0;
    end

    always @(posedge clock or negedge reset) begin
        if(!reset)
            reset_cmd <= 1'b1;
        else if(r_st_cur == P_ST_RESET)
            reset_cmd <= 1'b1;
        else
            reset_cmd <= 1'b0;
    end
    
endmodule