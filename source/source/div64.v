module div64(
	input	wire	        	CLK,		    //?????64MHZ
	input	wire				CCLK,		    //???????????128MHz
	input	wire	        	RST_N,      	//????¦Ë
	
	input	wire				Start,			//???????
	input	wire	[63:0]	    iDividend,		//??????
	input   wire	[31:0]	    iDivisor,		//????
	
	output	reg	    [63:0]	    Quotient,		//??
	output	reg	    [31:0]	    Reminder,		//????
	output	reg				    Done		    //???????
	);

//=======================================================
//	REG/WIRE ????
//=======================================================
reg	[6:0]		i;
reg				Sign;			//??????????
reg	[63:0]	    Dividend;	    //?????????????
reg	[96:0]	    Temp_D;
reg	[32:0]	    Temp_S;

//=======================================================
//	??¦Ë??????
//=======================================================
always@(posedge CCLK or negedge RST_N) begin
	if(!RST_N) begin
		i 			= 7'h0;
		Dividend	= 64'h0;
		Sign		= 1'b0;
		Temp_D	= 97'h0;
		Temp_S	= 33'h0;
		Done		= 1'b0;
	end 
    else case( i )
		0:  if(Start) begin							    //???????????§Ø??????????
				if(iDividend[63]) begin
					Sign			= 1'b1;
					Dividend 	= ~iDividend + 1'b1;
				end else begin
					Sign			= 1'b0;
					Dividend 	= iDividend;
				end
				i 			= i + 1'b1;
				Done 		= 1'b0;
			end
	
		1:  begin									    //????????????
				Temp_D 	= {33'h0,Dividend};
				Temp_S	= {1'b0,iDivisor};
				i 			= i + 1'b1;
		    end

		66: begin Done = 1'b1; i = i + 1'b1; end		//???????
		67: begin i = 0; end

		default : begin								    //??¦Ë??????
			Temp_D  = {Temp_D[95:0],1'b0};
			if(Temp_D[96:64] >= Temp_S)
				Temp_D = ({(Temp_D[96:64] - Temp_S),Temp_D[63:0]}) + 1'b1;
			else 
				Temp_D = Temp_D;
			i = i + 1'b1;
	    end
	endcase
end

//??????????
always@(posedge CLK or negedge RST_N) begin
	if(!RST_N) begin
		Quotient <= 64'd0;
		Reminder <= 32'd0;
	end 
    else if(Done) begin
		if(Sign) begin
			Quotient <= ~Temp_D[63:0] + 1'b1;
			Reminder <= ~Temp_D[95:64] + 1'b1;
		end 
        else begin
			Quotient <= Temp_D[63:0];
			Reminder <= Temp_D[95:64];
		end
	end
end

endmodule
