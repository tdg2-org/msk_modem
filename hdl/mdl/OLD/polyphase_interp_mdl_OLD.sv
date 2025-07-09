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
module polyphase_interp_mdl_OLD #
(
  parameter int OSF        = 20,  // polyphase branches
  parameter int TAPS_PPH   = 5 ,  // taps per branch
  parameter int WIQ        = 16,  // input sample width
  parameter int WO         = 18   // output sample width
)
(
  input  logic                  clk,
  input  logic                  reset_n,

  // oversampled I/Q stream (200 MHz)
  input  logic signed [WIQ-1:0] i_raw_i,
  input  logic signed [WIQ-1:0] q_raw_i,
  input  logic                  iq_raw_val_i,       
  // phase info from phase-accumulator
  input  logic [4:0]            phase_int_i,    // 0…19
  input  logic [26:0]           mu_i,           // not used here

  // one-per-symbol enable
  input  logic                  sym_valid_i,

  // interpolated symbol output
  output logic signed [WO-1:0]  i_sym_o,
  output logic signed [WO-1:0]  q_sym_o,
  output logic                  sym_valid_o
);

  // ---------------------------------------------------------------------------
  // 1. delay-line : store (OSF + (TAPS_PPH-1)*OSF) samples  (here 100 max)
  // ---------------------------------------------------------------------------
  localparam int DEPTH = OSF * TAPS_PPH;    // 100
  typedef logic signed [WIQ-1:0] sample_t;

  sample_t idelay [DEPTH];
  sample_t qdelay [DEPTH];
  int      wr_ptr;

  logic [DEPTH-1:0] sr;
  logic array_full;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      wr_ptr      <= 0;
      sr          <= '0;
      array_full  <= '0;
    end else if (iq_raw_val_i) begin
      sr <= {sr[DEPTH-2:0],1'b1};
      if (sr == '1) array_full <= '1;
      idelay[wr_ptr] <= i_raw_i;
      qdelay[wr_ptr] <= q_raw_i;
      wr_ptr         <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
    end
  end

  // helper: wrapped read (current pointer minus offset)
  function automatic sample_t rd_i (input int off);
    int idx;
    begin
      idx = wr_ptr - off;
      if (idx < 0)       idx += DEPTH;
      else if (idx >= DEPTH) idx -= DEPTH;
      return idelay[idx];
    end
  endfunction

  function automatic sample_t rd_q (input int off);
    int idx;
    begin
      idx = wr_ptr - off;
      if (idx < 0)       idx += DEPTH;
      else if (idx >= DEPTH) idx -= DEPTH;
      return qdelay[idx];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 2. coefficient ROM  (Q1.15 half-sine example; replace as needed)
  // ---------------------------------------------------------------------------
  typedef logic signed [15:0] coef_t;
  coef_t coeff[OSF][TAPS_PPH];

  initial begin
    real half_sine[OSF];
    for (int p = 0; p < OSF; p++)
      half_sine[p] = $sin( (p + 0.5) * 3.1415926536 / OSF );   // 0…π

    // simple “shifted” version: same taps each branch, scaled half-sine
    for (int p = 0; p < OSF; p++)
      for (int t = 0; t < TAPS_PPH; t++)
//        coeff[p][t] = $rtoi( half_sine[p] * 32767.0 / TAPS_PPH );
        coeff[p][t] = $rtoi( half_sine[p] * 32767.0);
  end

  // ---------------------------------------------------------------------------
  // 3. dot product on sym_valid_i
  // ---------------------------------------------------------------------------
  localparam int PROD_W = WIQ + 16;              // 32 bits
  logic signed [PROD_W-1:0] acc_i, acc_q;

  logic sym_val;
  int off;

  always_ff @(posedge clk) begin
    sym_val <= 1'b0;
    if (sym_valid_i && array_full) begin
      acc_i = '0;
      acc_q = '0;
      for (int k = 0; k < TAPS_PPH; k++) begin
        off = phase_int_i + k*OSF;
        acc_i += rd_i(off) * coeff[phase_int_i][k];
        acc_q += rd_q(off) * coeff[phase_int_i][k];
      end
      // truncate / round to WO bits (here simple shift)
      //i_sym_o     <= acc_i >>> (PROD_W-WO);
      //q_sym_o     <= acc_q >>> (PROD_W-WO);
      i_sym_o     <= acc_i >>> (16);
      q_sym_o     <= acc_q >>> (16);
      sym_val     <= 1'b1;
    end
  end

  assign sym_valid_o = sym_val;


// dbg 

//  logic [19:0] sym_val_sr = '0;
//  always_ff @(posedge clk) sym_val_sr <= {sym_val_sr[18:0],sym_val};
//
//  int shiftPtr = 7;
//  assign sym_valid_o = sym_val_sr[shiftPtr];


endmodule



/* instantiation template ------------------------------------------------------

polyphase_interp_mdl #(
  .OSF       (20),
  .TAPS_PPH  (5 ),
  .WIQ       (16),
  .WO        (18)
) polyphase_interp_inst (
  .clk           (),
  .reset_n       (),
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
