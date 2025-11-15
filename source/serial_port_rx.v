module serial_port_rx(
	input    wire        sys_clk    ,
	input    wire        sys_rst_n  ,
	input    wire        rx_data    ,
	
	output    wire       data_value ,
    output    reg        rd_cmd     ,
	output    reg  [7:0] rcv_data
);
 
localparam  IDLE  = 4'b0001,
			START = 4'b0010,
			DATA  = 4'b0100,
			STOP  = 4'b1000;

localparam  CLK_FRE   = 50;      //clock frequency(Mhz)
localparam  BAUD_RATE = 115200;  //serial baud rate
localparam  BAUD_MAX  = CLK_FRE * 1000000 / BAUD_RATE;

reg [4:0] c_state;
reg [4:0] n_state;
reg       rx_data_reg1;
reg       rx_data_reg2;
reg       start_en    ;
reg [12:0]b_cnt ;
reg [3:0] bit_cnt;
reg [7:0] data_reg;
always@ (posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0)
		b_cnt <= 13'd0;
	else if ((c_state == IDLE)||(c_state == STOP))
			b_cnt <= 13'd0;
	else if (((c_state == START)||(c_state == DATA))&&(b_cnt == BAUD_MAX - 1'b1))
			b_cnt <= 13'd0;
	else	
			b_cnt <= b_cnt + 1'b1;
always@ (posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0)
		bit_cnt <= 4'd0;
	else if(c_state == STOP)
			bit_cnt <= 4'd0;
	else if (((c_state == START )||(c_state == DATA))&&(b_cnt == BAUD_MAX -1'b1 ))
			bit_cnt <= bit_cnt + 1'b1;
	else
		bit_cnt <= bit_cnt;
 
always@ (posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0) begin
		rx_data_reg1 <= 1'b0;
	    rx_data_reg2 <= 1'b0;
		end
	else begin
		rx_data_reg1 <= rx_data;
	    rx_data_reg2 <= rx_data_reg1;
		end
		
always@ (posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0)	
		start_en <= 1'b0;
	else if(((c_state == IDLE)&&(rx_data_reg1 == 1'b0) && (rx_data_reg2 ==1'b1)))
		start_en <= 1'b1;
	else
		start_en <= 0;
 
//?????????
always @ (posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		c_state <= IDLE;
	else
		c_state <= n_state;
		
always @ (*) begin
	case (c_state)
		IDLE  :begin
			if(start_en == 1'b1)
				n_state <= START;
			else
				n_state <= IDLE;
		end
	    START :begin
			if((bit_cnt == 0)&&(b_cnt == BAUD_MAX - 1'b1))
				n_state <= DATA;
			else
				n_state <= START;
		end
	    DATA  :begin
			if((bit_cnt == 8)&&(b_cnt == BAUD_MAX - 1'b1))
				n_state <= STOP;
			else
				n_state <= DATA;
		end
	    STOP  :n_state <= IDLE;
		default : n_state <= IDLE;
	endcase
end
 
always @ (posedge sys_clk or negedge sys_rst_n) 	
	if(sys_rst_n == 1'b0)
		data_reg <= 8'd0;
	else begin
		case (c_state)
		IDLE  :data_reg <= 8'd0;
	    START :data_reg <= 8'd0;
	    DATA  :begin
		if(b_cnt == BAUD_MAX >>1 + 1'b1)begin
			case(bit_cnt)
				1: data_reg[0] <= rx_data_reg1;
				2: data_reg[1] <= rx_data_reg1;
				3: data_reg[2] <= rx_data_reg1;
				4: data_reg[3] <= rx_data_reg1;
				5: data_reg[4] <= rx_data_reg1;
				6: data_reg[5] <= rx_data_reg1;
				7: data_reg[6] <= rx_data_reg1;
				8: data_reg[7] <= rx_data_reg1;
				default :;
			endcase	
			end
		else
			data_reg <= data_reg;
		end
	    STOP  :data_reg <= data_reg;
		default : data_reg <= 8'd0;
	endcase	
end

always @ (posedge sys_clk or negedge sys_rst_n) 	
	if(sys_rst_n == 1'b0)	
		rcv_data <= 8'd0;
	else if(c_state == STOP)
		rcv_data <= data_reg;
	
assign data_value = (c_state == STOP)?1'b1:1'b0;

always @ (posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rd_cmd <= 1'b0;
    else
        rd_cmd <= data_value;

endmodule