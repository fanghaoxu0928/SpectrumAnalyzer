module uart_test(
    input                        sys_clk	,        //system clock 50Mhz on board
    input                        rst_n		,        //reset ,low active
	input						 handle		,
	input 				  [15:0] data 		,
	output                       uart_tx
);

parameter                        CLK_FRE = 50;//Mhz
localparam                       IDLE =  0;
localparam                       SEND =  1;   
localparam                       WAIT =  2;   //wait 1 second and send uart received data
reg[7:0]                         tx_data;
reg[7:0]                         tx_str;
reg                              tx_data_valid;
wire                             tx_data_ready;
reg[7:0]                         tx_cnt;

reg[3:0]                         state;



always@(posedge sys_clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin

		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 8'd0;
		tx_data_valid <= 1'b0;
	end
	else
	case(state)
		IDLE:
			state <= SEND;
		SEND:
		begin
			tx_data <= tx_str;
			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < 8'd1)//Send 12 bytes data
			begin
				tx_cnt <= tx_cnt + 8'd1; //Send data counter
			end
			else if(tx_data_valid && tx_data_ready)//last byte sent is complete
			begin
				tx_cnt <= 8'd0;
				tx_data_valid <= 1'b0;
				state <= WAIT;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end
		end
		WAIT:
		begin
			if(tx_data_valid && tx_data_ready)
			begin
				tx_data_valid <= 1'b0;
			end
			else if(handle == 1) // wait for 1 second
				state <= SEND;
		end
		default:
			state <= IDLE;
	endcase
end

always@(*)
begin
	case(tx_cnt)
		8'd0 :  tx_str <= data[15:8];
		8'd1 :  tx_str <= data[7:0]; 
		default:tx_str <= 8'd0;
	endcase
end

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(115200)
) uart_tx_inst
(
	.clk                        (sys_clk                  ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);
endmodule