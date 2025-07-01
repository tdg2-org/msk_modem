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
  input  logic                       clk,
  input  logic                       reset_n,

  // 200-MHz I/Q from interpolator delay-line input
  input  logic signed [WIQ-1:0]      i_in,
  input  logic signed [WIQ-1:0]      q_in,

  // one-symbol strobe from phase-accumulator
  input  logic                       sym_valid_i,

  // Gardner error output
  output logic signed [WERR-1:0]     e_out_o,
  output logic                       e_valid_o
);
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

  logic signed [WIQ-1:0] array_i [OSF:0]; //21 deep
  logic signed [WIQ-1:0] array_q [OSF:0]; //21 deep

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      array_i <= '{default:'0};
      array_q <= '{default:'0};
    end else begin 
      array_i <= {array_i[OSF-1:0],i_in};
      array_q <= {array_q[OSF-1:0],q_in};
    end
  end 

  logic signed [WIQ-1:0] Ic, Ih, Ip, Qc, Qh, Qp, dI, dQ;
  assign Ic = i_in;
  assign Ih = array_i[9];
  assign Ip = array_i[19];
  assign Qc = q_in;
  assign Qh = array_q[9];
  assign Qp = array_q[19];

  assign dI = Ic - Ip;
  assign dQ = Qc - Qp;

  localparam int SHIFT = (WIQ + $clog2(OSF)) - WERR;
  logic signed [17:0] err;
  assign err = ((Ih * dI) + (Qh * dQ)) >>> (SHIFT);

  
  //assign e_out_o    = (sym_valid_i) ? err : e_out_o;
  //assign e_valid_o  = sym_valid_i;

  always_ff @(posedge clk) begin
    e_valid_o <= '0;
    if (sym_valid_i) begin 
      e_out_o <= err;
      e_valid_o <= '1;
    end 
  end

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
