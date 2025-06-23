
module duc #(
    parameter real IF = 50e6,   // Intermediate frequency in Hz.
    parameter real FS = 200e6   // Sample rate in Hz.
)(
    input  logic                clk,
    input  logic                reset,
    input  logic signed [15:0]  dds_tdata,
    input  logic signed [15:0]  I_data,  // In-phase component.
    input  logic signed [15:0]  Q_data,  // Quadrature component.
    output logic signed [15:0]  dac_out  // Real-valued (digitized) output to DAC.
);

  logic signed [17:0]  dds_sin, dds_cos, q_ext, i_ext;
  logic signed [47:0]  QxSIN, duc_data;

  assign dds_sin = signed'({dds_tdata[15:8]});
  assign dds_cos = signed'({dds_tdata[7:0]});
  
  assign i_ext = signed'({I_data});
  assign q_ext = signed'({Q_data});

  // A*B-C
  dsp_macro_AxBmC dsp_QxSIN (
    .CLK  (clk      ),
    .CE   ('1       ),
    .A    (q_ext    ),
    .B    (dds_sin  ),
    .C    ('0       ),
    .P    (QxSIN    )
  );

  dsp_macro_AxBmC dsp_IxCOSmQxSIN (
    .CLK  (clk      ),
    .CE   ('1       ),
    .A    (i_ext    ),
    .B    (dds_cos  ),
    .C    (QxSIN    ),
    .P    (duc_data )
  );

  assign dac_out = duc_data[22:7];

endmodule

