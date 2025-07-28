
// REMOVE function and $signed 


`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// synthesizable PI loop filter (fixed-point), with correct saturation
module loop_filter_cfo #
(
  parameter int ERR_WIDTH   = 24,  // Q1.(ERR_WIDTH-1) phase_err_i
  parameter int PHASE_WIDTH = 32,  // Q1.(PHASE_WIDTH-1) freq_word_o

  // K = COEFF / 2**SHIFT
  parameter int KP_SHIFT = 28,
  parameter int KI_SHIFT = 28,
  parameter int KP_COEFF =  322,   // ≈ 1.2e-6 * 2^28
  parameter int KI_COEFF =   13    // ≈ 5.0e-8 * 2^28
)
(
  input  logic                           clk,
  input  logic                           rst,
  input  logic                           err_valid_i,
  input  logic signed [ERR_WIDTH-1:0]    phase_err_i,
  output logic                           freq_valid_o,
  output logic signed [PHASE_WIDTH-1:0]  freq_word_o
);

  // saturation endpoints for Q1.(PHASE_WIDTH-1)
  localparam logic signed [PHASE_WIDTH-1:0] SAT_MAX = {1'b0, {(PHASE_WIDTH-1){1'b1}}}; // +2^(W-1)-1
  localparam logic signed [PHASE_WIDTH-1:0] SAT_MIN = {1'b1, {(PHASE_WIDTH-1){1'b0}}}; // -2^(W-1)

  // add with saturation (W-bit + W-bit -> W-bit)
  function automatic logic signed [PHASE_WIDTH-1:0]
  sat_add2(input logic signed [PHASE_WIDTH-1:0] a,
           input logic signed [PHASE_WIDTH-1:0] b);
    logic signed [PHASE_WIDTH:0] y;  // one extra bit
    y = a + b;
    if (y[PHASE_WIDTH] != y[PHASE_WIDTH-1]) begin
      sat_add2 = y[PHASE_WIDTH] ? SAT_MIN : SAT_MAX;
    end else begin
      sat_add2 = y[PHASE_WIDTH-1:0];
    end
  endfunction

  // registers
  logic signed [PHASE_WIDTH-1:0] integr_acc = '0;

  // combinational terms for this update
  logic signed [PHASE_WIDTH-1:0] p_term_w;   // proportional (resized)
  logic signed [PHASE_WIDTH-1:0] i_step_w;   // integrator delta this tick
  logic signed [PHASE_WIDTH-1:0] integr_n;   // next integrator value
  logic signed [PHASE_WIDTH-1:0] freq_n;

  // multiply-then-shift helpers (cast both operands to signed)
  function automatic logic signed [PHASE_WIDTH-1:0]
  mul_shift_clip(input logic signed [ERR_WIDTH-1:0] err,
                 input int coeff,
                 input int shift);
    // full-precision product (ERR_WIDTH + 32) then arithmetic right shift
    logic signed [ERR_WIDTH+31:0] prod;
    logic signed [ERR_WIDTH+31:0] shr;
    prod = $signed(err) * $signed(coeff);
    shr  = prod >>> shift;
    // clip into PHASE_WIDTH
    if (shr >  $signed(SAT_MAX))      mul_shift_clip = SAT_MAX;
    else if (shr < $signed(SAT_MIN))  mul_shift_clip = SAT_MIN;
    else                              mul_shift_clip = shr[PHASE_WIDTH-1:0];
  endfunction

  always_ff @(posedge clk) begin
    if (rst) begin
      integr_acc   <= '0;
      freq_word_o  <= '0;
      freq_valid_o <= 1'b0;
    end else begin
      freq_valid_o <= 1'b0;

      if (err_valid_i) begin
        // P and I contributions for this symbol
        p_term_w  = mul_shift_clip(phase_err_i, KP_COEFF, KP_SHIFT);
        i_step_w  = mul_shift_clip(phase_err_i, KI_COEFF, KI_SHIFT);

        // integrator update with proper saturation
        integr_n  = sat_add2(integr_acc, i_step_w);

        // PI output and register updates
        freq_n        = sat_add2(integr_n, p_term_w);
        integr_acc    <= integr_n;
        freq_word_o   <= freq_n;
        freq_valid_o  <= 1'b1;
      end
    end
  end
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

  loop_filter_cfo #(
    .ERR_WIDTH   (24 ), 
    .PHASE_WIDTH (32 ), 
    .KP_SHIFT    (28 ), 
    .KI_SHIFT    (28 ),
    .KP_COEFF    (322), 
    .KI_COEFF    (13 )  
  ) loop_filter_cfo (
    .clk          (),
    .rst          (),
    .err_valid_i  (),
    .phase_err_i  (),
    .freq_valid_o (),
    .freq_word_o  ()
  );


*/


