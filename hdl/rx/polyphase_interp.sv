`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// TODO: need to figure out mu


module polyphase_interp #
(
  parameter int OSF        = 20,  // polyphase branches
  parameter int TAPS_PPH   = 5 ,  // taps per branch
  parameter int WIQ        = 16,  // input sample width
  parameter int WO         = 18   // output sample width
)
(
  input  logic                  clk,
  input  logic                  rst,
  input  logic signed [WIQ-1:0] i_raw_i,
  input  logic signed [WIQ-1:0] q_raw_i,
  input  logic                  iq_raw_val_i,       
  input  logic [4:0]            phase_int_i,    // 0…19
  input  logic [26:0]           mu_i,           // not used here
  input  logic                  phase_val_i,
  input  logic                  sym_valid_i,
  output logic signed [WO-1:0]  i_sym_o,
  output logic signed [WO-1:0]  q_sym_o,
  output logic                  sym_valid_o
);
//-------------------------------------------------------------------------------------------------
// 
//-------------------------------------------------------------------------------------------------
  logic poly_fir_val, poly_fir_rdy, fir_full=0, fir_en, phase_val;
  logic [39:0] poly_fir_I, poly_fir_Q;

  assign fir_en     = iq_raw_val_i  && phase_val_i;
  assign phase_val  = phase_val_i && sym_valid_i;


  fir_poly_interp fir_poly_interp_I (
    .aresetn              (~rst   ),  // input wire aresetn
    .aclk                 (clk    ),  // input wire aclk
    .aclken               (fir_en ),  // input wire aclken
    .s_axis_data_tvalid   (iq_raw_val_i   ),  // input wire s_axis_data_tvalid
    .s_axis_data_tready   (               ),  // output wire s_axis_data_tready
    .s_axis_data_tdata    (i_raw_i        ),  // input wire [15 : 0] s_axis_data_tdata
    .s_axis_config_tvalid (phase_val      ),  // input wire s_axis_config_tvalid
    .s_axis_config_tready (poly_fir_rdy   ),  // output wire s_axis_config_tready
    .s_axis_config_tdata  (phase_int_i    ),  // input wire [7 : 0] s_axis_config_tdata
    .m_axis_data_tvalid   (poly_fir_val   ),  // output wire m_axis_data_tvalid
    .m_axis_data_tdata    (poly_fir_I     )   // output wire [39 : 0] m_axis_data_tdata
  );

  fir_poly_interp fir_poly_interp_Q (
    .aresetn              (~rst   ),  // input wire aresetn
    .aclk                 (clk    ),  // input wire aclk
    .aclken               (fir_en ),  // input wire aclken
    .s_axis_data_tvalid   (iq_raw_val_i   ),  // input wire s_axis_data_tvalid
    .s_axis_data_tready   (               ),  // output wire s_axis_data_tready
    .s_axis_data_tdata    (q_raw_i        ),  // input wire [15 : 0] s_axis_data_tdata
    .s_axis_config_tvalid (phase_val      ),  // input wire s_axis_config_tvalid
    .s_axis_config_tready (               ),  // output wire s_axis_config_tready
    .s_axis_config_tdata  (phase_int_i    ),  // input wire [7 : 0] s_axis_config_tdata
    .m_axis_data_tvalid   (               ),  // output wire m_axis_data_tvalid
    .m_axis_data_tdata    (poly_fir_Q     )   // output wire [39 : 0] m_axis_data_tdata
  );

  assign i_sym_o = poly_fir_I[32:17];
  assign q_sym_o = poly_fir_Q[32:17];

  localparam int DEPTH = 17;
  int cnt = 0;

  always_ff @(posedge clk) begin
    if (poly_fir_rdy) begin  
      if (cnt < DEPTH) cnt <= cnt + 1;
      else fir_full <= '1;
    end
  end

  assign sym_valid_o = poly_fir_val && fir_full;

endmodule



/* instantiation template ------------------------------------------------------

polyphase_interp_mdl #(
  .OSF       (20),
  .TAPS_PPH  (5 ),
  .WIQ       (16),
  .WO        (18)
) polyphase_interp_inst (
  .clk          (),
  .rst          (),
  .i_raw_i      (),
  .q_raw_i      (),
  .phase_int_i  (),
  .mu_i         (),
  .phase_val_i  (),
  .sym_valid_i  (),
  .i_sym_o      (),
  .q_sym_o      (),
  .sym_valid_o  ()
);

*/
