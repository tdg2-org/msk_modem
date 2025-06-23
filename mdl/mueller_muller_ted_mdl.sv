// This module is a non-synthesizable model of a Mueller & Müller Timing Error Detector (TED).
module mueller_muller_ted (
    input  logic clk,
    input  logic reset,
    // Input symbol-rate baseband sample components.
    input  real I_symbol,
    input  real Q_symbol,
    // Timing error output (real-valued).
    output real error,
    // Asserted for one clock cycle when a new error is computed.
    output logic symbol_valid
);

    // Registers to store previous symbol samples.
    real I_old, Q_old;   // Sample from two symbols ago.
    real I_prev, Q_prev; // Previous symbol sample.
    real error_reg;
    assign error = error_reg;
    int symbol_count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            I_old <= 0.0;
            Q_old <= 0.0;
            I_prev <= 0.0;
            Q_prev <= 0.0;
            symbol_count <= 0;
            error_reg <= 0.0;
            symbol_valid <= 0;
        end else begin
            symbol_count <= symbol_count + 1;
            if (symbol_count < 2) begin
                // For the first two symbols, we only store data.
                I_prev <= I_symbol;
                Q_prev <= Q_symbol;
                symbol_valid <= 0;
            end else begin
                // Compute the M&M error using the previous two stored symbols.
                error_reg <= I_prev * (I_symbol - I_old) + Q_prev * (Q_symbol - Q_old);
                symbol_valid <= 1;
                // Shift the stored symbols.
                I_old <= I_prev;
                Q_old <= Q_prev;
                I_prev <= I_symbol;
                Q_prev <= Q_symbol;
            end
        end
    end

endmodule


//         I_real = $itor(I_data);
//         Q_real = $itor(Q_data);
