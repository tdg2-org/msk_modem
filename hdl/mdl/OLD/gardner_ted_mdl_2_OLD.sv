// -----------------------------------------------------------------------------
// Gardner TED – non-synthesizable model  (pointer-fix version)
// -----------------------------------------------------------------------------
module gardner_ted_mdl_2 #
(
  parameter int OSF  = 20,   // samples / symbol
  parameter int WIQ  = 16,   // input I/Q width
  parameter int WERR = 18    // e_out_o width
)
(
  input  logic                       clk,
  input  logic                       reset_n,

  input  logic signed [WIQ-1:0]      i_in,          // oversampled I
  input  logic signed [WIQ-1:0]      q_in,          // oversampled Q
  input  logic                       sym_valid_i,   // 1-clk pulse / symbol

  output logic signed [WERR-1:0]     e_out_o,       // timing error
  output logic                       e_valid_o      // 1-clk pulse with e_out_o
);

  // ---------------------------------------------------------------------------
  // 1. 20-sample circular buffer  (write pointer pre-incremented)
  // ---------------------------------------------------------------------------
  typedef struct packed { logic signed [WIQ-1:0] i, q; } iq_t;
  iq_t delay [OSF];
  int  wr_idx;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      wr_idx <= 0;
    end else begin
      int nxt = (wr_idx == OSF-1) ? 0 : wr_idx + 1;   // pre-increment
      delay[nxt].i <= i_in;
      delay[nxt].q <= q_in;
      wr_idx       <= nxt;
    end
  end

  // helper: wrapped read
  function automatic iq_t tap (input int rel);
    int idx;
    begin
      idx = wr_idx + rel;
      if (idx < 0)          idx += OSF;
      else if (idx >= OSF)  idx -= OSF;
      return delay[idx];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 2. timing-error calc on sym_valid_i
  // ---------------------------------------------------------------------------
  localparam int SHIFT = (WIQ + $clog2(OSF)) - WERR;

  logic signed [WIQ-1:0] Ic,Qc, Ih,Qh, Ip,Qp;
  logic signed [WIQ  :0] dI,dQ;
  logic signed [2*WIQ:0] e_long;

  always_comb begin
    e_out_o   = '0;
    e_valid_o = 1'b0;

    if (sym_valid_i) begin
      {Ic,Qc} = {tap( 0).i, tap( 0).q};
      {Ih,Qh} = {tap(-OSF/2).i, tap(-OSF/2).q}; // −10
      {Ip,Qp} = {tap(-(OSF-1)).i, tap(-(OSF-1)).q}; // −19

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
