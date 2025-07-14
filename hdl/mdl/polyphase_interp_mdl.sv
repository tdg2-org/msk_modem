`timescale 1ns / 1ps  // <time_unit>/<time_precision>
//--------------------------------------------------------------------------
// Ideal fractional-delay interpolator (debug-only, non-synthesizable)
//
// • Uses a ±8-sample sinc kernel  → 17 taps
// • phase_int_i  : integer part 0…19  (coarse delay  p/20  symbols)
// • mu_i (Q0.27) : fractional part     0…1            symbols
//--------------------------------------------------------------------------
module polyphase_interp_mdl #
(
  parameter int OSF        = 20,  // polyphase branches
  parameter int TAPS_PPH   = 5 ,  // taps per branch
  parameter int WIQ        = 16,  // input sample width
  parameter int WO         = 18   // output sample width
)
(
  input  logic                  clk,
  input  logic                  rst,
  input  logic signed [WIQ-1:0] i_raw_i,
  input  logic signed [WIQ-1:0] q_raw_i,
  input  logic                  iq_raw_val_i,       
  input  logic [4:0]            phase_int_i,    // 0…19
  input  logic [26:0]           mu_i,           // not used here
  input  logic                  sym_valid_i,
  output logic signed [WO-1:0]  i_sym_o,
  output logic signed [WO-1:0]  q_sym_o,
  output logic                  sym_valid_o
);
//-------------------------------------------------------------------------------------------------
// 
//-------------------------------------------------------------------------------------------------
  localparam DEPTH = OSF * TAPS_PPH;
  
  logic signed [WIQ-1:0] idelay [DEPTH-1:0] = '{default:'0};
  logic signed [WIQ-1:0] qdelay [DEPTH-1:0] = '{default:'0};

  // newest sample at 0, left shift
  always_ff @(posedge clk) begin
    if (iq_raw_val_i) begin 
      idelay <= {idelay[DEPTH-2:0],i_raw_i};
      qdelay <= {qdelay[DEPTH-2:0],q_raw_i};
    end
  end
  
  // newest sample is at 99, right shift
//  always_ff @(posedge clk) begin
//    if (iq_raw_val_i) begin 
//      idelay <= {i_raw_i,idelay[DEPTH-1:1]};
//      qdelay <= {q_raw_i,qdelay[DEPTH-1:1]};
//    end
//  end


  localparam int LAG   = 8;   // ±8 raw samples
  real y_i, y_q, mu, t, w;    // high-precision accumulation
  int centre, idx;

  always_comb begin
    y_i = 0.0;
    y_q = 0.0;

    // fractional part μ in [0,1)
    mu = real'(mu_i) / (1<<27);

    //centre = 99 - phase_int_i; // newest sample is at 99, so the sample with raw offset phase_int_i is at 99-phase_int_i
    centre = phase_int_i; // newsest sample at idx 0
    if (centre < 0) centre += DEPTH;  // wrap (defensive)

    // 17-tap sinc window
    for (int n = -LAG; n <= +LAG; n++) begin
        idx = centre - n;               // raw offset n
        if (idx < 0)        idx += DEPTH;   // circular wrap
        else if (idx >= DEPTH) idx -= DEPTH;

        t = n - mu;                    // fractional distance
        w = (t == 0.0) ? 1.0 : $sin(3.14159265358979*t) / (3.14159265358979*t);

        y_i += real'( idelay[idx] ) * w;
        y_q += real'( qdelay[idx] ) * w;
    end
  end
                      // rtoi = real to int
  assign i_sym_o     = $rtoi( y_i );   // raw full-precision
  assign q_sym_o     = $rtoi( y_q );
  assign sym_valid_o = sym_valid_i;    // same symbol strobe


endmodule



/* instantiation template ------------------------------------------------------

polyphase_interp_mdl #(
  .OSF       (20),
  .TAPS_PPH  (5 ),
  .WIQ       (16),
  .WO        (18)
) polyphase_interp_inst (
  .clk           (),
  .rst           (),
  .i_raw_i       (),
  .q_raw_i       (),
  .phase_int_i   (),
  .mu_i          (),
  .sym_valid_i   (),
  .i_sym_o       (),
  .q_sym_o       (),
  .sym_valid_o   ()
);

*/
