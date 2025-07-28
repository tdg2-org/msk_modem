`timescale 1ns / 1ps  // <time_unit>/<time_precision>



module msk_slicer_dec #
(
  parameter int IW = 18   // width of I/Q symbol samples
)(
  input  logic                      clk,
  input  logic                      reset_n,

  // interpolator outputs
  input  logic signed [IW-1:0]      i_sym_i,
  input  logic signed [IW-1:0]      q_sym_i,
  input  logic                      sym_valid_i,

  // recovered bit
  output logic                      data_o,
  output logic                      data_valid_o
);

//  imag = q_in * I_prev - i_in * Q_prev
//  data_out = (imag_diff >= 0) ? 1:0;

  logic                  prev_valid;
  logic signed [IW-1:0]  I_prev=0, Q_prev=0;

  always_ff @(posedge clk) begin
    prev_valid <= '0;
    if (sym_valid_i) begin
      I_prev     <= i_sym_i;
      Q_prev     <= q_sym_i;
      prev_valid <= 1'b1;     // becomes valid after first symbol
    end
  end


  localparam int DSP_IWID = 18;
  localparam int DSP_OWID = 48;
  logic signed [DSP_IWID-1:0] dspI,dspQ,dspI_delay,dspQ_delay;
  logic signed [DSP_OWID:0]   IxQP, QxIP, imag_diff;

  assign dspI       = signed'(i_sym_i );
  assign dspQ       = signed'(q_sym_i );
  assign dspI_delay = signed'(I_prev  );
  assign dspQ_delay = signed'(Q_prev  );


  //dsp_mix. sel = 0: A*B-C, sel = 1: A*B+C
  dsp_mix dsp_IxQP ( // dsp_mix
    .CLK  (clk          ),
    .CE   (sym_valid_i  ),
    .SEL  ('1           ),  // A*B+C 
    .A    (dspI         ),  // in [17:0]
    .B    (dspQ_delay   ),  // in [17:0]
    .C    ('0           ),  // in [17:0]
    .P    (IxQP         )   // out [47:0]
  );

  dsp_mix dsp_QxIP ( // dsp_mix
    .CLK  (clk          ),
    .CE   (sym_valid_i  ),
    .SEL  ('1           ),  // A*B+C 
    .A    (dspQ         ),  // in [17:0]
    .B    (dspI_delay   ),  // in [17:0]
    .C    ('0           ),  // in [17:0]
    .P    (QxIP         )   // out [47:0]
  );

  logic data_pre;

  assign imag_diff = QxIP - IxQP;
  assign data_pre = (imag_diff >= 0) ? 1:0;


  // delay sym val DSP delay 4clk/CEs
  localparam DSP_DELAY = 4;
  logic [DSP_DELAY-1:0] sym_val_sr = '0;
  logic sym_valid_pre = 0;

  always_ff @(posedge clk) begin 
    if (sym_valid_i) sym_val_sr <= {sym_val_sr[DSP_DELAY-2:0],sym_valid_i};//4 DSP CEs delay 
    if (&sym_val_sr[DSP_DELAY-2:0])  sym_valid_pre <= sym_valid_i; // "DSP_DELAY-2" : ready ON THE 4TH CE + 1clk delay  
  end

  always_ff @(posedge clk) begin 
    data_o       <= data_pre;
    data_valid_o <= sym_valid_pre;
  end

endmodule


/* instantiation template ------------------------------------------------------

msk_slicer_dec #(
  .IW (18)
) msk_slicer_dec (
  .clk          (),
  .reset_n      (),
  .i_sym_i      (),
  .q_sym_i      (),
  .sym_valid_i  (),
  .data_o       (),
  .data_valid_o ()
);

*/
