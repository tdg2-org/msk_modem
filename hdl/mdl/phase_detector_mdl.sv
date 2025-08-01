`timescale 1ns / 1ps  // <time_unit>/<time_precision>
// ------------------------------------------------------------
// Phase-detector model  ✧  decision-directed, MSK / BPSK-compatible
//   • Runs at the 200 MHz sample clock
//   • Updates output only when sym_valid==1  (10 MHz)
//   • Uses previous symbol to form the error term:
//         e ≈ I(n)*Q(n-1) - Q(n)*I(n-1)
// ------------------------------------------------------------
module phase_detector_mdl #(
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

  logic                  err_valid_pre;
  logic signed [EW-1:0]  phase_err_pre;

  //--- constants for int⇄real scaling ------------------------
  localparam real IQ_SCALE   =  1.0 / (1 << (IW-1));  // int → real  (≈ ±1.0)
  localparam real ERR_ISCALE =  (1 << (EW-2));    // real → Q2.(EW-2)
  localparam int  ERR_MAX    =  (1 << (EW-1)) - 1;
  localparam int  ERR_MIN    = -(1 << (EW-1));

  //--- pipeline registers for previous symbol ----------------
  real prev_i, prev_q, curr_i, curr_q, err_r;
  int  err_i;

  //--- main logic --------------------------------------------
  always_ff @(posedge clk) begin
    if (rst) begin
      prev_i    <= 0.0;
      prev_q    <= 0.0;
      phase_err_pre <= '0;
      err_valid_pre <= 1'b0;
    end else begin
      // default: not valid unless we assert below
      err_valid_pre <= 1'b0;

      if (sym_valid) begin
        // convert current int samples → real
        curr_i = $itor(din_i) * IQ_SCALE;
        curr_q = $itor(din_q) * IQ_SCALE;

        // decision-directed error: e = I·Q_prev - Q·I_prev
        err_r  = curr_i * prev_q - curr_q * prev_i;

        // scale to fixed-point and saturate
        err_i  = $rtoi(err_r * ERR_ISCALE);
        if (err_i >  ERR_MAX) err_i = ERR_MAX;
        if (err_i <  ERR_MIN) err_i = ERR_MIN;
        phase_err_pre   <= err_i;

        // update valid flag
        err_valid_pre   <= 1'b1;

        // pipeline previous symbol for next error calc
        prev_i      <= curr_i;
        prev_q      <= curr_q;
      end
    end
  end

  //assign err_valid = err_valid_pre;  
  //assign phase_err = phase_err_pre;

//-------------------------------------------------------------------------------------------------
// delay to match synth version
//-------------------------------------------------------------------------------------------------

  // delay sym val DSP delay 4clk/CEs
  localparam DSP_DELAY = 4;
  logic [DSP_DELAY-1:0] sym_val_sr = '0;
  logic sym_valid_pre = 0;
  logic signed [EW-1:0]  phase_err_pre_delay [DSP_DELAY-1:0];

  always_ff @(posedge clk) begin 
    if (sym_valid) sym_val_sr <= {sym_val_sr[DSP_DELAY-2:0],sym_valid};//4 DSP CEs delay 
    if (sym_valid) phase_err_pre_delay <= {phase_err_pre_delay[DSP_DELAY-2:0],phase_err_pre};//4 DSP CEs delay 
    if (&sym_val_sr[DSP_DELAY-2:0])  sym_valid_pre <= sym_valid; // "DSP_DELAY-2" : ready ON THE 4TH CE + 1clk delay
  end


  assign err_valid = sym_valid_pre;  
  assign phase_err = phase_err_pre_delay[2];


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