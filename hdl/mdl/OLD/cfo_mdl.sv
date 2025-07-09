module cfo_mdl #(
    parameter real CFO_HZ = 1000.0,  // Carrier Frequency Offset in Hz
    parameter real FS = 200.0e6 // Sample rate in Hz
)(
    input  logic        clk,
    input  logic        reset,
    input  logic signed [15:0] i_in,  // In-phase component
    input  logic signed [15:0] q_in,  // Quadrature component
    output logic signed [15:0] i_out, // Offset In-phase component
    output logic signed [15:0] q_out  // Offset Quadrature component
);

    real phase, phase_step;
    real cos_theta, sin_theta;
    real i_temp, q_temp;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            phase <= 0.0;
            i_out <= 16'sd0;
            q_out <= 16'sd0;
        end else if (CFO_HZ == 0.0) begin
            i_out <= i_in;
            q_out <= q_in;
        end else begin
            // Compute phase step per sample
            phase_step = 2.0 * 3.141592653589793 * CFO_HZ / FS;

            // Update phase
            phase <= phase + phase_step;
            if (phase > (2.0 * 3.141592653589793))
                phase <= phase - (2.0 * 3.141592653589793); // Keep phase within 0 to 2π

            // Compute sinusoidal rotation
            cos_theta = $cos(phase);
            sin_theta = $sin(phase);

            // Apply frequency shift
            i_temp = real'(i_in) * cos_theta - real'(q_in) * sin_theta;
            q_temp = real'(i_in) * sin_theta + real'(q_in) * cos_theta;

            // Convert back to 16-bit signed values with clipping
            i_out <= (i_temp > 32767) ? 16'sh7FFF :
                     (i_temp < -32768) ? 16'sh8000 :
                     signed'(int'(i_temp));

            q_out <= (q_temp > 32767) ? 16'sh7FFF :
                     (q_temp < -32768) ? 16'sh8000 :
                     signed'(int'(q_temp));
        end
    end

endmodule
