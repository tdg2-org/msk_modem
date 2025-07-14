`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// √RC matched filter  – SIMULATION-ONLY
//   • OSF = 20  (200 MHz / 10 MHz symbol rate)
//   • Roll-off   : BETA   (0.0 … 1.0)
//   • Span       : SPAN_SYM symbols  (total taps = OSF*SPAN_SYM + 1)
//   • Coeffs calculated in real math at elaboration; then quantised Q1.15
// -----------------------------------------------------------------------------
module rrc_mf_mdl_0 #
(
  parameter int   OSF      = 20,      // samples / symbol
  parameter real  BETA     = 0.25,    // roll-off
  parameter int   SPAN_SYM = 6,       // filter length ±SPAN_SYM symbols
  parameter int   WIQ      = 16,      // input width
  parameter int   WO       = 18       // output width
)
(
  input  logic                       clk,
  input  logic                       rst,

  // 200 MHz oversampled baseband
  input  logic signed [WIQ-1:0]      i_in,
  input  logic signed [WIQ-1:0]      q_in,
  input  logic                       iq_val_i,

  // filtered output  (1-clock latency)
  output logic signed [WO-1:0]       i_out,
  output logic signed [WO-1:0]       q_out,
  output logic                       iq_val_o
);

  // ---------------------------------------------------------------------------
  // 1.  calculate ideal √RC taps (real)
  // ---------------------------------------------------------------------------
  localparam int TAPS = OSF * SPAN_SYM + 1;   // e.g. 6*20+1 = 121
  localparam real PI    = 3.141592653589793;
  int  k;

  real h_real [TAPS-1:0];
  real x, num, den, alpha, t, sum2, g;

  function automatic real abs(input real x);
    return (x < 0) ? -x : x;
  endfunction


  initial begin
    k  = 0;                    // array index

    // time index n spans ±SPAN_SYM*OSF/2 raw samples  (even-length symmetric)
    for (int n = - (SPAN_SYM*OSF)/2; n <= (SPAN_SYM*OSF)/2; n++) begin
        t = n / real'(OSF);    // time in symbol units

        alpha = BETA;

        if (n == 0) begin
            x = 1.0 - alpha + (4.0*alpha/PI);
        end
        else if (alpha != 0.0 && abs(t) == 1.0/(4.0*alpha)) begin
            // singularity at |t| = T/4β
            num = (alpha / $sqrt(2.0)) *
                  ((1.0 + 2.0/PI) * $sin(PI/(4.0*alpha)) +
                   (1.0 - 2.0/PI) * $cos(PI/(4.0*alpha)));
            x = num;   // denominator = 1
        end
        else begin
            num = $sin(PI*t*(1.0-alpha)) +
                  4.0*alpha*t*$cos(PI*t*(1.0+alpha));
            den = PI*t*(1.0 - (4.0*alpha*t)*(4.0*alpha*t));
            x   = num / den;
        end

        h_real[k++] = x;
    end

    // normalise energy to 1.0  (MF gain = +3 dB)
    sum2 = 0.0;
    foreach (h_real[m]) sum2 += h_real[m]*h_real[m];
    g = 1.0 / $sqrt(sum2);
    foreach (h_real[m]) h_real[m] *= g;
  end

  // ---------------------------------------------------------------------------
  // 2. quantise to Q1.15  (signed 16-bit)
  // ---------------------------------------------------------------------------
  logic signed [15:0] h_fix [TAPS-1:0];
  initial foreach (h_fix[m])
      h_fix[m] = $rtoi( h_real[m] * 32767.0 );

  // ---------------------------------------------------------------------------
  // 3. 121-tap shift-register delay line (newest sample at index 0)
  // ---------------------------------------------------------------------------
  logic signed [WIQ-1:0] idelay [TAPS-1:0] = '{default:'0};
  logic signed [WIQ-1:0] qdelay [TAPS-1:0] = '{default:'0};

  always_ff @(posedge clk)
    if (iq_val_i) begin
        idelay <= { i_in , idelay[TAPS-1:1] };
        qdelay <= { q_in , qdelay[TAPS-1:1] };
    end

  // ---------------------------------------------------------------------------
  // 4. convolution  (real*int → 32-bit signed), accumulate in 40-bit
  // ---------------------------------------------------------------------------
  localparam int PROD_W = WIQ + 16;          // 32
  localparam int ACC_W  = 40;
  logic signed [ACC_W-1:0] acc_i, acc_q;
  logic                    val_d;

  always_ff @(posedge clk) begin
    acc_i = '0;
    acc_q = '0;
    if (iq_val_i) begin
        for (int k = 0; k < TAPS; k++) begin
            acc_i += idelay[k] * h_fix[k];
            acc_q += qdelay[k] * h_fix[k];
        end
    end
    val_d <= iq_val_i;   // 1-clock latency
  end

  // ---------------------------------------------------------------------------
  // 5. truncate / round to WO bits (simple MSB slice)
  //     Q1.15 taps ⇒ shift right 15 to return to original scale
  // ---------------------------------------------------------------------------
  localparam int SHIFT = 15;
  assign i_out    = acc_i[ACC_W-1 -: WO];    // keep MSBs (same as >>15)
  assign q_out    = acc_q[ACC_W-1 -: WO];
  assign iq_val_o = val_d;

endmodule

/*

  rrc_mf_mdl_1 #
  (
    .OSF      (20   ),  
    .BETA     (0.25 ),  
    .SPAN_SYM (6    ),  
    .WI       (16   ),  
    .WO       (18   )   
  ) rrc_mf_mdl_inst1 (
    .clk      (),
    .rst      (),
    .i_in     (),
    .q_in     (),
    .iq_val_i (),
    .i_out    (),
    .q_out    (),
    .iq_val_o ()
  );


  rrc_mf_mdl_1  rrc_mf_mdl_inst1 (
    .clk      (clk    ),
    .rst      (rst    ),
    .i_in     (i_fir  ),
    .q_in     (q_fir  ),
    .iq_val_i (iq_val ),
    .i_out    (),
    .q_out    (),
    .iq_val_o ()
  );



*/