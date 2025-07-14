// -----------------------------------------------------------------------------
// √RC matched filter  (simulation-only, fixed taps)
//   • OSF       : 20 samples / symbol   (200 MHz over 10 MHz)
//   • Roll-off  : β = 0.25
//   • Span      : 6 symbols  → 121 taps  (-3T … +3T, inclusive)
//   • Coeffs    : hard-coded, Q1.15
// -----------------------------------------------------------------------------
import mf_taps_pkg::*;

module rrc_mf_mdl #
(
  parameter int OSF  = 20,        // samples / symbol  (fixed)
  parameter int WIQ  = 16,        // input width
  parameter int WO   = 16         // output width
)
(
  input  logic                       clk,
  input  logic                       rst,

  // 200-MHz I/Q input
  input  logic signed [WIQ-1:0]      i_in,
  input  logic signed [WIQ-1:0]      q_in,
  input  logic                       iq_val_i,

  // filtered output  (1-clock latency)
  output logic signed [WO-1:0]       i_out,
  output logic signed [WO-1:0]       q_out,
  output logic                       iq_val_o
);

  // ---------------------------------------------------------------------------
  // 1. 121 hard-coded Q1.15 taps  (symmetrical)
  //     Generated for β = 0.25, span = 6 T, unit-energy normalised
  // ---------------------------------------------------------------------------
  localparam int NTAPS = MF_NTAPS; // pkg file
  localparam logic signed [15:0] coeffs [NTAPS-1:0] = mf_coeffs; // pkg file


  logic signed [WIQ-1:0] idelay [NTAPS-1:0] = '{default:'0};
  logic signed [WIQ-1:0] qdelay [NTAPS-1:0] = '{default:'0};

  always_ff @(posedge clk)
    if (iq_val_i) begin
        idelay <= { i_in , idelay[NTAPS-1:1] };
        qdelay <= { q_in , qdelay[NTAPS-1:1] };
    end

  // ---------------------------------------------------------------------------
  // 3. convolution: sum_{k=0}^{120}  x[n-k]·h[k]
  // ---------------------------------------------------------------------------
  localparam int ACC_W = WIQ + 16 + $clog2(NTAPS);  // 16+16+7 = 39
  logic signed [ACC_W-1:0] acc_i, acc_q;
  logic val_d;

  always_ff @(posedge clk) begin
    acc_i = '0;
    acc_q = '0;
    if (iq_val_i) begin
        for (int k = 0; k < NTAPS; k++) begin
            acc_i += idelay[k] * coeffs[k];
            acc_q += qdelay[k] * coeffs[k];
        end
    end
    val_d <= iq_val_i;   // 1-clock latency
  end


  assign i_out    = acc_i[33:18];
  assign q_out    = acc_q[33:18];
  assign iq_val_o = val_d;

endmodule
/*

  rrc_mf_mdl_3 #
  (
    .OSF      (20   ),  
    .BETA     (0.25 ),  
    .SPAN_SYM (6    ),  
    .WI       (16   ),  
    .WO       (18   )   
  ) rrc_mf_mdl_inst3 (
    .clk      (),
    .rst      (),
    .i_in     (),
    .q_in     (),
    .iq_val_i (),
    .i_out    (),
    .q_out    (),
    .iq_val_o ()
  );


  rrc_mf_mdl_3  mf3 (
    .clk      (clk    ),
    .rst      (rst    ),
    .i_in     (i_fir  ),
    .q_in     (q_fir  ),
    .iq_val_i (iq_val ),
    .i_out    (),
    .q_out    (),
    .iq_val_o ()
  );


*/

