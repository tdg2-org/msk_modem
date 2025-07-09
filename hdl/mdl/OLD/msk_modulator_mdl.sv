module msk_modulator_mdl #(
    parameter real FS = 800.0e6,  // Sample rate (Hz)
    parameter real F_SYM = 10.0e6 // Symbol rate (Hz)
)(
    input logic clk,
    input logic reset_n,
    input logic data_in,
    output logic signed [15:0] i_out,  // Baseband I
    output logic signed [15:0] q_out   // Baseband Q
);

    // Compute MSK frequency deviation (± 0.25 * Symbol Rate)
    localparam real FREQ_DEV = 0.25 * F_SYM;

    // Compute phase steps based on sample rate
    localparam int PHASE_STEP_HIGH = int'( (FREQ_DEV) * (2.0**32) / FS );
    localparam int PHASE_STEP_LOW  = int'( (-FREQ_DEV) * (2.0**32) / FS );

    // Compute number of samples per symbol
    localparam int SAMPLES_PER_SYM = int'(FS / F_SYM);

    logic [31:0] phase_acc;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            phase_acc <= 0;
        else
            phase_acc <= phase_acc + (data_in ? PHASE_STEP_HIGH : PHASE_STEP_LOW);
    end

    function automatic signed [15:0] sine_wave(input [31:0] phase);
        automatic real phase_radians;
        phase_radians = (phase * 2.0 * 3.14159265) / (2.0**32); // Convert fixed-point phase to radians
        return $signed(32767 * $sin(phase_radians));
    endfunction

    function automatic signed [15:0] cosine_wave(input [31:0] phase);
        automatic real phase_radians;
        phase_radians = (phase * 2.0 * 3.14159265) / (2.0**32);
        return $signed(32767 * $cos(phase_radians));
    endfunction

    always_ff @(posedge clk) begin
        i_out <= cosine_wave(phase_acc);  // Baseband I
        q_out <= sine_wave(phase_acc);    // Baseband Q
    end

endmodule
