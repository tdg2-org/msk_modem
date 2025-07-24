`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// coarse_cfo_estimator_model.sv
// 2‑space indentation throughout  (user preference)
// Symbol‑rate, blind (NDA) CFO estimator using conjugate‑product average.
// Produces one signed NCO frequency word when 'done' pulses high.

module coarse_cfo #(
  parameter int  PHASE_ACC_BITS = 32,          // NCO accumulator width
  parameter int  AVG_LEN        = 128,         // # symbols to average (power‑of‑2 preferred)
  parameter int  IQ_WIDTH       = 16           // Q1.(IQ_WIDTH‑1) fixed‑point
)(
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     enable,     // high during acquisition
  input  logic                     vld_in,     // one strobe per symbol
  input  logic signed [IQ_WIDTH-1:0] i_in,     // timing‑loop I sample
  input  logic signed [IQ_WIDTH-1:0] q_in,     // timing‑loop Q sample
  output logic signed [PHASE_ACC_BITS-1:0] freq_word, // coarse word for NCO
  output logic                     done        // 1‑clk pulse when estimate valid
);

  // --------------------------------------------------------------------------
  // Internal fixed‑point storage for previous sample
  // --------------------------------------------------------------------------
  logic signed [IQ_WIDTH-1:0] i_prev, q_prev;

  // --------------------------------------------------------------------------
  // Accumulators (REAL only in this model; replace with fixed‑point in RTL)
  // --------------------------------------------------------------------------
  real re_sum, im_sum, i_cur, q_cur, i_prv, q_prv, re_mult, im_mult, dphi, scale;
  int  sample_cnt;

  // --------------------------------------------------------------------------
  // Helper function: convert Q1.(IQ_WIDTH‑1) to real in [‑1, +1)
  // --------------------------------------------------------------------------
  function real fxp_to_real (input logic signed [IQ_WIDTH-1:0] val);
    return val / real'(1 << (IQ_WIDTH-1));
  endfunction

  // --------------------------------------------------------------------------
  // Conjugate‑product averaging
  // --------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      i_prev      <= '0;
      q_prev      <= '0;
      re_sum      <= 0.0;
      im_sum      <= 0.0;
      sample_cnt  <= 0;
      freq_word   <= '0;
      done        <= 1'b0;
    end
    else begin
      done <= 1'b0;                       // default: no result this cycle

      if (enable && vld_in) begin
        // 1. Convert current & previous samples to real
        i_cur = fxp_to_real(i_in);
        q_cur = fxp_to_real(q_in);
        i_prv = fxp_to_real(i_prev);
        q_prv = fxp_to_real(q_prev);

        // 2. z_k = r_k * conj(r_{k-1})
        re_mult =  i_cur * i_prv + q_cur * q_prv;
        im_mult =  q_cur * i_prv - i_cur * q_prv;

        // 3. Accumulate
        re_sum     <= re_sum + re_mult;
        im_sum     <= im_sum + im_mult;
        sample_cnt <= sample_cnt + 1;

        // 4. When AVG_LEN symbols collected → compute CFO estimate
        if (sample_cnt == (AVG_LEN-1)) begin
          // atan2 gives mean phase step  [‑π, π]
          dphi  = $atan2(im_sum + im_mult, re_sum + re_mult);

          // Convert to NCO word:   Δθ_word = dphi * 2^N / (2π)
          scale = (2.0 ** PHASE_ACC_BITS) / (2.0 * $acos(-1.0));
          freq_word  <= $rtoi(dphi * scale);

          done        <= 1'b1;           // one‑cycle valid flag

          // 5. Reset accumulators for next run
          re_sum     <= 0.0;
          im_sum     <= 0.0;
          sample_cnt <= 0;
        end

        // 6. Shift register for next iteration
        i_prev <= i_in;
        q_prev <= q_in;
      end

      // If enable de‑asserts (e.g., loop in TRACK mode), clear state
      if (!enable) begin
        re_sum     <= 0.0;
        im_sum     <= 0.0;
        sample_cnt <= 0;
      end
    end
  end

endmodule
/*

  coarse_cfo_mdl #(
    .PHASE_ACC_BITS (32   ),  // NCO accumulator width
    .AVG_LEN        (128  ), // # symbols to average (power‑of‑2 preferred)
    .IQ_WIDTH       (16   )   // Q1.(IQ_WIDTH‑1) fixed‑point
  ) coarse_cfo_mdl_inst (
    .clk        (     ),
    .rst_n      (     ),
    .enable     (     ), // high during acquisition
    .vld_in     (     ), // one strobe per symbol
    .i_in       (     ), // timing‑loop I sample
    .q_in       (     ), // timing‑loop Q sample
    .freq_word  (     ), // coarse word for NCO
    .done       (     )  // 1‑clk pulse when estimate valid
  );

  coarse_cfo_mdl coarse_cfo_mdl_inst (
    .clk        (     ),
    .rst_n      (     ),
    .enable     (     ), // high during acquisition
    .vld_in     (     ), // one strobe per symbol
    .i_in       (     ), // timing‑loop I sample
    .q_in       (     ), // timing‑loop Q sample
    .freq_word  (     ), // coarse word for NCO
    .done       (     )  // 1‑clk pulse when estimate valid
  );


*/