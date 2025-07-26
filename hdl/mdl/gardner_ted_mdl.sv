`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// this module will delay e_out by 1 clock w/respect to I/Q raw (i_in)
// PI loop filter will delay ctrl by 1 clock w/respect to I/Q raw (i_in)
// 
// -----------------------------------------------------------------------------
// Gardner TED – non-synthesizable model  (21-deep buffer, true −20 tap)
// -----------------------------------------------------------------------------
module gardner_ted_mdl #
(
  parameter int RAW_DLY = 20,
  parameter int OSF     = 20,   // samples / symbol
  parameter int WI      = 16,   // I/Q input width
  parameter int WO      = 18    // error-output width
)
(
  input  logic                    clk,
  input  logic                    reset_n,

  // 200-MHz I/Q from interpolator delay-line input
  input  logic signed [WI-1:0]    i_in,
  input  logic signed [WI-1:0]    q_in,
  input                           iq_val,

  // one-symbol strobe from phase-accumulator
  input  logic                    sym_valid_i,

  // Gardner error output
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
  logic signed [ERR_WID-1:0] err,err3, e_out_pre;//  = '{default:'0};
  //assign err = ((Ih * dI) + (Qh * dQ)) >>> (SHIFT);

  (* keep = "true" *) logic signed [2*WI+1:0] err_long, multI, multQ, err_long2,err_long3, mQd, mId;
  assign multI = (Ih * dI);//debug
  assign multQ = (Qh * dQ);//debug
  array_shift_delay_simple # (.LEN(4),.DW(34)) array_shift_delay_simpleI (clk,multI,mId);//debug
  array_shift_delay_simple # (.LEN(4),.DW(34)) array_shift_delay_simpleQ (clk,multQ,mQd);//debug  
  assign err_long2 = (mId + mQd);//debug
  assign err_long3 = err_long2 >>> SHIFT;//debug
  assign err3 = err_long3[2*WI+1:16];//debug

  assign err_long = ((Ih * dI) + (Qh * dQ)) >>> (SHIFT);
  assign err = err_long[2*WI+1:16];
  
  logic e_valid_pre;

  always_ff @(posedge clk) begin
    e_valid_pre <= '0;
    if (sym_valid_i && array_full && iq_val) begin // wait til array is full after reset
      e_out_pre <= err;
      e_valid_pre <= '1;
    end 
  end

  //assign e_out_o   = e_out_pre;
  //assign e_valid_o = e_valid_pre;

  // processing delay in timing recover loop to align samples for interpolator
  //assign i_raw_delay_o = array_i[RAW_DLY];
  //assign q_raw_delay_o = array_q[RAW_DLY];


//-------------------------------------------------------------------------------------------------
// add DSP48 delay to model, 4clk
//-------------------------------------------------------------------------------------------------
  localparam int DSP_DELAY = 4;

  array_shift_delay # (
    .LEN(DSP_DELAY), .DW(ERR_WID)
  ) array_shift_delay (
    .clk(clk), .rst(rst),
    .d_in     (e_out_pre),
    .d_in_val (e_valid_pre),
    .d_out    (e_out_o),
    .d_out_val(e_valid_o)
  );

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
