// half_sine_mf_int16.sv  – 2‑symbol half‑sine matched filter
// • External interface: signed 16‑bit samples (two’s‑complement)
// • Internals use real; therefore NON‑SYNTHESIZABLE.
// • Scaling rule
//     int16  +32767 … ‑32768   ↔   real  +1.0 … ‑1.0
// • Peak gain of the matched filter ≈ 1.0, so output fits the same range.

module msk_mf0 #(
  int SAMPLES_PER_SYM = 20,
  int NUM_TAPS       = SAMPLES_PER_SYM * 2 + 1,
  parameter int WI  = 16,      // input width
  parameter int WO  = 16       // output width
) (
  input  logic                  clk,
  input  logic signed [WI-1:0]  din,   // int16 sample per clk
  output logic signed [WO-1:0]  dout   // int16 filtered sample
);

  // ------------------------------------------------------------------
  //  Coefficients and delay line (real)
  // ------------------------------------------------------------------
  localparam real PI    = 3.141592653589793;

  real coeffs    [NUM_TAPS];
  real shift_reg [NUM_TAPS] = '{default:'0};

  real tau, din_r, acc;
  int tmp;

  function automatic real abs(input real x);
    return (x < 0) ? -x : x;
  endfunction


  initial begin
    for (int i = 0; i < NUM_TAPS; i++) begin
      tau = (i - (NUM_TAPS-1)/2.0) / SAMPLES_PER_SYM; // -1 … +1
      if (tau > -1.0 && tau < 1.0)
        coeffs[i] = $sin(PI * (1.0 - abs(tau)) / 2.0);
      else
        coeffs[i] = 0.0;
      //shift_reg[i] = 0.0;
    end
  end

  // ------------------------------------------------------------------
  //  Clocked FIR with int16 ⇄ real conversion
  // ------------------------------------------------------------------
  always_ff @(posedge clk) begin
    // 1. convert new input sample to real in [-1, 1)
    din_r = din / 32768.0;

    // 2. update delay line
    for (int k = NUM_TAPS-1; k > 0; k--)
      shift_reg[k] <= shift_reg[k-1];
    shift_reg[0] <= din_r;

    // 3. multiply‑accumulate
    acc = 0.0;
    for (int j = 0; j < NUM_TAPS; j++)
      acc += coeffs[j] * shift_reg[j];

    // 4. scale back to int16 with saturation
    
    if (acc >=  0.999969)       // 32767 / 32768
      tmp =  32767;
    else if (acc <= -1.0)
      tmp = -32768;
    else
      tmp = $rtoi(acc * 32768.0);

    dout <= tmp[15:0];
  end

endmodule

/*

msk_mf0 #(
  .SAMPLES_PER_SYM  (),
  .NUM_TAPS         (),
  .WI               (),
  .WO               ()
) msk_mf0_inst (
  .clk (),
  .din (),
  .dout()
);


msk_mf0 msk_mf0_inst (
  .clk (clk),
  .din (),
  .dout()
);



*/