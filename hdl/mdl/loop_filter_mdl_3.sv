// -----------------------------------------------------------------------------
// PI loop-filter (non-synthesisable model)
//   • Runs once per symbol when e_valid_i pulses
//   • Fixed-point gains implemented as right shifts
//   • ctrl_o drives the phase-accumulator (same 18-bit scale as Gardner e_out_o)
// -----------------------------------------------------------------------------
module pi_loop_filter_mdl_3 #
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

  logic signed [WERR-1:0] ctrl=0;
  logic signed [ACC_WIDTH-1:0] acc=0;
  logic signed [WERR-1:0] u_prop1=0,u_prop2=0,u_prop=0,u_pre,u_prop4;          // proportional term

  logic ctrl_val;

  assign u_pre =    ((e_in_i > 0) && (e_in_i > 127)) ? e_in_i[WERR-1:KP_SHIFT] : 
                    ((e_in_i > 0) && (e_in_i < 128)) ? '0 :
                    ((e_in_i < 0) && (e_in_i < -128)) ? {{KP_SHIFT{e_in_i[WERR-1]}},e_in_i[WERR-1:KP_SHIFT]} :
                    ((e_in_i < 0) && (e_in_i > -127)) ? '0 : '0;



  //assign u_prop = (e_in_i >>> KP_SHIFT);
  //assign acc    = (acc + (e_in_i >>> KI_SHIFT));
  //assign ctrl   = (u_prop + acc);

  /* NOTE: be careful with shift operation and signed values:
    (-1) >>> 1 = -1;
    (+1) >>> 1 = 0;
    *Depending on how it's used, could be a problem, for example in an integrator... */

  always_ff @(posedge clk) begin
    if (!reset_n) begin 
      ctrl_val <= '0;
    end else begin 
      if (e_valid_i) begin
        u_prop  <= u_pre;
        acc     <= acc + u_pre;
        ctrl    <= u_prop + acc;
      end
      if (e_valid_i) ctrl_val <= '1;
      else ctrl_val <= '0;
    end
  end

  assign ctrl_o     = ctrl;
  assign ctrl_val_o = ctrl_val;

        //u_prop1 <= (e_in_i >>> KP_SHIFT);
        //u_prop2 <= (e_in_i + (e_in_i[WERR-1] ? -1 : 1) << (KP_SHIFT-1)) >>> KP_SHIFT;

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


