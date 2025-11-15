module LTC_2208(
input                    sys_rst_n    ,
    input                    adc_dci      ,
    input                    adc_dci_2    ,
    input       [15:0] adc_dai      ,
	input       [15:0] adc_dai2      ,
    output reg  [15:0] adc_data,
	output reg  [15:0] adc_data2
);


always @(posedge adc_dci)begin
    if (!sys_rst_n) begin
        adc_data<=0;
	
    end
    else begin
        adc_data <= adc_dai;
		
    end
end

always @(posedge adc_dci_2)begin
    if (!sys_rst_n) begin
        adc_data2<=0;
	
    end
    else begin
        adc_data2 <= adc_dai2;
		
    end
end

endmodule
