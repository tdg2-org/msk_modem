// Upconversion module: converts I/Q baseband (16-bit) to a real passband signal.
module duc_ddc_lpf_top #(
    parameter       DUC_EN = 1,
    parameter       DDC_EN = 1,
    parameter real  IF = 50e6,   // Intermediate frequency in Hz.
    parameter real  FS = 200e6   // Sample rate in Hz.
)(
    input  logic       clk,
    input  logic       rstn,
    //DDC
    input  logic signed [15:0]  adc_in,  // ADC input (digitized real signal).
    input  logic                adc_val,
    output logic signed [15:0]  I_out,   // Recovered In-phase component.
    output logic signed [15:0]  Q_out,   // Recovered Quadrature component.
    output logic                IQ_val,
    //DUC
    input  logic signed [15:0]  I_in,    // In-phase component.
    input  logic signed [15:0]  Q_in,    // Quadrature component.
    output logic signed [15:0]  dac_out  // Real-valued (digitized) output to DAC.
);

  logic signed [15:0] dds_tdata;
  
  dds_50 dds_50_inst (
    .aresetn            (rstn     ),
    .aclk               (clk      ),  // input wire aclk
    .m_axis_data_tvalid (dds_val  ),  // output wire m_axis_data_tvalid
    .m_axis_data_tdata  (dds_tdata)   // output wire [15 : 0] m_axis_data_tdata
  );

//-------------------------------------------------------------------------------------------------
// DUC
//-------------------------------------------------------------------------------------------------
generate if (DUC_EN) begin : DUC
  duc #(
    .FS(200e6)
  ) duc_inst (
    .clk      (clk      ),
    .reset    (~rstn    ),
    .dds_tdata(dds_tdata),
    .I_data   (I_in     ),
    .Q_data   (Q_in     ),
    .dac_out  (dac_out  )
  );
end else begin 
  assign dac_out = '0;
end endgenerate

//-------------------------------------------------------------------------------------------------
// DDC + LPF
//-------------------------------------------------------------------------------------------------
generate if (DDC_EN) begin : DDC

  logic signed [15:0] dc_I, dc_Q;
  logic signed [31:0] fir_I_tdata, fir_Q_tdata;


  ddc #(
    .FS(200e6)
  ) ddc_inst (
    .clk      (clk      ),
    .reset    (~rstn    ),
    .dds_tdata(dds_tdata),
    .dds_val  (dds_val  ),
    .adc_in   (adc_in   ),
    .adc_val  (adc_val  ),
    .I_out    (dc_I     ),
    .Q_out    (dc_Q     ),
    .IQ_val   (dc_IQ_val)
  );

  // output tvalids will both be aligned
  // 18 clock delay
  fir_lpf fir_lpf_dc_I (
    .aclk               (clk      ),// input wire aclk
    .s_axis_data_tvalid (dc_IQ_val),// input wire s_axis_data_tvalid
    .s_axis_data_tready (         ), // output wire s_axis_data_tready
    .s_axis_data_tdata  (dc_I     ),// input wire [15 : 0] s_axis_data_tdata
    .m_axis_data_tvalid (fir_val  ), // output wire m_axis_data_tvalid
    .m_axis_data_tdata  (fir_I_tdata)// output wire [31 : 0] m_axis_data_tdata
  );

  fir_lpf fir_lpf_dc_Q (
    .aclk               (clk      ),// input wire aclk
    .s_axis_data_tvalid (dc_IQ_val),// input wire s_axis_data_tvalid
    .s_axis_data_tready (         ), // output wire s_axis_data_tready
    .s_axis_data_tdata  (dc_Q     ),// input wire [15 : 0] s_axis_data_tdata
    .m_axis_data_tvalid (         ), // output wire m_axis_data_tvalid
    .m_axis_data_tdata  (fir_Q_tdata)// output wire [31 : 0] m_axis_data_tdata
  );

  assign I_out  = fir_I_tdata[30:15]; // CAREFUL TO PRESERVE SIGN BIT!!!
  assign Q_out  = fir_Q_tdata[30:15];
  assign IQ_val = fir_val;

end else begin 
  assign I_out  = '0;
  assign Q_out  = '0;
  assign IQ_val = '0;
end endgenerate


endmodule

/*

  duc_ddc_lpf_top #(
    .DUC_EN(1),
    .DDC_EN(1),
    .FS(200e6)
  ) duc_ddc_top_inst0 (
    .clk      (),
    .reset    (),
    //DDC
    .adc_in   (), // from ADC
    .adc_val  (),
    .I_out    (), // to demod
    .Q_out    (), // to demod
    .IQ_val   (),
    //DUC
    .I_in     (), // from modulator
    .Q_in     (), // from modulator
    .dac_out  ()  // to DAC
  );

*/

