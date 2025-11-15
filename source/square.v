module square(
    input                clk,
    input                rst_n,
    input      [31:0]    source_real,
    input      [31:0]    source_imag,
    output reg [63:0]    source_data
);
    
    // delay for 1 clock

    reg [31:0] data_real;
    reg [31:0] data_imag;

    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            source_data <= 64'd0;
            data_real   <= 32'd0;
            data_imag   <= 32'd0;
        end
        else begin
            if(!source_real[31]) begin               //由补码计算原码
                data_real <= source_real;
            end else begin
                data_real <= ~source_real + 1'b1;
            end

            if(!source_imag[31]) begin               //由补码计算原码
                data_imag <= source_imag;
            end else begin
                data_imag <= ~source_imag + 1'b1;            
            end                                        //计算原码平方和
            source_data <= (data_real * data_real) + (data_imag * data_imag);
        end
    end

endmodule