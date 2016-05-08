`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: ikari_01
//
// Create Date:    23:28:13 02/16/2016
// Design Name:
// Module Name:    n64rgb
// Project Name: n64rgb
// Target Devices: xc9536xl
// Tool versions: Xilinx ISE 14.7
// Description:
//
// Dependencies:
//
// Revision: 2
// Additional Comments: hurr
//
//////////////////////////////////////////////////////////////////////////////////
module n64rgb(
  input [6:0] DI,
  input CLK,
  input nDSYNC,
  output reg [6:0] R_o,
  output reg [6:0] G_o,
  output reg [6:0] B_o,
  output reg nCSYNC,
  output reg nHSYNC,
  output reg nVSYNC,
  output reg nCLAMP
  );

  reg [1:0] cnt;
  reg skip;
  reg [2:0] serrcount; // 240p: 3 hsync per vsync; 480i: 6 serrated hsync per vsync

  always @(negedge CLK) begin
    if(~nDSYNC) begin
      cnt<=2'b00;
      {nVSYNC, nCLAMP, nHSYNC, nCSYNC} <= DI[3:0];
      if(nVSYNC & ~DI[3]) serrcount <= 0;
      if(~nCSYNC & DI[0]) begin
        skip <= 0;
        // count up hsync pulses during vsync pulse
        if(~nVSYNC) serrcount <= serrcount + 1;
      end else skip <= ~skip;
    end else begin
      cnt <= cnt + 1;
      if(serrcount[2] | skip) begin
        case(cnt)
          2'b00: R_o <= DI;
          2'b01: G_o <= DI;
          2'b10: B_o <= DI;
        endcase
      end
    end
  end
endmodule
