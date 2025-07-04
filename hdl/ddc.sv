
// DSP48 has 4clk latency

module ddc #(
    parameter real IF = 50e6,   // Intermediate frequency in Hz.
    parameter real FS = 200e6   // Sample rate in Hz.
)(
    input  logic                clk,
    input  logic                reset,
    input  logic signed [15:0]  dds_tdata,
    input  logic                dds_val,
    input  logic signed [15:0]  adc_in,   // ADC input (digitized real signal).
    input  logic                adc_val,
    output logic signed [15:0]  I_out,    // Recovered In-phase component.
    output logic signed [15:0]  Q_out,     // Recovered Quadrature component.
    output logic                IQ_val
);

  logic signed [17:0]  dds_sin, dds_cos, adc_in_ext;
  logic signed [47:0]  mix_I, mix_Q;
  logic dsp_ce;

  assign dds_sin = signed'({dds_tdata[15:8]});
  assign dds_cos = signed'({dds_tdata[7:0]});
  assign adc_in_ext = signed'({adc_in});

  // this is only intended for startup, after reset. dont start until both dds and adc data
  // is stable running, after this should never deassert
  assign dsp_ce = (dds_val && adc_val) ? '1 : '0;

  // A*B-C
  // I = data * cos
  // 4 CLOCK DELAY
  dsp_macro_AxBmC dsp_I (
    .CLK  (clk        ),
    .CE   (dsp_ce     ),
    .A    (adc_in_ext ),
    .B    (dds_cos    ),
    .C    ('0         ),
    .P    (mix_I      )
  );
  // Q = -(data * sin)
  dsp_macro_AxBmC dsp_Q (
    .CLK  (clk        ),
    .CE   (dsp_ce     ),
    .A    (adc_in_ext ),
    .B    (dds_sin    ),
    .C    ('0         ),
    .P    (mix_Q      )
  );

  //assign I_out = mix_I[22:7];
  //assign Q_out = -signed'(mix_Q[22:7]); // negation has no effect?

  // align output of DSPs 4 clock delay and valid

  localparam SRN = 4;
  logic [SRN-1:0] sr;

  always_ff @(posedge clk) begin
    if (reset) begin 
      sr      <= '0;
      IQ_val  <= '0;
    end else if (dsp_ce) begin 
      sr <= {sr[SRN-2:0],1'b1};
      if (sr == '1) begin // only intended for after reset, 4clk delay for data stream
        I_out   <= mix_I[22:7];
        Q_out   <= -signed'(mix_Q[22:7]); // negation has no effect?
        IQ_val  <= '1;
      end
    end
  end


endmodule

/*

  ddc #(
    .FS(200e6)
  ) ddc_inst (
    .clk      (),
    .reset    (),
    .dds_tdata(),
    .dds_val  (),
    .adc_in   (),
    .adc_val  (),
    .I_out    (),
    .Q_out    ()
  );

*/
