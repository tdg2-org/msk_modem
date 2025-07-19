`timescale 1ns / 1ps  // <time_unit>/<time_precision>
// ------------------------------------------------------------
// NCO / DDS model  (unsynthesizable)
//   • Phase accumulator width   : PHASE_WIDTH  (32 bits typical)
//   • Cos/Sin output word width : AMP_WIDTH    (signed, 16 bits typical)
//   • Runs every clock; no valid strobe needed
// ------------------------------------------------------------
module nco_dds_mdl #(
  parameter int PHASE_WIDTH = 32,  // accumulator & freq_word_i width
  parameter int AMP_WIDTH   = 16   // output amplitude word width
)(
  input  logic                           clk,
  input  logic                           rst,           // synchronous, active-high
  input  logic signed [PHASE_WIDTH-1:0]  freq_word_i,     // Δφ per clock (2-s-comp)
  output logic signed [PHASE_WIDTH-1:0]  phase_word_o,    // current phase accumulator
  output logic signed [AMP_WIDTH-1:0]    cos_out,       // cos(phase)
  output logic signed [AMP_WIDTH-1:0]    sin_out        // sin(phase)
);

  //--- constants for scaling --------------------------------
  localparam real TWO_PI   = 6.28318530717958647692;
  localparam real PH_LSB   = TWO_PI / (2.0 ** PHASE_WIDTH);   // rad per LSB
  localparam real AMP_ISCL = (1 << (AMP_WIDTH-1));            // real → int
  localparam int  AMP_MAX  = (1 << (AMP_WIDTH-1)) - 1;
  localparam int  AMP_MIN  = -(1 << (AMP_WIDTH-1));

  //--- phase accumulator ------------------------------------
  always_ff @(posedge clk) begin
    if (rst)
      phase_word_o <= '0;
    else
      phase_word_o <= phase_word_o + freq_word_i;   // wraps naturally
  end

  real  phase_r,cos_r,sin_r;
  int   cos_i,sin_i;

  //--- real-math lookup (unsynthesizable) -------------------
  always_comb begin
    // phase in radians
    phase_r = PH_LSB * $itor(phase_word_o);

    // compute sine & cosine
    cos_r = $cos(phase_r);
    sin_r = $sin(phase_r);

    // convert to fixed-point, with simple saturation
    cos_i  = $rtoi(cos_r * AMP_ISCL);
    sin_i  = $rtoi(sin_r * AMP_ISCL);

    if (cos_i > AMP_MAX) cos_i = AMP_MAX;
    if (cos_i < AMP_MIN) cos_i = AMP_MIN;
    if (sin_i > AMP_MAX) sin_i = AMP_MAX;
    if (sin_i < AMP_MIN) sin_i = AMP_MIN;

    cos_out = cos_i;
    sin_out = sin_i;
  end

endmodule

/*

  nco_dds_mdl #(
    .PHASE_WIDTH  (32),
    .AMP_WIDTH    (16) 
  ) nco_dds_mdl_inst (
    .clk          (clk),
    .rst          (rst),
    .freq_word_i  (),   
    .phase_word_o (),   
    .cos_out      (),   
    .sin_out      ()    
  );


*/