module iq_to_real #(
    parameter real FS = 800.0e6,  // Sample rate (Hz)
    parameter real F_SYM = 10.0e6 // Symbol rate (Hz)
)(
    input logic clk,
    input logic reset_n,
    input logic signed [15:0] i_in, // Baseband I input
    input logic signed [15:0] q_in, // Baseband Q input
    output logic signed [15:0] real_out // Real-valued output signal
);

    // Compute phase step for quadrature signal reconstruction
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
        real_out <= (i_in * cosine_wave(phase_acc) - q_in * sine_wave(phase_acc)) >>> 14;
    end

endmodule
