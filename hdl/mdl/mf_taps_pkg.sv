
package mf_taps_pkg;

  localparam int  MF_NTAPS = 41;

  // 16‑bit half‑sine taps, peak = 32767
  localparam logic signed [15:0] MF_COEFFS [MF_NTAPS] = '{
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

endpackage