`timescale 1ns / 1ps  // <time_unit>/<time_precision>
// ------------------------------------------------------------
// Phase-detector model  ✧  decision-directed, MSK / BPSK-compatible
//   • Runs at the 200 MHz sample clock
//   • Updates output only when sym_valid==1  (10 MHz)
//   • Uses previous symbol to form the error term:
//         e ≈ I(n)*Q(n-1) - Q(n)*I(n-1)
// ------------------------------------------------------------
module phase_detector #(
  parameter int IW  = 16,  // word width of I/Q samples
  parameter int EW  = 24   // word width of fixed-point error
)(
  input  logic                  clk,
  input  logic                  rst,          // synchronous, active-high
  input  logic                  sym_valid,    // asserted on symbol-center sample
  input  logic signed [IW-1:0]  din_i,
  input  logic signed [IW-1:0]  din_q,

  output logic                  err_valid,    // 1-cycle delayed sym_valid
  output logic signed [EW-1:0]  phase_err
);

  localparam int DSP_IWID = 18;
  localparam int DSP_OWID = 48;
  logic signed [DSP_IWID-1:0] dspI,dspQ,dspI_delay,dspQ_delay;
  logic signed [DSP_OWID:0]   dsp_I_Qdelay, dsp_Q_Idelay, err;
  logic signed [IW-1:0] i_delay=0, q_delay=0;

  always_ff @(posedge clk) begin
    if (sym_valid) begin 
      i_delay <= din_i;
      q_delay <= din_q;
    end
  end

  assign dspI       = signed'(din_i   );
  assign dspQ       = signed'(din_q   );
  assign dspI_delay = signed'(i_delay );
  assign dspQ_delay = signed'(q_delay );

  //dsp_mix. sel = 0: A*B-C, sel = 1: A*B+C
  dsp_mix dsp_I_Qd ( // dsp_mix
    .CLK  (clk          ),
    .CE   (sym_valid    ),
    .SEL  ('1           ),  // A*B+C 
    .A    (dspI         ), // in [17:0]
    .B    (dspQ_delay   ), // in [17:0]
    .C    ('0           ), // in [17:0]
    .P    (dsp_I_Qdelay )  // out [47:0]
  );

  dsp_mix dsp_Q_Id ( // dsp_mix
    .CLK  (clk          ),
    .CE   (sym_valid    ),
    .SEL  ('1           ),  // A*B+C 
    .A    (dspQ         ), // in [17:0]
    .B    (dspI_delay   ), // in [17:0]
    .C    ('0           ), // in [17:0]
    .P    (dsp_Q_Idelay )  // out [47:0]
  );

  assign err = dsp_I_Qdelay - dsp_Q_Idelay;

  // delay sym val DSP delay 4clk/CEs
  localparam DSP_DELAY = 4;
  logic [DSP_DELAY-1:0] sym_val_sr = '0;
  logic sym_valid_pre = 0;

  always_ff @(posedge clk) begin 
    if (sym_valid) sym_val_sr <= {sym_val_sr[DSP_DELAY-2:0],sym_valid};//4 DSP CEs delay 
    if (&sym_val_sr[DSP_DELAY-2:0])  sym_valid_pre <= sym_valid; // "DSP_DELAY-2" : ready ON THE 4TH CE + 1clk delay
  end

  assign phase_err = err[31:8];
  assign err_valid = sym_valid_pre;

endmodule

/*

  phase_detector_mdl #(
    .IW (16), 
    .EW (24)  
  ) phase_detector_mdl_inst (
    .clk        (clk),
    .rst        (rst),
    .sym_valid  (),
    
    .din_i      (),
    .din_q      (),
    .err_valid  (),
    .phase_err  ()
  );


*/