`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ikari_01
// 
// Create Date:    23:28:13 02/16/2016 
// Design Name: 
// Module Name:    n64rgb_buffered
// Project Name: n64rgb
// Target Devices: xc9572xl
// Tool versions: Xilinx ISE 14.7
// Description: 
//
// Dependencies: 
//
// Revision: 3 (interlaced + pal/ntsc detect)
// Additional Comments: BUFFERED version (no color shifting around edges)
//
//////////////////////////////////////////////////////////////////////////////////
module n64rgb_buffered(
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

  reg [6:0] R_i;
  reg [6:0] G_i;
  reg [6:0] B_i;

  reg [1:0] cnt;
  reg skip;
  reg [2:0] serrcount; // 240p: 3 hsync per vsync; 480i: 6 serrated hsync per vsync
  reg [1:0] linecount; // PAL: Linecount[1:0] = 01; NTSC: Linecount[1:0] = 11
  reg vmode;

  always @(negedge CLK) begin
    if(~nDSYNC) begin
      cnt<=2'b00;
      {nVSYNC, nCLAMP, nHSYNC, nCSYNC} <= DI[3:0];
      if(~nVSYNC & DI[3]) begin
        vmode <= linecount[1];
        linecount <= 0;
      end
      if(~nHSYNC & DI[1]) linecount <= linecount + 1;
      if(nVSYNC & ~DI[3]) serrcount <= 0;
      if(~nCSYNC & DI[0]) begin
        skip <= 0;
        // count up hsync pulses during vsync pulse
        if(~nVSYNC) serrcount <= serrcount + 1;
      end else skip <= ~skip;
      R_o <= R_i;
      G_o <= G_i;
      B_o <= B_i;
    end else begin
      cnt <= cnt + 1;
      if(serrcount[2] | (skip ^ ~vmode)) begin
        case(cnt)
          2'b00: R_i <= DI;
          2'b01: G_i <= DI;
          2'b10: B_i <= DI;
        endcase
      end
    end
  end
endmodule
