`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// -----------------------------------------------------------------------------
// Non-synthesizable MSK differential slicer / decoder
//   • Input stream is one complex sample per symbol from the interpolator
//   • No carrier loop, no matched filter → use SIGN of Imag{Sₖ·conj(Sₖ₋₁)}
//   • Produces a hard bit and a 1-cycle data_valid_o pulse
//   • Zero multipliers inferred in simulation; just $signed * for clarity
// -----------------------------------------------------------------------------
module msk_slicer_dec_mdl #
(
  parameter int IW = 18   // width of I/Q symbol samples
)
(
  input  logic                      clk,
  input  logic                      reset_n,

  // interpolator outputs
  input  logic signed [IW-1:0]      i_sym_i,
  input  logic signed [IW-1:0]      q_sym_i,
  input  logic                      sym_valid_i,

  // recovered bit
  output logic                      data_o,
  output logic                      data_valid_o
);

  // ----------------------------------------------------------------------------
  // 1. store previous symbol (only when sym_valid_i)
  // ----------------------------------------------------------------------------
  logic                  prev_valid;
  logic signed [IW-1:0]  I_prev, Q_prev;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      I_prev     <= '0;
      Q_prev     <= '0;
      prev_valid <= 1'b0;
    end
    else if (sym_valid_i) begin
      I_prev     <= i_sym_i;
      Q_prev     <= q_sym_i;
      prev_valid <= 1'b1;     // becomes valid after first symbol
    end
  end

  // ----------------------------------------------------------------------------
  // 2. differential phase detector & slicer
  //    imag{S_k · conj(S_k-1)}  =  Q_k·I_{k-1}  −  I_k·Q_{k-1}
  // ----------------------------------------------------------------------------
  logic signed [2*IW:0] imag_diff;

  always_comb
    imag_diff = (q_sym_i * I_prev) - (i_sym_i * Q_prev);

  // ----------------------------------------------------------------------------
  // 3. output bit & valid pulse (only after we have a previous symbol)
  // ----------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!reset_n) begin
      data_o        <= 1'b0;
      data_valid_o  <= 1'b0;
    end
    else if (sym_valid_i) begin
      data_o        <= (imag_diff >= 0);
      data_valid_o  <= prev_valid;   // first symbol suppressed
    end
    else
      data_valid_o  <= 1'b0;
  end

endmodule



/* instantiation template ------------------------------------------------------

msk_slicer_dec_mdl #(
  .IW (18)
) msk_slicer_dec_inst (
  .clk          (),
  .reset_n      (),
  .i_sym_i      (),
  .q_sym_i      (),
  .sym_valid_i  (),
  .data_o       (),
  .data_valid_o ()
);

*/
