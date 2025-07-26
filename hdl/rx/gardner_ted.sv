`timescale 1ns / 1ps  // <time_unit>/<time_precision>

module gardner_ted #
(
  parameter int RAW_DLY = 20,
  parameter int OSF     = 20,   // samples / symbol
  parameter int WI      = 16,   // I/Q input width
  parameter int WO      = 18    // error-output width
)
(
  input  logic                    clk,
  input  logic                    reset_n,
  input  logic signed [WI-1:0]    i_in,
  input  logic signed [WI-1:0]    q_in,
  input                           iq_val,
  input  logic                    sym_valid_i,
  output logic signed [WO-1:0]    e_out_o,
  output logic                    e_valid_o,
  output  logic signed [WI-1:0]   i_raw_delay_o,
  output  logic signed [WI-1:0]   q_raw_delay_o
);
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

  logic signed [WI-1:0] array_i [OSF:0]; //21 deep
  logic signed [WI-1:0] array_q [OSF:0]; //21 deep

  logic [OSF-1:0] sr;
  logic array_full;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      array_i     <= '{default:'0};
      array_q     <= '{default:'0};
      sr          <= '0;
      array_full  <= '0;
    end else if (iq_val) begin 
      sr <= {sr[OSF-2:0],1'b1};
      if (sr == '1) array_full <= '1;
      array_i <= {array_i[OSF-1:0],i_in};
      array_q <= {array_q[OSF-1:0],q_in};
    end
  end 

  logic signed [WI-1:0] Ic, Ih, Ip, Qc, Qh, Qp, dI, dQ;
  assign Ic = i_in;         // 0th current sample
  assign Ih = array_i[9];   // 10th half symbol delay sample
  assign Ip = array_i[19];  // 20th full symbol delay sample
  assign Qc = q_in;
  assign Qh = array_q[9];
  assign Qp = array_q[19];

  assign dI = Ic - Ip;
  assign dQ = Qc - Qp;

  localparam int ERR_WID = 18;
  localparam int SHIFT = (WI + $clog2(OSF)) - WO;
  logic signed [ERR_WID-1:0] err, e_out_pre, dsp_Ih, dsp_dI, dsp_Qh, dsp_dQ;

  assign dsp_Ih = signed'({Ih});
  assign dsp_dI = signed'({dI});
  assign dsp_Qh = signed'({Qh});
  assign dsp_dQ = signed'({dQ});

  logic signed [47:0] dsp_I_prod, dsp_Q_prod, iq_sum, err_long;

  //dsp_mix. sel = 0; A*B-C, sel = 1: A*B+C
  dsp_mix dsp_I ( // dsp_mix
    .CLK  (clk        ),
    .CE   (iq_val     ),
    .SEL  ('1         ),  // A*B+C 
    .A    (dsp_Ih), // in [17:0]
    .B    (dsp_dI), // in [17:0]
    .C    ('0   ), // in [17:0]
    .P    (dsp_I_prod)  // out [47:0]
  );

  dsp_mix dsp_Q ( // dsp_mix
    .CLK  (clk        ),
    .CE   (iq_val     ),
    .SEL  ('1         ),  // A*B+C 
    .A    (dsp_Qh), // in [17:0]
    .B    (dsp_dQ), // in [17:0]
    .C    ('0   ),  // in [17:0]
    .P    (dsp_Q_prod)  // out [47:0]
  );

  assign iq_sum = (dsp_I_prod + dsp_Q_prod);
  assign err_long = iq_sum >>> (SHIFT);
  assign err = err_long[2*WI+1:16];

  logic e_valid_pre;


  localparam int DSP_DELAY = 4;

  logic [DSP_DELAY-1:0] sym_val_sr = '0;

  always_ff @(posedge clk) begin
    sym_val_sr <= {sym_val_sr[DSP_DELAY-1:0],sym_valid_i}; // 4clk DSP48 delay
    
    if (sym_val_sr[DSP_DELAY-1] && array_full && iq_val) begin // wait til array is full after reset
      e_out_pre <= err;
      e_valid_pre <= '1;
    end else e_valid_pre <= '0;
  end

  assign e_out_o   = e_out_pre;
  assign e_valid_o = e_valid_pre;

  // processing delay in timing recover loop to align samples for interpolator
  assign i_raw_delay_o = array_i[RAW_DLY + DSP_DELAY];
  assign q_raw_delay_o = array_q[RAW_DLY + DSP_DELAY];


endmodule



/* instantiation template ------------------------------------------------------

gardner_ted_mdl_3 #(
  .RAW_DLY  (3),
  .OSF      (20),
  .WI       (16),
  .WO       (18)
) gardner_ted_inst (
  .clk          (),
  .reset_n      (),
  .i_in         (),
  .q_in         (),
  .sym_valid_i  (),
  .e_out_o      (),
  .e_valid_o    ()
);

*/
