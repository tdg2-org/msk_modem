module timing_jitter_drift_mdl #(
    parameter real INITIAL_OFFSET = 0.25,  // Initial fraction of symbol period (T)
    parameter real DRIFT_PER_SAMPLE = 0.00001, // Drift added every sample
    parameter bit ENABLE_RANDOM_JITTER = 0  // Set to 1 to add additional noise
)(
    input  logic        clk,
    input  logic        reset,
    input  logic signed [15:0] i_in,  // In-phase input
    input  logic signed [15:0] q_in,  // Quadrature input
    output logic signed [15:0] i_out, // Jittered In-phase output
    output logic signed [15:0] q_out  // Jittered Quadrature output
);

    real jitter_offset;
    real controlled_drift;
    real u1, u2, jitter;
    real i_interp, q_interp;
    logic signed [15:0] i_prev, q_prev;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            i_out <= 16'sd0;
            q_out <= 16'sd0;
            i_prev <= 16'sd0;
            q_prev <= 16'sd0;
            jitter_offset <= INITIAL_OFFSET;  // Start with controlled timing error
        end else begin
            // Update controlled timing drift
            jitter_offset = jitter_offset + DRIFT_PER_SAMPLE;
            if (jitter_offset > 0.5) jitter_offset = -0.5; // Keep within ±T/2 range

            // Generate random jitter only if enabled
            if (ENABLE_RANDOM_JITTER) begin
                u1 = real'($urandom_range(1, 10000)) / 10000.0;
                u2 = real'($urandom_range(1, 10000)) / 10000.0;
                jitter = (u1 - 0.5) * 0.05; // Small random jitter
            end else begin
                jitter = 0.0; // No random jitter
            end

            // Apply linear interpolation between previous and current sample
            controlled_drift = jitter_offset + jitter;
            i_interp = (1 - controlled_drift) * real'(i_prev) + controlled_drift * real'(i_in);
            q_interp = (1 - controlled_drift) * real'(q_prev) + controlled_drift * real'(q_in);

            // Store previous sample
            i_prev <= i_in;
            q_prev <= q_in;

            // Convert back to 16-bit signed output
            i_out <= (i_interp > 32767) ? 16'sh7FFF :
                     (i_interp < -32768) ? 16'sh8000 :
                     int'(i_interp);

            q_out <= (q_interp > 32767) ? 16'sh7FFF :
                     (q_interp < -32768) ? 16'sh8000 :
                     int'(q_interp);
        end
    end

endmodule