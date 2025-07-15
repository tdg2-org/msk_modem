// half_sine_mf_int16_fixed.sv
// 2‑symbol half‑sine matched filter
// – external samples: signed 16‑bit
// – coefficients: signed 16‑bit, hard‑wired
// – internal math: real  (behavioural, non‑synthesizable)
//
// Scaling rule
//   int16  +32767 … –32768  ↔  real +1.0 … –1.0
//
// Taps were computed with
//   h[n] = sin(π·(1−|τ|)/2),  τ = (n−20)/20,  |τ|<1
//   quantised: round(h · 32767)

module msk_mf #(
  parameter int WI  = 16,  // input width
  parameter int WO  = 16   // output width
)(
  input  logic                 clk,
  input  logic signed [WI-1:0] din,
  input  logic                 din_val,
  output logic signed [WO-1:0] dout,
  output logic                 dout_val
);

  // -------------------- constants -----------------------------------
  localparam int  NUM_TAPS = 41;
  localparam real INV_GAIN = 1.0 / 19.99883943703;   // 1 / Σ h²
  localparam real I2R      = 1.0   / 32768.0;        // int16 → real
  localparam real R2I      = 32768.0;                // real  → int16

  // 16‑bit half‑sine taps, peak = 32767
  localparam logic signed [15:0] COEFFS [NUM_TAPS] = '{
    16'sd0,      16'sd2571, 16'sd5126, 16'sd7649, 16'sd10126,
    16'sd12539,  16'sd14876, 16'sd17121, 16'sd19260, 16'sd21280,
    16'sd23170,  16'sd24916, 16'sd26509, 16'sd27938, 16'sd29196,
    16'sd30273,  16'sd31163, 16'sd31862, 16'sd32364, 16'sd32666,
    16'sd32767,  16'sd32666, 16'sd32364, 16'sd31862, 16'sd31163,
    16'sd30273,  16'sd29196, 16'sd27938, 16'sd26509, 16'sd24916,
    16'sd23170,  16'sd21280, 16'sd19260, 16'sd17121, 16'sd14876,
    16'sd12539,  16'sd10126, 16'sd7649,  16'sd5126,  16'sd2571,
    16'sd0
  };

  // -------------------- state ---------------------------------------
  real shift_reg [NUM_TAPS];   // delay‑line (real)

  // -------------------- clocked process -----------------------------
  real din_r, acc, y;
  int  tmp;

  always_ff @(posedge clk) begin
    dout_val <= din_val;

    if (!din_val) begin
      dout <= '0;
    end
    else begin
      // 1) int16 → real
      din_r = din * I2R;

      // 2) shift (blocking so new sample is used immediately)
      for (int k = NUM_TAPS-1; k > 0; k--) shift_reg[k] = shift_reg[k-1];
      shift_reg[0] = din_r;

      // 3) MAC
      acc = 0.0;
      for (int j = 0; j < NUM_TAPS; j++)
        acc += shift_reg[j] * (COEFFS[j] * I2R);   // coeff int16 → real

      // 4) normalise and map back to int16
      y = acc * INV_GAIN;     // keeps |y| ≤ 1 for |din| ≤ 1
      
      if (y >= 0.999969)      tmp =  32767;
      else if (y <= -1.0)     tmp = -32768;
      else                    tmp = $rtoi(y * R2I);

      dout <= tmp[WO-1:0];
    end
  end
endmodule


/*
module msk_mf #(
  parameter int WI  = 16,      // input width
  parameter int WO  = 16       // output width
)(
  input   logic                 clk,
  input   logic signed [WI-1:0] din,   // one sample per clk
  input   logic                 din_val,
  output  logic signed [WO-1:0] dout,  // filtered sample
  output  logic                 dout_val
);

  // --------------------------------------------------------------------
  //  CONSTANT COEFFICIENT TABLE  (41 taps, symmetric)
  // --------------------------------------------------------------------
  localparam int NUM_TAPS = 41;

  // Signed‑16 constants, peak = 32767
  localparam logic signed [15:0] COEFFS [0:NUM_TAPS-1] = '{
    16'sd0,      16'sd2571, 16'sd5126, 16'sd7649, 16'sd10126,
    16'sd12539,  16'sd14876, 16'sd17121, 16'sd19260, 16'sd21280,
    16'sd23170,  16'sd24916, 16'sd26509, 16'sd27938, 16'sd29196,
    16'sd30273,  16'sd31163, 16'sd31862, 16'sd32364, 16'sd32666,
    16'sd32767,  16'sd32666, 16'sd32364, 16'sd31862, 16'sd31163,
    16'sd30273,  16'sd29196, 16'sd27938, 16'sd26509, 16'sd24916,
    16'sd23170,  16'sd21280, 16'sd19260, 16'sd17121, 16'sd14876,
    16'sd12539,  16'sd10126, 16'sd7649,  16'sd5126,  16'sd2571,
    16'sd0
  };

  // --------------------------------------------------------------------
  //  Delay‑line (real) – holds the last 41 input samples
  // --------------------------------------------------------------------
  real shift_reg [0:NUM_TAPS-1];

  // --------------------------------------------------------------------
  //  Clocked FIR
  // --------------------------------------------------------------------

  real din_r, acc;
  real acc_max=0, acc_min=0; // debug
  int tmp;

  always_ff @(posedge clk) begin
    
    din_r = din / 32768.0; // 1. convert new input sample to real in [‑1, +1)
    acc = 0.0;

    if (din_val) begin 
      for (int k = NUM_TAPS-1; k > 0; k--)  // 2. shift delay line and insert newest sample
        shift_reg[k] <= shift_reg[k-1];
      shift_reg[0] <= din_r;

      for (int j = 0; j < NUM_TAPS; j++)  // 3. MAC: Σ  shift_reg[j] * coeff[j]
        acc += shift_reg[j] * (COEFFS[j] / 32768.0);  // int16 → real

      // 4. scale back to int16 and saturate
      if (acc >= 0.999969)  // 32767 / 32768
        tmp = 32767;
      else if (acc <= -1.0)
        tmp = -32768;
      else
        tmp = $rtoi(acc * 32768.0);

      dout <= tmp[15:0];
    
      // debug
      if (acc > acc_max) acc_max <= acc;
      if (acc < acc_min) acc_min <= acc;
      // end debug


    end else dout <= '0;

    dout_val <= din_val;

  end

endmodule

/*

  msk_mf #(
    .WI (16),
    .WO (16)
  ) msk_mf_inst (
    .clk      (),
    .din      (),
    .din_val  (),
    .dout     (),
    .dout_val ()
  );


  msk_mf msk_mf_inst (
    .clk      (),
    .din      (),
    .din_val  (),
    .dout     (),
    .dout_val ()
  );



*/