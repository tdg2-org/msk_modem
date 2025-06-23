
module ddc #(
    parameter real IF = 50e6,   // Intermediate frequency in Hz.
    parameter real FS = 200e6   // Sample rate in Hz.
)(
    input  logic                clk,
    input  logic                reset,
    input  logic signed [15:0]  dds_tdata,
    input  logic signed [15:0]  adc_in,   // ADC input (digitized real signal).
    output logic signed [15:0]  I_out,    // Recovered In-phase component.
    output logic signed [15:0]  Q_out     // Recovered Quadrature component.
);

  logic signed [17:0]  dds_sin, dds_cos, adc_in_ext;
  logic signed [47:0]  mix_I, mix_Q;

  assign dds_sin = signed'({dds_tdata[15:8]});
  assign dds_cos = signed'({dds_tdata[7:0]});
  
  assign adc_in_ext = signed'({adc_in});

  // A*B-C
  // I = data * cos
  dsp_macro_AxBmC dsp_I (
    .CLK  (clk        ),
    .CE   ('1         ),
    .A    (adc_in_ext ),
    .B    (dds_cos    ),
    .C    ('0         ),
    .P    (mix_I      )
  );
  // Q = -(data * sin)
  dsp_macro_AxBmC dsp_Q (
    .CLK  (clk        ),
    .CE   ('1         ),
    .A    (adc_in_ext ),
    .B    (dds_sin    ),
    .C    ('0         ),
    .P    (mix_Q      )
  );

  assign I_out = mix_I[22:7];
  assign Q_out = -signed'(mix_Q[22:7]); // negation has no effect?


endmodule

