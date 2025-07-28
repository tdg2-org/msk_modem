`timescale 1ns / 1ps  // <time_unit>/<time_precision>
// ------------------------------------------------------------
// NCO / DDS model  (unsynthesizable)
//   • Phase accumulator width   : PHASE_WIDTH  (32 bits typical)
//   • Cos/Sin output word width : AMP_WIDTH    (signed, 16 bits typical)
//   • Runs every clock; no valid strobe needed
// ------------------------------------------------------------
module nco_dds #(
  parameter int PHASE_WIDTH = 32,  // accumulator & freq_word_i width
  parameter int AMP_WIDTH   = 16   // output amplitude word width
)(
  input  logic                          clk,
  input  logic                          rst,           // synchronous, active-high
  input  logic signed [PHASE_WIDTH-1:0] freq_word_i,     // Δφ per clock (2-s-comp)
  input  logic                          freq_word_val_i,
  output logic signed [PHASE_WIDTH-1:0] phase_word_o,    // current phase accumulator
  output logic signed [AMP_WIDTH-1:0]   cos_out,       // cos(phase)
  output logic signed [AMP_WIDTH-1:0]   sin_out        // sin(phase)
);

  dds_cfo dds_cfo (
    .aclk     (clk  ),                            // input wire aclk
    .aclken   ('1   ),                            // input wire aclken
    .aresetn  (~rst ),                            // input wire aresetn
    .s_axis_config_tvalid (freq_word_val_i  ),  // input wire s_axis_config_tvalid
    .s_axis_config_tdata  (freq_word_i      ),  // input wire [31 : 0] s_axis_config_tdata
    .m_axis_data_tvalid   (                 ),  // output wire m_axis_data_tvalid
    .m_axis_data_tdata    (dds_tdata        ),  // output wire [31 : 0] m_axis_data_tdata
    .m_axis_phase_tvalid  (                 ),  // output wire m_axis_phase_tvalid
    .m_axis_phase_tdata   (dds_phase        )   // output wire [31 : 0] m_axis_phase_tdata
  );

  logic [31:0] dds_tdata, dds_phase;
  
  assign sin_out      = signed'(dds_tdata[31:16]);
  assign cos_out      = signed'(dds_tdata[15:0]);
  assign phase_word_o = signed'(dds_phase);

endmodule

/*

  nco_dds #(
    .PHASE_WIDTH  (32),
    .AMP_WIDTH    (16) 
  ) nco_dds (
    .clk              (clk),
    .rst              (rst),
    .freq_word_i      (), 
    .freq_word_val_i  ()
    .phase_word_o (),   
    .cos_out      (),   
    .sin_out      ()    
  );


*/