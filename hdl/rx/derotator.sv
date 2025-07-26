`timescale 1ns / 1ps  // <time_unit>/<time_precision>
// ------------------------------------------------------------
// I_derot = (I * cos) + (Q * sin)
// Q_derot = (Q * cos) - (I * sin)
// 
// ------------------------------------------------------------
module derotator #(
  parameter int WIDTH        = 16,
  parameter int DDS_WIDTH    = 16,
  parameter int PHASE_WIDTH  = 32  // kept for interface symmetry
)(
  input  logic                           clk,
  input  logic                           rst,            // sync reset (active‑high)
  input  logic                           sym_valid_in,   // 1 = symbol‑center sample
  input  logic signed [WIDTH-1:0]        din_i,
  input  logic signed [WIDTH-1:0]        din_q,
  input  logic signed [DDS_WIDTH-1:0]    cos_in,         // cos(phase)
  input  logic signed [DDS_WIDTH-1:0]    sin_in,         // sin(phase)
  output logic                           sym_valid_out,  // aligned with dout_*
  output logic signed [WIDTH-1:0]        dout_i,
  output logic signed [WIDTH-1:0]        dout_q
);

  localparam int DSP_IWID = 18;
  localparam int DSP_OWID = 48;
  logic signed [DSP_IWID-1:0] dspI,dspQ,dspCos,dspSin;
  logic signed [DSP_OWID-1:0] mult_Icos,mult_Qsin,mult_Isin,mult_Qcos;
  logic signed [DSP_OWID:0]   i_derot_pre, q_derot_pre;

  assign dspI   = signed'({din_i});
  assign dspQ   = signed'({din_q});
  assign dspCos = signed'({cos_in});
  assign dspSin = signed'({sin_in});

  //dsp_mix. sel = 0: A*B-C, sel = 1: A*B+C
  dsp_mix dsp_Icos ( // dsp_mix
    .CLK  (clk          ),
    .CE   (sym_valid_in ),
    .SEL  ('1           ),  // A*B+C 
    .A    (dspI         ), // in [17:0]
    .B    (dspCos       ), // in [17:0]
    .C    ('0           ), // in [17:0]
    .P    (mult_Icos    )  // out [47:0]
  );

  dsp_mix dsp_Qsin ( // dsp_mix
    .CLK  (clk          ),
    .CE   (sym_valid_in ),
    .SEL  ('1           ),  // A*B+C 
    .A    (dspQ         ), // in [17:0]
    .B    (dspSin       ), // in [17:0]
    .C    ('0           ),  // in [17:0]
    .P    (mult_Qsin    )  // out [47:0]
  );

  dsp_mix dsp_Isin ( // dsp_mix
    .CLK  (clk          ),
    .CE   (sym_valid_in ),
    .SEL  ('1           ),  // A*B+C 
    .A    (dspI         ), // in [17:0]
    .B    (dspSin       ), // in [17:0]
    .C    ('0           ), // in [17:0]
    .P    (mult_Isin    )  // out [47:0]
  );

  dsp_mix dsp_Qcos ( // dsp_mix
    .CLK  (clk          ),
    .CE   (sym_valid_in ),
    .SEL  ('1           ),  // A*B+C 
    .A    (dspQ         ), // in [17:0]
    .B    (dspCos       ), // in [17:0]
    .C    ('0           ),  // in [17:0]
    .P    (mult_Qcos    )  // out [47:0]
  );


  assign i_derot_pre = mult_Icos + mult_Qsin;
  assign q_derot_pre = mult_Qcos - mult_Isin;

  // delay sym val DSP delay 4clk/CEs
  localparam DSP_DELAY = 4;
  logic [DSP_DELAY-1:0] sym_val_sr = '0;
  logic sym_valid_pre = 0;

  always_ff @(posedge clk) begin 
    if (sym_valid_in) sym_val_sr <= {sym_val_sr[DSP_DELAY-2:0],sym_valid_in};//4 DSP CEs delay 
    if (&sym_val_sr[DSP_DELAY-2:0])  sym_valid_pre <= sym_valid_in; // "DSP_DELAY-2" : ready ON THE 4TH CE + 1clk delay
  end

  // outputs
  assign sym_valid_out = sym_valid_pre;
  assign dout_i = i_derot_pre[30:15];
  assign dout_q = q_derot_pre[30:15];


endmodule

/*

  derotator_mdl #(
    .WIDTH        (16),
    .DDS_WIDTH    (16),
    .PHASE_WIDTH  (32) 
  ) derotator_mdl_inst (
    .clk            (clk),
    .rst            (rst),
    .sym_valid_in   (),
    .din_i          (),
    .din_q          (),
    .cos_in         (),
    .sin_in         (),
    .sym_valid_out  (),
    .dout_i         (),
    .dout_q         ()
  );


*/