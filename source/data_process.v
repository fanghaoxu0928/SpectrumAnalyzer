module data_process(
    input [15:0] ad_data_in,
    output [15:0] ad_data_out
);
    
    assign ad_data_out = ('h7fff - ad_data_in);

endmodule