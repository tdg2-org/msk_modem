`timescale 1ns / 1ps  // <time_unit>/<time_precision>

module pi_loop_filter #
(
  parameter int WERR        = 18,  // width of e_in_i and ctrl_o
  parameter int KP_SHIFT    = 7,   // Kp = 2^-KP_SHIFT
  parameter int KI_SHIFT    = 11,  // Ki = 2^-KI_SHIFT
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
  logic signed [WERR-1:0] u_prop=0,prop_pre, int_pre, prop_pre1, int_pre1;          // proportional term
  logic ctrl_val;

  localparam int DZ_KP = (1 << KP_SHIFT) - 1;
  localparam int DZ_KI = (1 << KI_SHIFT) - 1;

  assign prop_pre = ((e_in_i > 0) && (e_in_i >   DZ_KP)) ? e_in_i[WERR-1:KP_SHIFT] :
                    ((e_in_i > 0) && (e_in_i <=  DZ_KP)) ? '0 :
                    ((e_in_i < 0) && (e_in_i <  -DZ_KP)) ? {{KP_SHIFT{e_in_i[WERR-1]}}, e_in_i[WERR-1:KP_SHIFT]} :
                    ((e_in_i < 0) && (e_in_i >= -DZ_KP)) ? '0 : '0;

  assign int_pre =  ((e_in_i > 0) && (e_in_i >   DZ_KI)) ? e_in_i[WERR-1:KI_SHIFT] :
                    ((e_in_i > 0) && (e_in_i <=  DZ_KI)) ? '0 :
                    ((e_in_i < 0) && (e_in_i <  -DZ_KI)) ? {{KI_SHIFT{e_in_i[WERR-1]}}, e_in_i[WERR-1:KI_SHIFT]} :
                    ((e_in_i < 0) && (e_in_i >= -DZ_KI)) ? '0 : '0;


  //assign prop_pre1 = e_in_i >>> KP_SHIFT;
  //assign int_pre1  = e_in_i >>> KI_SHIFT;


  always_ff @(posedge clk) begin
    if (!reset_n) begin 
      ctrl_val <= '0;
    end else begin 
      if (e_valid_i) begin
        u_prop  = prop_pre;       // BLOCKING
        acc     = acc + int_pre;  // BLOCKING
        ctrl    <= u_prop + acc;
      end
      if (e_valid_i) ctrl_val <= '1;
      else ctrl_val <= '0;
    end
  end

  assign ctrl_o     = ctrl;
  assign ctrl_val_o = ctrl_val;

endmodule
/*
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

pi_loop_filter #(
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


