// Upconversion module: converts I/Q baseband (16-bit) to a real passband signal.
module duc_ddc_top #(
    parameter real IF = 50e6,   // Intermediate frequency in Hz.
    parameter real FS = 200e6   // Sample rate in Hz.
)(
    input  logic       clk,
    input  logic       reset,
    //DDC
    input  logic signed [15:0] adc_in,  // ADC input (digitized real signal).
    output logic signed [15:0] I_out,   // Recovered In-phase component.
    output logic signed [15:0] Q_out,   // Recovered Quadrature component.
    //DUC
    input  logic signed [15:0] I_in,    // In-phase component.
    input  logic signed [15:0] Q_in,    // Quadrature component.
    output logic signed [15:0] dac_out  // Real-valued (digitized) output to DAC.
);

  logic signed [15:0] dds_tdata;
  
  dds_50 dds_50_inst (
    .aclk(clk), // input wire aclk
    .m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
    .m_axis_data_tdata(dds_tdata) // output wire [15 : 0] m_axis_data_tdata
  );

  duc #(
    .FS(200e6)
  ) duc_inst (
    .clk      (clk      ),
    .reset    (reset    ),
    .dds_tdata(dds_tdata),
    .I_data   (I_in     ),
    .Q_data   (Q_in     ),
    .dac_out  (dac_out  )
  );

  ddc #(
    .FS(200e6)
  ) ddc_inst (
    .clk      (clk      ),
    .reset    (reset    ),
    .dds_tdata(dds_tdata),
    .adc_in   (adc_in   ),
    .I_out    (I_out    ),
    .Q_out    (Q_out    )
  );

endmodule

