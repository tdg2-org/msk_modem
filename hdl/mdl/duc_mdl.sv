// Upconversion module: converts I/Q baseband (16-bit) to a real passband signal.
module upconverter_mdl #(
    parameter real IF = 50e6,   // Intermediate frequency in Hz.
    parameter real FS = 200e6   // Sample rate in Hz.
)(
    input  logic             clk,
    input  logic             reset,
    input  logic signed [15:0] I_data,  // In-phase component.
    input  logic signed [15:0] Q_data,  // Quadrature component.
    output logic signed [15:0] dac_out  // Real-valued (digitized) output to DAC.
);

   // Internal time-tracking variable.
   real t;
   real sample_period = 1.0 / FS;
   real two_pi = 6.283185307179586;

   initial begin
      t = 0.0;
   end

   always @(posedge clk) begin
      if (reset) begin
         t <= 0.0;
         dac_out <= 0;
      end else begin
         // Convert 16-bit integers to real.
         real I_real, Q_real, computed;
         I_real = $itor(I_data);
         Q_real = $itor(Q_data);
         // Upconversion: mix I and Q with cosine and sine.
         computed = I_real * $cos(two_pi * IF * t) - Q_real * $sin(two_pi * IF * t);
         // Convert the real result back to a 16-bit integer.
         dac_out <= $rtoi(computed);
         // Increment time by the sample period.
         t <= t + sample_period;
      end
   end

endmodule

