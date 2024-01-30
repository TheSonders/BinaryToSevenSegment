`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*
MIT License

Copyright (c) 2024 Antonio Sánchez (@TheSonders)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Converting 14-bit binary to decimal for 7 segments and four digits using shift registers
*/
//////////////////////////////////////////////////////////////////////////////////
module Dec7Seg 
	#(parameter CLK_FREQ=20_000_000)(
	input wire CLK,
	input wire [13:0]VALUE,
	output reg Led=0,
	output reg [3:0]AN=0,
	output reg [7:0]SSEG=8'hFF);
	
	localparam Prescaler= (CLK_FREQ/240);
	
	reg [3:0]Digit[0:4];
	
	reg [2:0]DGCounter=0;	//Digits 0 to 4
	reg [3:0]SHCounter=0;	//Shifts 13 to 0
	reg [10:0]Quotient=0;
	reg [26:0]Shift=0;
	
	always @(posedge CLK)begin
		if (SHCounter)begin
			SHCounter<=SHCounter-1;
			if (Shift[26:13]<14'd10)begin
				Quotient<={Quotient[9:0],1'b0};
				Shift<={Shift[25:0],1'b0};
			end
			else begin
				Quotient<={Quotient[9:0],1'b1};
				Shift[26:14]<=(Shift[26:13]-14'd10);
				Shift[13:0]<={Shift[12:0],1'b0};
			end
		end
		else begin
			SHCounter<=14;
			if (DGCounter)begin
				DGCounter<=DGCounter-1;
				Digit[DGCounter-1]<=Shift[17:14];
				Shift<={16'h0,Quotient};
				Quotient<=0;
			end
			else begin
				DGCounter<=5;
				Shift<={13'h0,VALUE};
			end
		end
	end
	
	reg [7:0]Cathode[0:9];
	initial begin
		Cathode[0]=8'b00000011;
		Cathode[1]=8'b10011111;
		Cathode[2]=8'b00100101;
		Cathode[3]=8'b00001101;
		Cathode[4]=8'b10011001;
		Cathode[5]=8'b01001001;
		Cathode[6]=8'b01000001;
		Cathode[7]=8'b00011111;
		Cathode[8]=8'b00000001;
		Cathode[9]=8'b00001001;
	end

	reg [$clog2(Prescaler)-1:0]PRE=0;
	reg [1:0]STM=0;
	reg ZeroFill=0;
	always @(posedge CLK)begin
		if (PRE==0)begin
			PRE<=Prescaler;
			STM<=STM-1;
			case (STM)
				0:begin
					if (Digit[0]) begin
						Led<=1;
						ZeroFill<=1;
					end
					else begin
						Led<=0;
						ZeroFill<=0;
					end
					AN<=4'b1110;
					SSEG<=Cathode[Digit[4]];			//UNITS
				end
				1:begin
					if (Digit[3]!=0 || ZeroFill) begin
						ZeroFill<=1;
						AN<=4'b1101;
						SSEG<=Cathode[Digit[3]];		//TENS
					end
				end
				2:begin
					if (Digit[2]!=0 || ZeroFill) begin
						ZeroFill<=1;
						AN<=4'b1011;
						SSEG<=Cathode[Digit[2]];		//HUNDREDS
					end
				end
				3:begin
					if (Digit[1]!=0 || ZeroFill) begin
						ZeroFill<=1;
						AN<=4'b0111;
						SSEG<=Cathode[Digit[1]];		//THOUSANDS
					end
				end
			endcase
		end
		else begin
			PRE<=PRE-1;
		end
	end
endmodule
