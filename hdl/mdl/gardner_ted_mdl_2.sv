// -----------------------------------------------------------------------------
// Gardner TED – non-synthesizable model  (21-deep buffer, true −20 tap)
// -----------------------------------------------------------------------------
module gardner_ted_mdl_2 #
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

  // ---------------------------------------------------------------------------
  // 1. circular buffer : depth = OSF + 1  (0 … 20)
  // ---------------------------------------------------------------------------
  localparam int DEPTH = OSF + 1;           // 21

  typedef struct packed { logic signed [WIQ-1:0] i, q; } iq_t;
  iq_t delay [DEPTH];
  int  wr_idx;

  initial begin
    foreach (delay[idx])           // idx iterates 0 … DEPTH-1
      delay[idx] = '{default:'0};  // sets both .i and .q to 0
  end

  // pre-increment pointer before write
  always_ff @(posedge clk) begin
    if (!reset_n) begin
      wr_idx <= 0;
    end else begin
      int nxt = (wr_idx == DEPTH-1) ? 0 : wr_idx + 1;
      delay[nxt].i <= i_in;
      delay[nxt].q <= q_in;
      wr_idx       <= nxt;
    end
  end

  // wrapped read
  function automatic iq_t tap (input int rel);
    int idx;
    begin
      idx = wr_idx + rel;
      if (idx < 0)         idx += DEPTH;
      else if (idx >= DEPTH) idx -= DEPTH;
      return delay[idx];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 2. Gardner timing error (executes once per sym_valid_i)
  // ---------------------------------------------------------------------------
  localparam int SHIFT = (WIQ + $clog2(OSF)) - WERR;

  logic signed [WIQ-1:0] Ic=0,Qc=0, Ih=0,Qh=0, Ip=0,Qp=0;
  logic signed [WIQ  :0] dI=0,dQ=0;
  logic signed [2*WIQ:0] e_long=0;

  always_comb begin
    e_out_o   = '0;
    e_valid_o = 1'b0;

    if (sym_valid_i) begin
      {Ic,Qc} = {tap( 0       ).i, tap( 0       ).q}; // current      (n)
      {Ih,Qh} = {tap(-OSF/2   ).i, tap(-OSF/2   ).q}; // −10 samples  (n–10)
      {Ip,Qp} = {tap(-OSF     ).i, tap(-OSF     ).q}; // −20 samples  (n–20)

      dI      = Ic - Ip;
      dQ      = Qc - Qp;
      e_long  = Ih * dI + Qh * dQ;

      e_out_o   = e_long >>> SHIFT;
      e_valid_o = 1'b1;
    end
  end

endmodule



/* instantiation template ------------------------------------------------------

gardner_ted_mdl_2 #(
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
