// Downconversion module: converts a real ADC input at IF to I/Q baseband.
module downconverter_mdl #(
    parameter real IF = 50e6,   // Intermediate frequency in Hz.
    parameter real FS = 200e6   // Sample rate in Hz.
)(
    input  logic       clk,
    input  logic       reset,
    input  logic signed [15:0] adc_in,   // ADC input (digitized real signal).
    output logic signed [15:0] I_out,    // Recovered In-phase component.
    output logic signed [15:0] Q_out     // Recovered Quadrature component.
);

   // Internal time tracking.
   real t;
   real sample_period = 1.0 / FS;
   real two_pi = 6.283185307179586;

   initial begin
      t = 0.0;
   end

   always @(posedge clk) begin
      if (reset) begin
         t <= 0.0;
         I_out <= 0;
         Q_out <= 0;
      end else begin
         real adc_in_real, mix_I, mix_Q;
         // Convert the ADC input to real.
         adc_in_real = $itor(adc_in);
         // Mix the ADC input with cosine and -sine to extract I and Q.
         mix_I = adc_in_real * $cos(two_pi * IF * t);
         mix_Q = -adc_in_real * $sin(two_pi * IF * t);
         // Convert the mixed results back to 16-bit integers.
         I_out <= $rtoi(mix_I);
         Q_out <= $rtoi(mix_Q);
         // Increment time.
         t <= t + sample_period;
      end
   end

endmodule