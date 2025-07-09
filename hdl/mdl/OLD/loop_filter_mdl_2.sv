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
  input  logic                    clk,
  input  logic                    reset_n,
  input  logic signed [WERR-1:0]  e_in_i,      // timing-error from TED
  input  logic                    e_valid_i,   // 1-cycle strobe
  output logic signed [WERR-1:0]  ctrl_o,      // correction to phase-acc
  output logic                    ctrl_val_o
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
  logic signed [WERR-1:0] ki_term;
  logic ctrl_val;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      acc       <= '0;
      ctrl      <= '0;
      u         <= '0;
      ctrl_val  <= '0;
    end else if (e_valid_i) begin
      // proportional term   u = e / 2^KP_SHIFT
      u = e_in_i >>> KP_SHIFT;

      // integrator update   acc += e / 2^KI_SHIFT
      /*acc_next = acc + (e_in_i >>> KI_SHIFT);*/
      
      // replace above line
      // rounding right shift   (adds 0.5 LSB before >>>)
      
      ki_term   = (e_in_i + (e_in_i[WERR-1] ? -1 : 1) << (KI_SHIFT-1)) >>> KI_SHIFT;
      acc_next  = acc + ki_term;


      // optional anti-wind-up clamp
      if (acc_next >  ($signed({1'b0, {(ACC_WIDTH-1){1'b1}}})))  // +max
        acc <=  $signed({1'b0, {(ACC_WIDTH-1){1'b1}}});
      else if (acc_next < ($signed({1'b1, {(ACC_WIDTH-1){1'b0}}}))) // -max
        acc <=  $signed({1'b1, {(ACC_WIDTH-1){1'b0}}});
      else
        acc <= acc_next;

      // sum → ctrl
      //ctrl <= acc[WERR-1:0] + u;
      ctrl <= acc_next[WERR-1:0] + u;   // use just-computed value
      //ctrl_val <= '1;
    end
    if (e_valid_i) ctrl_val <= '1;
    else ctrl_val <= '0;

  end

  assign ctrl_o     = ctrl;
  assign ctrl_val_o = ctrl_val;



//-------------------------------------------------------------------------------------------------
// debug - 1000 sample average of e_in_i
//-------------------------------------------------------------------------------------------------
  logic signed [WERR-1:0] e_sr [999:0] = '{default:'0};
  int signed avg = 0, sum=0, cnt = 1;

  always_ff @(posedge clk) begin
    if (e_valid_i) begin 
      e_sr <= {e_sr[998:0],e_in_i};
      if (cnt == 1000) begin 
        sum <= (sum + e_in_i) - e_sr[999];
        avg <= sum / 1000;
      end else begin 
        cnt <= cnt + 1;
        sum <= sum + e_in_i;
        avg <= sum / cnt;
      end
    end
  end



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
  .ctrl_o     (),
  .ctrl_val_o ()
);

*/
