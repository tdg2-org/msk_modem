module loop_filter_mdl #(
    // Proportional gain
    parameter real Kp = 0.1,
    // Integral gain
    parameter real Ki = 0.01
)(
    input  logic clk,
    input  logic reset,
    // Real-valued error input from the timing error detector (e.g., Gardner TED)
    input  real  error,
    // Control signal output for the fractional delay/interpolator
    output real  control_signal
);

  // Internal register for the integrator state.
  real integrator;

  // Compute the control signal as: control_signal = Kp*error + integral(error)
  // The integrator accumulates Ki*error at each clock cycle.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      integrator <= 0.0;
    end else begin
      integrator <= integrator + Ki * error;
    end
  end

  assign control_signal = Kp * error + integrator;

  int ctrl_int, err_int;

  assign ctrl_int = int'(control_signal);
  assign err_int  = int'(error);

endmodule
