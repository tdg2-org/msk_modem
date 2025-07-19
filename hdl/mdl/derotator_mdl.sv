`timescale 1ns / 1ps  // <time_unit>/<time_precision>
// ------------------------------------------------------------
// Derotator model (non‑synthesizable, uses external DDS)
//   • I/Q  : Q1.(WIDTH‑1)
//   • Cos/Sin : Q1.(DDS_WIDTH‑1)
// ------------------------------------------------------------
module derotator_mdl #(
  parameter int WIDTH        = 16,
  parameter int DDS_WIDTH    = 16,
  parameter int PHASE_WIDTH  = 32  // kept for interface symmetry
)(
  input  logic                           clk,
  input  logic                           rst,            // sync reset (active‑high)
  input  logic                           sym_valid_in,   // 1 = symbol‑center sample
  input  logic signed [WIDTH-1:0]        din_i,
  input  logic signed [WIDTH-1:0]        din_q,
  input  logic signed [DDS_WIDTH-1:0]    cos_in,         // cos(phase)
  input  logic signed [DDS_WIDTH-1:0]    sin_in,         // sin(phase)
  output logic                           sym_valid_out,  // aligned with dout_*
  output logic signed [WIDTH-1:0]        dout_i,
  output logic signed [WIDTH-1:0]        dout_q
);

  //––– scaling factors ––––––––––––––––––––––––––––––––––––––
  localparam int  MAX_IQ   = (1 << (WIDTH-1)) - 1;
  localparam int  MIN_IQ   = -(1 << (WIDTH-1));
  localparam real IQ_SCALE = 1.0 / (1 << (WIDTH-1));      // int  → real
  localparam real IQ_ISCL  = (1 << (WIDTH-1));            // real → int
  localparam real AMP_SCALE = 1.0 / (1 << (DDS_WIDTH-1)); // cos/sin int → real

  //––– combinational derotation –––––––––––––––––––––––––––––

  real  ri,rq,cosr,sinr,ro_i,ro_q;
  int   tmp_i,tmp_q;

  always_comb begin
    // int → real
    ri   = $itor(din_i) * IQ_SCALE;
    rq   = $itor(din_q) * IQ_SCALE;
    cosr = $itor(cos_in) * AMP_SCALE;
    sinr = $itor(sin_in) * AMP_SCALE;

    // complex multiply by e^(‑jθ)
    ro_i =  ri * cosr + rq * sinr;
    ro_q = -ri * sinr + rq * cosr;

    // real → int with rounding
    tmp_i = $rtoi(ro_i * IQ_ISCL);
    tmp_q = $rtoi(ro_q * IQ_ISCL);

    // saturate to WIDTH bits
    if (tmp_i > MAX_IQ) tmp_i = MAX_IQ;
    if (tmp_i < MIN_IQ) tmp_i = MIN_IQ;
    if (tmp_q > MAX_IQ) tmp_q = MAX_IQ;
    if (tmp_q < MIN_IQ) tmp_q = MIN_IQ;

    dout_i = tmp_i;
    dout_q = tmp_q;
  end

  // pass‑through (no added latency)
  assign sym_valid_out = sym_valid_in;

endmodule

/*

  derotator_mdl #(
    .WIDTH        (16),
    .DDS_WIDTH    (16),
    .PHASE_WIDTH  (32) 
  ) derotator_mdl_inst (
    .clk            (clk),
    .rst            (rst),
    .sym_valid_in   (),
    .din_i          (),
    .din_q          (),
    .cos_in         (),
    .sin_in         (),
    .sym_valid_out  (),
    .dout_i         (),
    .dout_q         ()
  );


*/