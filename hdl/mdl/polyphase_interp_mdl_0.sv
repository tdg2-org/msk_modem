`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// -----------------------------------------------------------------------------
// Polyphase fractional-delay interpolator (non-synthesizable model)
//   • OSF       : 20 samples / symbol   (fixed phase-bank count)
//   • TAPS_PPH  : taps per polyphase FIR branch
//   • For each symbol strobe (sym_valid_i = 1) it:
//        1) selects coefficient set  = phase_int_i  (0…19)
//        2) picks TAPS_PPH samples   = {x[n-d-p], x[n-d-p-OSF], …}
//        3) returns the dot product  → I/Q_sym_o  + sym_valid_o
//
//   Notes
//     – Coefficients supplied as a 2-D constant array [OSF][TAPS_PPH] (Q1.15)
//     – Delay-line implemented as simple packed array (non-synth)
//     – mu_i is unused in the polyphase version but kept for pin-compatibility
// -----------------------------------------------------------------------------
module polyphase_interp_mdl_0 #
(
  parameter int OSF        = 20,  // polyphase branches
  parameter int TAPS_PPH   = 5 ,  // taps per branch
  parameter int WIQ        = 16,  // input sample width
  parameter int WO         = 18   // output sample width
)
(
  input  logic                  clk,
  input  logic                  rst,
  input  logic signed [WIQ-1:0] i_raw_i,
  input  logic signed [WIQ-1:0] q_raw_i,
  input  logic                  iq_raw_val_i,       
  input  logic [4:0]            phase_int_i,    // 0…19
  input  logic [26:0]           mu_i,           // not used here
  input  logic                  sym_valid_i,
  output logic signed [WO-1:0]  i_sym_o,
  output logic signed [WO-1:0]  q_sym_o,
  output logic                  sym_valid_o
);
//-------------------------------------------------------------------------------------------------
// 5taps * 20samples/symbol = 100 deep delay
//-------------------------------------------------------------------------------------------------
  localparam DEPTH = OSF * TAPS_PPH;
  
  logic signed [WIQ-1:0] idelay [DEPTH-1:0] = '{default:'0};
  logic signed [WIQ-1:0] qdelay [DEPTH-1:0] = '{default:'0};
//
//  always_ff @(posedge clk) begin
//    if (iq_raw_val_i) begin 
//      idelay <= {idelay[DEPTH-2:0],i_raw_i};
//      qdelay <= {qdelay[DEPTH-2:0],q_raw_i};
//    end
//  end

  
  always_ff @(posedge clk) begin
    if (iq_raw_val_i) begin 
      idelay <= {i_raw_i,idelay[DEPTH-1:1]};
      qdelay <= {q_raw_i,qdelay[DEPTH-1:1]};
    end
  end


//-------------------------------------------------------------------------------------------------
// 5-tap per phase branch, in this scenario without pulse-shaping each tap for the phase branch is 
// identical. this will change when doing pulse-shaping, and will then have to be 20xN taps, where
// N=5 or the new number of taps for the design
//-------------------------------------------------------------------------------------------------
  //localparam signed [15:0] coeffs [OSF-1:0][TAPS_PPH-1:0] = { // for future when doing pulse-shaping at TX side
  localparam signed [15:0] coeffs [OSF-1:0] = {
    16'sd2571, 16'sd7649, 16'sd12567, 16'sd17133, 16'sd21283, 16'sd24954, 16'sd28080, 16'sd30272, 16'sd31480, 16'sd31988,
    16'sd31988, 16'sd31480, 16'sd30272, 16'sd28080, 16'sd24954, 16'sd21283, 16'sd17133, 16'sd12567, 16'sd7649, 16'sd2571};

  logic signed [15:0] coeffs0 [OSF-1:0] =coeffs;//debug view only

  logic signed [34:0] acc_i, acc_q, acc_si, acc_sq;
  logic acc_val;
  int unsigned off;

  always_ff @(posedge clk) begin 
    if (iq_raw_val_i && sym_valid_i) begin
      acc_si = '0; // BLOCKING: local running sum
      acc_sq = '0; // BLOCKING: local running sum
      for (int k = 0; k < TAPS_PPH; k++) begin
        off = k*20 + phase_int_i;
        off %= 100; // wrap 0…99
        acc_si += idelay[off] * coeffs[phase_int_i]; // or coeffs[phase_int_i][k]
        acc_sq += qdelay[off] * coeffs[phase_int_i]; // or coeffs[phase_int_i][k]
        //acc_si += (idelay[k*20 + phase_int_i] * coeffs[phase_int_i]);
        //acc_sq += (qdelay[k*20 + phase_int_i] * coeffs[phase_int_i]);
      end
      acc_i   <= acc_si; // NON-BLOCKING: update register
      acc_q   <= acc_sq; // NON-BLOCKING: update register
      acc_val <= '1;
    end else begin 
      //acc_i   <= '0;
      //acc_q   <= '0;
      acc_val <= '0;
    end 
  end

  assign sym_valid_o  = acc_val;

  //assign i_sym_o      = acc_i[28:11];
  //assign q_sym_o      = acc_q[28:11];
  assign i_sym_o      = acc_i;// >>> 15;    16'sd2571, 16'sd7649, 16'sd12567, 16'sd17133, 16'sd21283, 16'sd24954, 16'sd28080, 16'sd30272, 16'sd31480, 16'sd31988,
  assign q_sym_o      = acc_q;// >>> 15;    16'sd31988, 16'sd31480, 16'sd30272, 16'sd28080, 16'sd24954, 16'sd21283, 16'sd17133, 16'sd12567, 16'sd7649, 16'sd2571};
  




endmodule



/* instantiation template ------------------------------------------------------

polyphase_interp_mdl_0 #(
  .OSF       (20),
  .TAPS_PPH  (5 ),
  .WIQ       (16),
  .WO        (18)
) polyphase_interp_0 (
  .clk           (),
  .rst           (),
  .i_raw_i       (),
  .q_raw_i       (),
  .phase_int_i   (),
  .mu_i          (),
  .sym_valid_i   (),
  .i_sym_o       (),
  .q_sym_o       (),
  .sym_valid_o   ()
);

*/


// 2571, 7649, 12567, 17133, 21283, 24954, 28080, 30272, 31480, 31988, 31988, 31480, 30272, 28080, 24954, 21283, 17133, 12567, 7649, 2571
