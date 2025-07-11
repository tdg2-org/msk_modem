`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// -----------------------------------------------------------------------------
// Phase accumulator, Q5.27 format
//   • Adds 1 sample-step  (1 << FRAC_W)  every 200-MHz clock
//   • Adds ctrl_i (scaled) to fine-tune the step
//   • When INTEGER field ≥ OSF (20) it wraps and emits sym_valid_o = 1
// -----------------------------------------------------------------------------
module phase_accum_mdl #
(
  parameter int OSF        = 20,   // samples per symbol
  parameter int CTRL_W     = 18,   // ctrl_i width (LSB = 2-12 symbol)
  parameter int INT_W      = 5 ,   // ceil(log2(OSF)) = 5
  parameter int FRAC_W     = 27
)
(
  input   logic                     clk,
  input   logic                     reset_n,
  input   logic signed [CTRL_W-1:0] ctrl_i,        // timing correction
  input   logic                     ctrl_val_i,
  output  logic                     sym_valid_o,   // 1-cycle pulse / symbol
  output  logic [INT_W-1:0]         phase_int_o,   // 0 … 19
  output  logic [FRAC_W-1:0]        mu_o           // Q0.27
);

  // ---------------- constants & types ----------------------------------------
  localparam int PHASE_W   = INT_W + FRAC_W;        // 32 bits total
  localparam logic [PHASE_W-1:0] ONE_SAMPLE = 1 << FRAC_W;   // 1.000 in Q5.27
  localparam int SHIFT_CTRL = FRAC_W - 12;          // align ctrl (2-12) to frac

  // ---------------- registers -------------------------------------------------
  logic [PHASE_W-1:0] phi;          // phase pointer (Q5.27)

  logic signed [PHASE_W:0] ctrl_ext;
  logic [PHASE_W:0] phi_next;
  logic wrap, sym_val;


  always_ff @(posedge clk) begin
    if (!reset_n) begin
      phi         <= '0;
      sym_val <= 1'b0;
    end else begin
      // 1) accumulate one sample + fractional correction

      ctrl_ext = {{(PHASE_W-CTRL_W+1){ctrl_i[CTRL_W-1]}}, ctrl_i} << SHIFT_CTRL;

      phi_next = {1'b0,phi} + {1'b0,ONE_SAMPLE} + ctrl_ext;

      // 2) detect wrap: INTEGER part reached 20 ?
      wrap = (phi_next[PHASE_W-1:FRAC_W] >= OSF);

      // 3) wrap by subtracting 20 samples if needed
      if (wrap)
        phi <= phi_next - (OSF << FRAC_W);   // back into 0…19.xx range
      else
        phi <= phi_next[PHASE_W-1:0];

      // 4) one-clock symbol strobe
      sym_val <= (wrap);

    end
  end

  assign phase_int_o = phi[PHASE_W-1:FRAC_W];   // coarse 0…19
  assign mu_o        = phi[FRAC_W-1:0];         // fractional part (Q0.27)
  assign sym_valid_o = sym_val;


//-------------------------------------------------------------------------------------------------
// debug
//-------------------------------------------------------------------------------------------------
  int cnt = 0, cnt_prev=0;
  logic inc,dec,nom;
  logic wrap_reg;

  always_ff @(posedge clk) begin
    inc <= '0; dec <= '0; nom <= '0;

    if (sym_val == '1) cnt <= 0;
    else cnt <= cnt + 1;

    if      (sym_val && (cnt < 19))  dec <= '1;
    else if (sym_val && (cnt > 19))  inc <= '1;
    else if (sym_val) nom <= '1;

  end

endmodule



/* instantiation template ------------------------------------------------------

phase_accum_mdl #(
  .OSF       (20),
  .CTRL_W    (18),
  .INT_W     (5 ),
  .FRAC_W    (27)
) phase_accum_inst (
  .clk          (),
  .reset_n      (),
  .ctrl_i       (),
  .sym_valid_o  (),
  .phase_int_o  (),
  .mu_o         ()
);

*/
