`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// ------------------------------------------------------------
// Derotator model (unsynthesizable, simulation‑only)
//   • 2‑space indentation to match your style preference
//   • Fixed‑point Q1.(WIDTH‑1) on I/Q samples and phase word
// ------------------------------------------------------------
module derotator_mdl #(
  parameter int WIDTH        = 16,
  parameter int PHASE_WIDTH  = 32
)(
  input  logic                           clk,
  input  logic                           rst,            // sync reset (active‑high)
  input  logic                           sym_valid_in,   // 1 = current I/Q is a symbol‑center sample
  input  logic signed [WIDTH-1:0]        din_i,
  input  logic signed [WIDTH-1:0]        din_q,
  input  logic signed [PHASE_WIDTH-1:0]  freq_word,
  output logic                           sym_valid_out,  // aligned with dout_*
  output logic signed [WIDTH-1:0]        dout_i,
  output logic signed [WIDTH-1:0]        dout_q
);

  // localparam used for scaling between int<->real
  localparam real TWO_PI = 6.28318530717958647692;
  localparam int  MAX_IQ = (1 << (WIDTH-1)) - 1;
  localparam int  MIN_IQ = -(1 << (WIDTH-1));
  localparam real SCALE  = 1.0 / (1 << (WIDTH-1));           // int → real
  localparam real ISCALE = (1 << (WIDTH-1));                 // real → int
  localparam real PH_LSB = TWO_PI / (2.0 ** PHASE_WIDTH);


  // phase accumulator
  logic signed [PHASE_WIDTH-1:0] phase_acc;

  // ==========================================================
  // Phase accumulation (wraps naturally on overflow)
  // ==========================================================
  always_ff @(posedge clk or posedge rst)
    if (rst) phase_acc <= '0;
    else     phase_acc <= phase_acc + freq_word;

  // ==========================================================
  // Unsynthesizable derotation using real math
  // ==========================================================
  real ri,rq,phase,cos_p,sin_p,ro_i,ro_q;
  int tmp_i,tmp_q;

  always_comb begin
    // convert fixed‑point ints to real in range [‑1, +1)
    ri  = $itor(din_i) * SCALE;
    rq  = $itor(din_q) * SCALE;

    // phase in radians (map int phase_acc → 0 … 2π)
    //phase = TWO_PI * $itor(phase_acc) / (1 << PHASE_WIDTH);
    phase = PH_LSB * $itor(phase_acc);

    // complex multiply by e^(‑j*phase)
    cos_p = $cos(phase);
    sin_p = $sin(phase);

    ro_i  =  ri * cos_p + rq * sin_p;  // I' =  I·cos + Q·sin
    ro_q  = -ri * sin_p + rq * cos_p;  // Q' = -I·sin + Q·cos

    // convert back to fixed‑point with rounding
    tmp_i = $rtoi(ro_i * ISCALE);
    tmp_q = $rtoi(ro_q * ISCALE);

    // simple saturation to WIDTH‑bit signed range
    if (tmp_i >  MAX_IQ) tmp_i =  MAX_IQ;
    if (tmp_i <  MIN_IQ) tmp_i =  MIN_IQ;
    if (tmp_q >  MAX_IQ) tmp_q =  MAX_IQ;
    if (tmp_q <  MIN_IQ) tmp_q =  MIN_IQ;

    dout_i = tmp_i;
    dout_q = tmp_q;
  end

  assign sym_valid_out = sym_valid_in;

endmodule

/*

  derotator_mdl #(
    .WIDTH        (16),
    .PHASE_WIDTH  (32)
  ) derotator_mdl_inst (
    .clk            (clk),
    .rst            (rst),            // sync reset (active‑high)
    .sym_valid_in   (),   // 1 = current I/Q is a symbol‑center sample
    .din_i          (),
    .din_q          (),
    .freq_word      (),
    .sym_valid_out  (),  // aligned with dout_*
    .dout_i         (),
    .dout_q         ()
  );


*/