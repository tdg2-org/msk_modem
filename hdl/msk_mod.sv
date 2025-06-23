module msk_mod #(
    parameter real FS = 800.0e6,  // Sample rate (Hz)
    parameter real F_SYM = 10.0e6 // Symbol rate (Hz)
)(
    input   logic clk,
    input   logic reset_n,
    input   logic data_in,
    output  logic signed [15:0] i_out,  // Baseband I
    output  logic signed [15:0] q_out   // Baseband Q
);

  localparam logic signed [31:0] PHASE_STEP_HI = 53687091;
  localparam logic signed [31:0] PHASE_STEP_LO = -53687091;

  logic signed [31:0] s_tdata;
  logic [31:0] m_tdata;
  logic signed [15:0] dds_sin, dds_cos;

  assign s_tdata = data_in ? signed'(PHASE_STEP_HI) : signed'(PHASE_STEP_LO);

  dds_phase dds_phase_inst (
    .aclk(clk),                      // input wire aclk
    .s_axis_phase_tvalid  ('1),       // input wire s_axis_phase_tvalid
    .s_axis_phase_tdata   (s_tdata),  // input wire [31 : 0] s_axis_phase_tdata
    .m_axis_data_tvalid   (),         // output wire m_axis_data_tvalid
    .m_axis_data_tdata    (m_tdata)   // output wire [31 : 0] m_axis_data_tdata
  );

  assign dds_sin = signed'({m_tdata[31:16]});
  assign dds_cos = signed'({m_tdata[15:0]});

  assign i_out = dds_cos;
  assign q_out = dds_sin;
  
endmodule
