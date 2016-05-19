//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: ikari_01, borti4938
//
// Create Date:    23:28:13 02/16/2016
// Design Name:
// Module Name:    n64rgb
// Project Name:   n64rgb
// Target Devices: xc9572xl
// Tool versions:  Xilinx ISE 14.7, Altera Quartus Prime
// Description:
//
// Dependencies:
//
// Revision: 3 (interlaced + pal/ntsc detect)
// Additional Comments: BUFFERED version (no color shifting around edges)
//                      deactivation of de-blur if wanted (MAXII devices only)
//////////////////////////////////////////////////////////////////////////////////

`define USE_MAXII     // comment this line if Xilinx XC95##XL devices are used
`define USE_BUFFERED  // comment this line at least if XC9536XL is used (otherwise it is recommended to leave that line uncommented)

module n64rgb (
  input nCLK,
  input nDSYNC,
  input [6:0] DI,
`ifdef USE_MAXII
  input DF_FEAT, // feature to disable the dither filter (0 = feature off, 1 = feature on)
                 // (pin can be left unconnected; weak pull-up assigned)
`endif
  output nVSYNC,
  output nCLAMP,
  output nHSYNC,
  output nCSYNC,
  output [6:0] R_o,     // red data vector
  output [6:0] G_o,     // green data vector
  output [6:0] B_o      // blue data vector
);

`ifdef USE_BUFFERED
  localparam BUF_SIZE = 2; // BUF_SIZE >= 2 means buffered output (for XC9572XL and MAXII devices)
`else
  localparam BUF_SIZE = 1; // BUF_SIZE == 1 means unbuffered output (for XC9536XL)
`endif

integer idx;

reg [3:0] S_DBr[0:BUF_SIZE-1]; // sync data vector buffer: {nVSYNC, nCLAMP, nHSYNC, nCSYNC}
reg [6:0] R_DBr[0:BUF_SIZE-1]; // red data vector buffer
reg [6:0] G_DBr[0:BUF_SIZE-1]; // green data vector buffer
reg [6:0] B_DBr[0:BUF_SIZE-1]; // blue data vector buffer


initial begin
  for (idx=0; idx<BUF_SIZE; idx=idx+1) begin
   S_DBr[idx] = 4'b1111;
   R_DBr[idx] = 7'b0000000;
   G_DBr[idx] = 7'b0000000;
   B_DBr[idx] = 7'b0000000;
  end
end

reg [1:0] data_cnt = 2'b00;

reg [2:0] serrcount;  // 240p: 3 hsync pulses during vsync pulse ; 480i: 6 serrated hsync per vsync
reg [1:0] line_cnt;   // PAL: Linecount[1:0] == 01 ; NTSC: Linecount[1:0] = 11
reg       vmode;      // PAL: vmode == 1          ;  NTSC: vmode == 0
reg       nblank_rgb; // blanking of RGB pixels for de-blur

//
// pulse shapes and their realtion to each other:
// nCLK (50MHz, Numbers representing negedge count)
// ---. 3 .---. 0 .---. 1 .---. 2 .---. 3 .---
//    |___|   |___|   |___|   |___|   |___|
// nDSYNC (12.5MHz)                            .....
// -------.       .-------------------.
//        |_______|                   |_______
//
// more info: http://members.optusnet.com.au/eviltim/n64rgb/n64rgb.html
//


always @(negedge nCLK) begin
  if (~nDSYNC) begin

    // counter and blanking management
    if(S_DBr[0][3] & ~DI[3]) begin // negedge at nVSYNC detected - reset counter
      serrcount <= 3'b000;
      line_cnt <= 2'b00;
      vmode <= ~line_cnt[1];
    end

    if(&{~S_DBr[0][3],~S_DBr[0][0],DI[0]})  // nVSYNC low and posedge at nCSYNC
      serrcount <= serrcount + 1; // count up hsync pulses during vsync pulse
                                  // serrcount[2]==1 means a value >=4 -> 480i mode detected

    if(~S_DBr[0][1] & DI[1]) begin // posedge nHSYNC high -> increase line_cnt and reset blanking
      nblank_rgb <= vmode;
      line_cnt <= line_cnt + 1;
    end else
      nblank_rgb <= ~nblank_rgb;

    // get data
    S_DBr[0] <= DI[3:0];
    data_cnt <= 2'b01;

`ifdef USE_MAXII
  end else if (|{~DF_FEAT, serrcount[2], nblank_rgb}) begin
`else
  end else if (serrcount[2] | nblank_rgb) begin
`endif
    data_cnt <= data_cnt + 1;
    case(data_cnt)
      2'b01: R_DBr[0] <= DI;
      2'b10: G_DBr[0] <= DI;
      2'b11: B_DBr[0] <= DI;
    endcase
  end
end

always @(posedge nDSYNC) begin // nDSYNC has to wait for negedge nCLK with data_cnt == 2'b00
                               // to ensure B value is correct -> use posedge instead of negedge
  for (idx=BUF_SIZE-1; idx>0; idx=idx-1) begin
    S_DBr[idx] <= S_DBr[idx-1];
    R_DBr[idx] <= R_DBr[idx-1];
    G_DBr[idx] <= G_DBr[idx-1];
    B_DBr[idx] <= B_DBr[idx-1];
  end
end

assign {nVSYNC, nCLAMP, nHSYNC, nCSYNC} = S_DBr[BUF_SIZE-1];
assign R_o = R_DBr[BUF_SIZE-1];
assign G_o = G_DBr[BUF_SIZE-1];
assign B_o = B_DBr[BUF_SIZE-1];


endmodule