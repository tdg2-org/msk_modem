module real_to_iq #(
    parameter real FS = 800.0e6,  // Sample rate (Hz)
    parameter real F_SYM = 10.0e6 // Symbol rate (Hz)
)(
    input logic clk,
    input logic reset_n,
    input logic signed [15:0] real_in, // Real-valued input signal
    output logic signed [15:0] i_out,  // Baseband I output
    output logic signed [15:0] q_out   // Baseband Q output
);

    // Compute phase step for quadrature signal generation
    localparam int PHASE_STEP = int'((0.25 * F_SYM) * (2.0**32) / FS);

    logic [31:0] phase_acc;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            phase_acc <= 0;
        else
            phase_acc <= phase_acc + PHASE_STEP;
    end

    // Floating-point sine and cosine functions (for simulation only)
    function automatic signed [15:0] sine_wave(input [31:0] phase);
        automatic real phase_radians;
        phase_radians = (phase * 2.0 * 3.14159265) / (2.0**32);
        return $signed(32767 * $sin(phase_radians));
    endfunction

    function automatic signed [15:0] cosine_wave(input [31:0] phase);
        automatic real phase_radians;
        phase_radians = (phase * 2.0 * 3.14159265) / (2.0**32);
        return $signed(32767 * $cos(phase_radians));
    endfunction

    always_ff @(posedge clk) begin
        i_out <= (real_in * cosine_wave(phase_acc)) >>> 14; // In-phase component
        q_out <= (real_in * sine_wave(phase_acc)) >>> 14;    // Quadrature component
    end

endmodule
