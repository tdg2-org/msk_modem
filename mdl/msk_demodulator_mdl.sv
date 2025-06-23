module msk_demodulator_mdl #(
    parameter real FS = 800.0e6,  // Sample rate (Hz)
    parameter real F_SYM = 10.0e6 // Symbol rate (Hz)
)(
    input logic clk,
    input logic reset_n,
    input int   midpoint_adj,
    input logic signed [15:0] i_in,  // In-phase (I) input from if_to_iq
    input logic signed [15:0] q_in,  // Quadrature (Q) input from if_to_iq
    output logic data_out            // Recovered binary data
);

    // Compute number of samples per symbol
    localparam int SAMPLES_PER_SYM = int'(FS / F_SYM);
    
    // Compute symbol sampling midpoint
    localparam int SAMPLE_MIDPOINT = (SAMPLES_PER_SYM / 2);

    logic signed [31:0] phase_prev, phase_curr;
    logic signed [31:0] phase_diff;
    integer sample_count, midpoint;
    logic sample_midpoint_active;

    // Compute atan2 in fixed-point format
    function automatic signed [31:0] atan2_fixed(input signed [15:0] y, input signed [15:0] x);
        automatic real phase_radians;
        phase_radians = $atan2(real'(y), real'(x)); // Compute atan2 in radians
        return int'(phase_radians * (2.0**30) / 3.14159265); // Scale to Q30 fixed-point
    endfunction

    assign midpoint = SAMPLE_MIDPOINT + midpoint_adj;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            phase_prev  <= 0;
            phase_curr  <= 0;
            phase_diff  <= 0;
            sample_count <= 0;
            data_out <= 0;
            sample_midpoint_active <= 0;
        end else begin
            sample_midpoint_active <= 0;
            // Compute phase difference
            phase_prev <= phase_curr;
            phase_curr <= atan2_fixed(q_in, i_in);
            phase_diff <= phase_curr - phase_prev;

            // Handle phase wrapping
            if (phase_diff > (2**30)) 
                phase_diff <= phase_diff - (2**31);
            else if (phase_diff < -(2**30)) 
                phase_diff <= phase_diff + (2**31);

            // Sample at the calculated midpoint
            sample_count <= sample_count + 1;
            if (sample_count == SAMPLES_PER_SYM-1) begin
              sample_count <= 0;
            end 
            if (sample_count == midpoint) begin // Midpoint dynamically computed
                sample_midpoint_active <= 1;
                //sample_count <= 0;
                data_out <= (phase_diff > 0) ? 1 : 0; // Decision rule
            end
        end
    end
endmodule
