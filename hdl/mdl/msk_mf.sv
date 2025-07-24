`timescale 1ns / 1ps  // <time_unit>/<time_precision>

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

import mf_taps_pkg::*;

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
  localparam int  NUM_TAPS = MF_NTAPS; //pkg file mf_taps_pkg
  localparam real INV_GAIN = 1.0 / 19.99883943703;   // 1 / Σ h²
  localparam real I2R      = 1.0   / 32768.0;        // int16 → real
  localparam real R2I      = 32768.0;                // real  → int16

  // 16‑bit half‑sine taps, peak = 32767
  localparam logic signed [15:0] COEFFS [NUM_TAPS] = MF_COEFFS; //pkg file mf_taps_pkg

  // -------------------- state ---------------------------------------
  real shift_reg [NUM_TAPS];   // delay‑line (real)

  // -------------------- clocked process -----------------------------
  real din_r, acc, y;
  int  tmp;

  logic signed [WO-1:0] dout_pre;
  logic dout_val_pre;

  always_ff @(posedge clk) begin
    dout_val_pre <= din_val;

    if (!din_val) begin
      dout_pre <= '0;
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

      dout_pre <= tmp[WO-1:0];
    end
  end

  //assign dout     = dout_pre;
  //assign dout_val = dout_val_pre;

/* model delay in xilinx IP fir_mf */

  array_shift_delay # (
    .LEN(26), .DW(WO)
  ) array_shift_delay (
    .clk        (clk)   ,
    .rst        ('0)   ,
    .d_in       (dout_pre)   ,
    .d_in_val   (dout_val_pre)   ,
    .d_out      (dout)   ,
    .d_out_val  (dout_val)
  );




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