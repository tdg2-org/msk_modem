module multipath_fading_mdl #(
    parameter int NUM_PATHS = 3,         // Number of multipath components
    parameter real DOPPLER_FREQ = 100.0, // Maximum Doppler shift in Hz
    parameter real SAMPLE_RATE = 200.0e6,// Sample rate in Hz
    parameter real K_FACTOR = 0.0        // Rician K-factor (0 = Rayleigh, >0 = Rician)
)(
    input  logic        clk,
    input  logic        reset,
    input  logic signed [15:0] i_in,  // In-phase input
    input  logic signed [15:0] q_in,  // Quadrature input
    output logic signed [15:0] i_out, // Faded In-phase output
    output logic signed [15:0] q_out  // Faded Quadrature output
);


generate
  if ((NUM_PATHS == 0) && (DOPPLER_FREQ == 0.0) && (K_FACTOR == 0.0)) begin
    assign i_out = i_in;
    assign q_out = q_in;
  end else begin 

    // Arrays for path delays and gains
    real path_gain[NUM_PATHS];
    real doppler_phase[NUM_PATHS];
    real doppler_step,u1,u2;
    real cos_phase[NUM_PATHS], sin_phase[NUM_PATHS];
    real i_temp, q_temp;
    int unsigned rand1, rand2;
    real total_gain;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            i_out <= 16'sd0;
            q_out <= 16'sd0;
            total_gain = 0.0;

            // Initialize path gains (Rayleigh or Rician)
            for (int i = 0; i < NUM_PATHS; i++) begin
                rand1 = $urandom_range(1, 9999); // Avoid 1.0
                rand2 = $urandom_range(1, 10000);

                u1 = real'(rand1) / 10000.0;
                u2 = real'(rand2) / 10000.0;

                if (K_FACTOR == 0) begin
                    // Rayleigh Fading: Generate path gain using Gaussian distribution
                    path_gain[i] = $sqrt(-2.0 * $ln(u1)) * 
                                   $cos(2.0 * 3.141592653589793 * u2);
                end else begin
                    // Rician Fading: Strong LoS + multipath component
                    path_gain[i] = $sqrt(K_FACTOR / (K_FACTOR + 1)) + 
                                   $sqrt(1 / (K_FACTOR + 1)) * 
                                   $sqrt(-2.0 * $ln(u1)) * 
                                   $cos(2.0 * 3.141592653589793 * u2);
                end
                
                total_gain += path_gain[i];

                // Randomize initial Doppler phase
                doppler_phase[i] = 2.0 * 3.141592653589793 * (real'($urandom_range(0, 10000)) / 10000.0);
            end

            // Normalize gains to prevent attenuation issues
            if (total_gain < 1e-6) total_gain = 1.0; // Prevent division by zero
            for (int i = 0; i < NUM_PATHS; i++) begin
                path_gain[i] /= total_gain;
            end

        end else begin
            // Reset temporary outputs
            i_temp = 0.0;
            q_temp = 0.0;

            for (int i = 0; i < NUM_PATHS; i++) begin
                // Compute Doppler phase update
                doppler_step = 2.0 * 3.141592653589793 * (DOPPLER_FREQ / SAMPLE_RATE);
                doppler_phase[i] = doppler_phase[i] + doppler_step;

                // Keep phase in 0 to 2π range
                if (doppler_phase[i] > 2.0 * 3.141592653589793) 
                    doppler_phase[i] = doppler_phase[i] - (2.0 * 3.141592653589793);

                // Compute Doppler effect
                cos_phase[i] = $cos(doppler_phase[i]);
                sin_phase[i] = $sin(doppler_phase[i]);

                // Apply fading to the input I/Q signals
                i_temp = i_temp + path_gain[i] * (real'(i_in) * cos_phase[i] - real'(q_in) * sin_phase[i]);
                q_temp = q_temp + path_gain[i] * (real'(i_in) * sin_phase[i] + real'(q_in) * cos_phase[i]);
            end

            // Convert back to 16-bit signed output with clipping
            i_out <= (i_temp > 32767) ? 16'sh7FFF :
                     (i_temp < -32768) ? 16'sh8000 :
                     signed'(int'(i_temp));

            q_out <= (q_temp > 32767) ? 16'sh7FFF :
                     (q_temp < -32768) ? 16'sh8000 :
                     signed'(int'(q_temp));
        end
    end

  end 

endgenerate

endmodule
