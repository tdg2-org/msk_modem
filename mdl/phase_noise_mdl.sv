module phase_noise_mdl #(
    parameter real PHASE_NOISE_STD_DEV = 0.01  // Standard deviation of phase noise in radians
)(
    input  logic        clk,
    input  logic        reset,
    input  logic signed [15:0] i_in,  // In-phase component
    input  logic signed [15:0] q_in,  // Quadrature component
    output logic signed [15:0] i_out, // Noisy In-phase component
    output logic signed [15:0] q_out  // Noisy Quadrature component
);

    real phase_noise, u1, u2, theta;
    real cos_theta, sin_theta;
    real i_temp, q_temp;
    int unsigned rand1, rand2;

    always_comb begin
      if (PHASE_NOISE_STD_DEV == 0.0) begin 
        i_out <= i_in;
        q_out <= q_in;
      end else begin
        // Generate two uniform random numbers (0,1)
        rand1 = $urandom_range(1, 10000);
        rand2 = $urandom_range(1, 10000);
        u1 = real'(rand1) / 10000.0;
        u2 = real'(rand2) / 10000.0;

        // Gaussian-distributed phase noise using Box-Muller transform
        phase_noise = PHASE_NOISE_STD_DEV * $sqrt(-2.0 * $ln(u1)) * $cos(2.0 * 3.141592653589793 * u2);

        // Compute phase shift components
        cos_theta = $cos(phase_noise);
        sin_theta = $sin(phase_noise);

        // Apply phase rotation
        i_temp = real'(i_in) * cos_theta - real'(q_in) * sin_theta;
        q_temp = real'(i_in) * sin_theta + real'(q_in) * cos_theta;

        // Convert back to 16-bit signed values with clipping
        i_out = (i_temp > 32767) ? 16'sh7FFF :
                (i_temp < -32768) ? 16'sh8000 :
                signed'(int'(i_temp));

        q_out = (q_temp > 32767) ? 16'sh7FFF :
                (q_temp < -32768) ? 16'sh8000 :
                signed'(int'(q_temp));
      end
    end

endmodule
