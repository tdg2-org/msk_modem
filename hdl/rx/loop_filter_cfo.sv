`timescale 1ns / 1ps  // <time_unit>/<time_precision>
// ------------------------------------------------------------
// PI loop-filter model  (unsynthesizable, simulation-only)
//   • 2-space indentation
//   • Fixed-point I/O, real math inside
//   • Saturates integrator and output to avoid wrap
// ------------------------------------------------------------
module loop_filter_cfo #(
  parameter int ERR_WIDTH   = 24,        // width of phase_err_i input
  parameter int PHASE_WIDTH = 32,        // width of freq_word_o output
  // loop gains (tune in simulation, then quantise for RTL)
  parameter real KP         = 1.2e-6,    // proportional gain
  parameter real KI         = 5.0e-8     // integral gain (per update)
)(
  input  logic                           clk,
  input  logic                           rst,          // synchronous, active-high
  input  logic                           err_valid_i,    // strobe from phase detector
  input  logic signed [ERR_WIDTH-1:0]    phase_err_i,    // Q1.(ERR_WIDTH-1)
  output logic                           freq_valid_o,   // aligned with freq_word_o
  output logic signed [PHASE_WIDTH-1:0]  freq_word_o     // Q1.(PHASE_WIDTH-1)
);

  //--- scaling factors --------------------------------------
  localparam real ERR_SCALE  = 1.0 / (1 << (ERR_WIDTH-1));     // int → real
  localparam real FREQ_SCALE = (1 << (PHASE_WIDTH-1));         // real → int
  localparam int  FREQ_MAX   =  (1 << (PHASE_WIDTH-1)) - 1;
  localparam int  FREQ_MIN   = -(1 << (PHASE_WIDTH-1));

  //--- integrator -------------------------------------------
  real integ_acc, err_r, prop_r, freq_r;
  int  freq_i;

  always_ff @(posedge clk) begin
    if (rst) begin
      integ_acc     <= 0.0;
      freq_word_o   <= '0;
      freq_valid_o  <= 1'b0;
    end else begin
      freq_valid_o  <= 1'b0;              // default low

      if (err_valid_i) begin
        // convert fixed-point error to real
        err_r   = $itor(phase_err_i) * ERR_SCALE;

        // proportional + integral terms
        prop_r    = KP * err_r;
        integ_acc = integ_acc + KI * err_r;   // accumulate only on valid
        freq_r    = prop_r + integ_acc;

        // back to fixed-point, with saturation
        freq_i  = $rtoi(freq_r * FREQ_SCALE);
        if (freq_i >  FREQ_MAX) begin
          freq_i    =  FREQ_MAX;
          integ_acc = freq_i / FREQ_SCALE - prop_r;  // anti-wind-up clamp
        end else if (freq_i < FREQ_MIN) begin
          freq_i    =  FREQ_MIN;
          integ_acc = freq_i / FREQ_SCALE - prop_r;
        end

        freq_word_o  <= freq_i;
        freq_valid_o <= 1'b1;            // one-cycle latency relative to phase_err_i
      end
    end
  end

endmodule

/*

  loop_filter_cfo_mdl #(
    .ERR_WIDTH    (24    ), 
    .PHASE_WIDTH  (32    ), 
    .KP           (1.2e-6), 
    .KI           (5.0e-8)  
  ) loop_filter_cfo_mdl_inst (
    .clk          (clk),
    .rst          (rst),
    .err_valid_i  (),   
    .phase_err_i  (),   
    .freq_valid_o (),   
    .freq_word_o  ()    
  );


*/