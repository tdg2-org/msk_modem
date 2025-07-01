// -----------------------------------------------------------------------------
// PI loop-filter (non-synthesisable model)
//   • Runs once per symbol when e_valid_i pulses
//   • Fixed-point gains implemented as right shifts
//   • ctrl_o drives the phase-accumulator (same 18-bit scale as Gardner e_out_o)
// -----------------------------------------------------------------------------
module pi_loop_filter_mdl_2 #
(
  parameter int WERR        = 18,  // width of e_in_i and ctrl_o
  parameter int KP_SHIFT    = 7,   // Kp = 2^-KP_SHIFT
  parameter int KI_SHIFT    = 12,  // Ki = 2^-KI_SHIFT
  parameter int ACC_WIDTH   = 24   // integrator register width
)
(
  input  logic                       clk,
  input  logic                       reset_n,

  input  logic signed [WERR-1:0]     e_in_i,      // timing-error from TED
  input  logic                       e_valid_i,   // 1-cycle strobe

  output logic signed [WERR-1:0]     ctrl_o       // correction to phase-acc
);

  logic signed [WERR-1:0] ctrl;

  // ---------------------------------------------------------------------------
  // 1. integrator register
  // ---------------------------------------------------------------------------
  logic signed [ACC_WIDTH-1:0] acc;

  // ---------------------------------------------------------------------------
  // 2. proportional + integral update on each e_valid_i pulse
  // ---------------------------------------------------------------------------
  logic signed [WERR-1:0] u;          // proportional term
  logic signed [ACC_WIDTH-1:0] acc_next;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      acc   <= '0;
      ctrl  <= '0;
      u     <= '0;
    end else if (e_valid_i) begin
      // proportional term   u = e / 2^KP_SHIFT
      u = e_in_i >>> KP_SHIFT;

      // integrator update   acc += e / 2^KI_SHIFT
      acc_next = acc + (e_in_i >>> KI_SHIFT);

      // optional anti-wind-up clamp
      if (acc_next >  ($signed({1'b0, {(ACC_WIDTH-1){1'b1}}})))  // +max
        acc <=  $signed({1'b0, {(ACC_WIDTH-1){1'b1}}});
      else if (acc_next < ($signed({1'b1, {(ACC_WIDTH-1){1'b0}}}))) // -max
        acc <=  $signed({1'b1, {(ACC_WIDTH-1){1'b0}}});
      else
        acc <= acc_next;

      // sum → ctrl
      ctrl <= acc[WERR-1:0] + u;
    end
  end

  assign ctrl_o = ctrl;

endmodule



/* instantiation template ------------------------------------------------------

pi_loop_filter_mdl_2 #(
  .WERR      (18),
  .KP_SHIFT  (7 ),
  .KI_SHIFT  (12),
  .ACC_WIDTH (24)
) pi_loop_filter_inst (
  .clk        (),
  .reset_n    (),
  .e_in_i     (),
  .e_valid_i  (),
  .ctrl_o     ()
);

*/
