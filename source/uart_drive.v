`timescale 1ns / 1ps


module uart_drive(
    sys_clk    ,        
    rst_n      ,                 
    ad_data    ,
    uart_tx     
);
    input           sys_clk     ;            //50mhz
    input           rst_n       ;
 
    input [15:0]    ad_data     ;            //ad7606 采样数据
    wire  [15:0]    ad_ch       ;            //AD??2级连??

    wire  		    wclk  	    ;
    wire  		    rdclk  	    ;
    wire  		    rstclk      ;
	wire  [ 7:0] 	w_st_cur    ;
	wire  [ 7:0] 	w_st_nxt    ;

	output          uart_tx     ;

uart_test uart_test(
    .sys_clk(sys_clk),      //system clock 50Mhz on board
    .rst_n(rst_n),      //reset ,low active
    .handle(rdclk),
    .data(ad_ch),
    .uart_tx(uart_tx)
);

fsm fsm(
    .clock(sys_clk),
    .reset(rst_n),
    .write_cmd(wclk),
    .read_cmd(rdclk),
    .reset_cmd(rstclk),
	.w_st_cur(w_st_cur),    // design for test
    .w_st_nxt(w_st_nxt)
);    

/*
tlm fifo_1(
	.data_in(ad_data), // [15:0]
	.FIFO_w_clk(sys_clk),
	.FIFO_w_en(wclk),
	.FIFO_w_reset(rstclk),
	.FIFO_full(),
	.FIFO_r_clk(sys_clk),
	.FIFO_r_en(rdclk),
	.FIFO_r_reset(rstclk),
	.data_out(ad_ch), //[15:0]
	.FIFO_empty()
);
*/

wnr_fifo wnr_fifo(
  .wr_clk(sys_clk),               // input
  .wr_rst(rstclk),                // input
  .wr_en(wclk),                   // input
  .wr_data(ad_data),              // input [15:0]
  .wr_full(),                     // output
  .almost_full(),                 // output
  .rd_clk(sys_clk),               // input
  .rd_rst(rstclk),                // input
  .rd_en(rdclk),                  // input
  .rd_data(ad_ch),                // output [15:0]
  .rd_empty(),                    // output
  .almost_empty()                 // output
);

endmodule