`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// this module will delay e_out by 1 clock w/respect to I/Q raw (i_in)
// PI loop filter will delay ctrl by 1 clock w/respect to I/Q raw (i_in)
// 
// -----------------------------------------------------------------------------
// Gardner TED – non-synthesizable model  (21-deep buffer, true −20 tap)
// -----------------------------------------------------------------------------
module gardner_ted_mdl_3 #
(
  parameter int OSF  = 20,   // samples / symbol
  parameter int WIQ  = 16,   // I/Q input width
  parameter int WERR = 18    // error-output width
)
(
  input  logic                    clk,
  input  logic                    reset_n,

  // 200-MHz I/Q from interpolator delay-line input
  input  logic signed [WIQ-1:0]   i_in,
  input  logic signed [WIQ-1:0]   q_in,
  input                           iq_val,

  // one-symbol strobe from phase-accumulator
  input  logic                    sym_valid_i,

  // Gardner error output
  output logic signed [WERR-1:0]  e_out_o,
  output logic                    e_valid_o,

  output  logic signed [WIQ-1:0]   i_raw_delay_o,
  output  logic signed [WIQ-1:0]   q_raw_delay_o
);
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

  logic signed [WIQ-1:0] array_i [OSF:0]; //21 deep
  logic signed [WIQ-1:0] array_q [OSF:0]; //21 deep

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

  logic signed [WIQ-1:0] Ic, Ih, Ip, Qc, Qh, Qp, dI, dQ;
  assign Ic = i_in;         // 0th current sample
  assign Ih = array_i[9];   // 10th half symbol delay sample
  assign Ip = array_i[19];  // 20th full symbol delay sample
  assign Qc = q_in;
  assign Qh = array_q[9];
  assign Qp = array_q[19];

  assign dI = Ic - Ip;
  assign dQ = Qc - Qp;

  localparam int SHIFT = (WIQ + $clog2(OSF)) - WERR;
  logic signed [17:0] err;
  //assign err = ((Ih * dI) + (Qh * dQ)) >>> (SHIFT);

  logic signed [2*WIQ+1:0] err_long;
  assign err_long = ((Ih * dI) + (Qh * dQ)) >>> (SHIFT);
  assign err = err_long[2*WIQ+1:16];
  
  always_ff @(posedge clk) begin
    e_valid_o <= '0;
    if (sym_valid_i && array_full) begin // wait til array is full after reset
      e_out_o <= err;
      e_valid_o <= '1;
    end 
  end


// processing delay in timing recover loop to align samples for interpolator
  localparam int RAW_DLY = 11;
  assign i_raw_delay_o = array_i[RAW_DLY-1];
  assign q_raw_delay_o = array_q[RAW_DLY-1];


endmodule



/* instantiation template ------------------------------------------------------

gardner_ted_mdl_3 #(
  .OSF  (20),
  .WIQ  (16),
  .WERR (18)
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
