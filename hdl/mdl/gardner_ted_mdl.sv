// This module is a non-synthesizable model of a Gardner Timing Error Detector (TED).
module gardner_ted_mdl #(
    // Oversampling factor: number of samples per symbol period.
    parameter int OVERSAMPLE_FACTOR = 20,
    // The chosen midpoint index (must be between 1 and OVERSAMPLE_FACTOR-2).
    parameter int MID_POINT = 10
)(
    input  logic clk,
    input  logic reset,
    // Input oversampled baseband sample components.
    input  logic signed [15:0]  I_in,
    input  logic signed [15:0]  Q_in,
    // Timing error output (real-valued).
    output real error,
    // Asserted for one clock cycle when a new error is computed.
    output logic symbol_valid
);

    // Internal storage for one symbol period.
    real I_samples[0:OVERSAMPLE_FACTOR-1];
    real Q_samples[0:OVERSAMPLE_FACTOR-1];
    int counter;
    real error_reg;
    assign error = error_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            symbol_valid <= 0;
            error_reg <= 0.0;
        end else begin
            // Capture the current sample in the array.
            I_samples[counter] <= real'(I_in);
            Q_samples[counter] <= real'(Q_in);
            if (counter == OVERSAMPLE_FACTOR - 1) begin
                // Once a full symbol period is captured, compute the error.
                // Use sample at MID_POINT as the "on-time" sample.
                // (MID_POINT-1) is the early sample and (MID_POINT+1) is the late sample.
                error_reg <= (I_samples[MID_POINT - 1] - I_samples[MID_POINT + 1]) * I_samples[MID_POINT]
                           + (Q_samples[MID_POINT - 1] - Q_samples[MID_POINT + 1]) * Q_samples[MID_POINT];
                symbol_valid <= 1;
                counter <= 0;
            end else begin
                symbol_valid <= 0;
                counter <= counter + 1;
            end
        end
    end

    int error_int,error_max=0,error_min=0,error_floor=999999999;

    assign error_int = int'(error_reg);

    always_comb begin
      error_max = (error_int > error_max) ? error_int : error_max;
      error_min = (error_int < error_min) ? error_int : error_min;
      error_floor = ((error_int > 0) && (error_int < error_floor)) ? error_int :              // positive and closer to zero
                    ((error_int < 0) && (error_int > error_floor)) ? error_int : error_floor; // negative and closer to zero
    end 

endmodule


