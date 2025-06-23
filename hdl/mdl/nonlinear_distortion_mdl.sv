module nonlinear_distortion_mdl #(
    parameter real ALPHA = 0.00005,  // Nonlinearity strength
    parameter real P = 2.0        // Exponent controlling distortion
)(
    input  logic        clk,
    input  logic        reset,
    input  logic signed [15:0] i_in,  // In-phase input
    input  logic signed [15:0] q_in,  // Quadrature input
    output logic signed [15:0] i_out, // Distorted In-phase output
    output logic signed [15:0] q_out  // Distorted Quadrature output
);

    real i_temp, q_temp;
    real i_dist, q_dist;
    real i_abs, q_abs;
    real compression_factor_i, compression_factor_q;
    real ALPHA_SCALED;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            i_out <= 16'sd0;
            q_out <= 16'sd0;
        end else if ((ALPHA == 0.0) && (P == 0.0)) begin
            i_out <= i_in;
            q_out <= q_in;
        end else begin
            // Scale ALPHA down to ensure balanced distortion
            ALPHA_SCALED = ALPHA * 1e-6;

            // Convert input to real
            i_temp = real'(i_in);
            q_temp = real'(q_in);

            // Compute absolute values
            i_abs = (i_temp >= 0) ? i_temp : -i_temp;
            q_abs = (q_temp >= 0) ? q_temp : -q_temp;

            // Compute compression factors
            compression_factor_i = 1.0 / (1.0 + ALPHA_SCALED * i_abs**P);
            compression_factor_q = 1.0 / (1.0 + ALPHA_SCALED * q_abs**P);

            // Apply nonlinear amplitude compression
            i_dist = i_temp * compression_factor_i;
            q_dist = q_temp * compression_factor_q;

            // Convert back to 16-bit signed values with clipping
            i_out <= (i_dist > 32767) ? 16'sh7FFF :
                     (i_dist < -32768) ? 16'sh8000 :
                     int'(i_dist);

            q_out <= (q_dist > 32767) ? 16'sh7FFF :
                     (q_dist < -32768) ? 16'sh8000 :
                     int'(q_dist);
        end
    end

endmodule