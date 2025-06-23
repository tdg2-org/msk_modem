module awgn_noise_gen_mdl #(
    parameter real NOISE_STD_DEV = 10.0  // Standard deviation of the noise
)(
    input  logic        clk,
    input  logic        reset,
    input  logic signed [15:0] signal_in,
    output logic signed [15:0] signal_out
);

    real noise, u1, u2, z0;
    real noisy_signal;
    int unsigned rand1, rand2;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            signal_out <= 16'sd0;
        end else if ((NOISE_STD_DEV == 0.0)) begin
            signal_out <= signal_in;
        end else begin
            // Generate two uniform random numbers in (0,1)
            rand1 = $urandom_range(1, 10000);  
            rand2 = $urandom_range(1, 10000);
            u1 = real'(rand1) / 10000.0;
            u2 = real'(rand2) / 10000.0;

            // Box-Muller transform to get Gaussian noise
            z0 = NOISE_STD_DEV * $sqrt(-2.0 * $ln(u1)) * $cos(2.0 * 3.141592653589793 * u2);
            noise = z0;

            // Apply noise to signal
            noisy_signal = real'(signal_in) + noise;

            // Clip to 16-bit signed range and assign output
            if (noisy_signal > 32767) 
                signal_out <= 16'sh7FFF;
            else if (noisy_signal < -32768) 
                signal_out <= 16'sh8000;
            else 
                signal_out <= signed'(int'(noisy_signal));
        end
    end

endmodule