module timing_jitter_mdl #(
    parameter real JITTER_STD_DEV = 0.01 // Standard deviation of jitter in fraction of sample period
)(
    input  logic        clk,
    input  logic        reset,
    input  logic signed [15:0] i_in,  // In-phase input
    input  logic signed [15:0] q_in,  // Quadrature input
    output logic signed [15:0] i_out, // Jittered In-phase output
    output logic signed [15:0] q_out  // Jittered Quadrature output
);

    real jitter_offset, u1, u2, jitter;
    real i_interp, q_interp;
    logic signed [15:0] i_prev, q_prev;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            i_out <= 16'sd0;
            q_out <= 16'sd0;
            i_prev <= 16'sd0;
            q_prev <= 16'sd0;
        end else begin
            // Generate two uniform random numbers
            u1 = real'($urandom_range(1, 10000)) / 10000.0;
            u2 = real'($urandom_range(1, 10000)) / 10000.0;

            // Gaussian-distributed jitter using Box-Muller transform
            jitter_offset = JITTER_STD_DEV * $sqrt(-2.0 * $ln(u1)) * $cos(2.0 * 3.141592653589793 * u2);

            // Apply linear interpolation between previous and current sample
            jitter = jitter_offset * 1.0; // Scale jitter in sample fractions

            i_interp = (1 - jitter) * real'(i_prev) + jitter * real'(i_in);
            q_interp = (1 - jitter) * real'(q_prev) + jitter * real'(q_in);

            // Store previous sample
            i_prev <= i_in;
            q_prev <= q_in;

            // Convert back to 16-bit signed output
            i_out <= (i_interp > 32767) ? 16'sh7FFF :
                     (i_interp < -32768) ? 16'sh8000 :
                     signed'(int'(i_interp));

            q_out <= (q_interp > 32767) ? 16'sh7FFF :
                     (q_interp < -32768) ? 16'sh8000 :
                     signed'(int'(q_interp));
        end
    end

endmodule
