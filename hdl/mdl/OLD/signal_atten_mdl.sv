module signal_atten_mdl #(
    parameter int SHIFT_VAL = 0,        // Shift amount (0 means not used)
    parameter int SCALE_FACTOR = 0      // Q15 Scale factor (0 means not used)
)(
    input  logic signed [15:0] signal_in,
    output logic signed [15:0] signal_out
);

    logic signed [31:0] temp;

    always_comb begin
        if (SHIFT_VAL > 0) begin
            // Shift-based attenuation
            signal_out = signal_in >>> SHIFT_VAL;
        end else if (SCALE_FACTOR > 0) begin
            // Fixed-point multiplication (Q15)
            temp = signal_in * SCALE_FACTOR;
            signal_out = temp >>> 15; // Scale down to 16-bit
        end else begin
            // Direct pass-through
            signal_out = signal_in;
        end
    end

endmodule