// ---------------- polyphase_interp_mdl (unity-gain, no overflow) ----------
module polyphase_interp_mdl #
(
  parameter int OSF       = 20,   // branches
  parameter int TAPS_PPH  = 5 ,   // taps / branch
  parameter int WIQ       = 16,   // raw width
  parameter int WO        = 18    // out width
)
(
  input  logic                      clk,
  input  logic                      reset_n,
  input  logic signed [WIQ-1:0]     i_raw_i,
  input  logic signed [WIQ-1:0]     q_raw_i,
  input  logic                      iq_raw_val_i,
  input  logic        [4:0]         phase_int_i,
  input  logic        [26:0]        mu_i,          // unused
  input  logic                      sym_valid_i,
  output logic signed [WO-1:0]      i_sym_o,
  output logic signed [WO-1:0]      q_sym_o,
  output logic                      sym_valid_o
);

  // --- 1. delay line ---------------------------------------------------------
  localparam int DEPTH = OSF * TAPS_PPH;   // 100
  typedef logic signed [WIQ-1:0] sample_t;
  sample_t idelay [DEPTH], qdelay [DEPTH];
  int      wr_ptr;

  always_ff @(posedge clk)
    if (iq_raw_val_i) begin
      idelay[wr_ptr] <= i_raw_i;
      qdelay[wr_ptr] <= q_raw_i;
      wr_ptr         <= (wr_ptr==DEPTH-1)? 0 : wr_ptr+1;
    end

  function automatic sample_t rd_i(input int off);
    int idx; begin
      idx = wr_ptr - off;
      if (idx<0) idx+=DEPTH; else if (idx>=DEPTH) idx-=DEPTH;
      return idelay[idx];
    end
  endfunction
  function automatic sample_t rd_q(input int off);
    int idx; begin
      idx = wr_ptr - off;
      if (idx<0) idx+=DEPTH; else if (idx>=DEPTH) idx-=DEPTH;
      return qdelay[idx];
    end
  endfunction

  // --- 2. tap ROM : Q1.15, Σbranch ≃ 32767  🔎 ------------------------------
  typedef logic signed [15:0] coef_t;
  coef_t coeff[OSF][TAPS_PPH];

  initial begin
    real s;
    for (int p=0;p<OSF;p++) begin
      s = $sin((p+0.5)*3.14159265358979/OSF); // 0..π
      for (int k=0;k<TAPS_PPH;k++)
        coeff[p][k] = $rtoi( s * 32767.0 / TAPS_PPH ); //  ≈ 6553 each
    end
  end

  // --- 3. dot product --------------------------------------------------------
  localparam int PROD_W = WIQ + 16;   // 32-bit
  localparam int SHIFT  = 15;         // exact unity (2^15)

  logic signed [PROD_W-1:0] acc_i, acc_q;
  logic                     sym_val_d;

  always_ff @(posedge clk) begin
    sym_val_d <= 0;
    if (sym_valid_i) begin
      acc_i = '0; acc_q = '0;
      for (int k=0;k<TAPS_PPH;k++) begin
        int off = phase_int_i + k*OSF;
        acc_i += rd_i(off)*coeff[phase_int_i][k];
        acc_q += rd_q(off)*coeff[phase_int_i][k];
      end
      i_sym_o   <= acc_i >>> SHIFT;   // unity, full ±32767 span
      q_sym_o   <= acc_q >>> SHIFT;
      sym_val_d <= 1'b1;
    end
  end

  assign sym_valid_o = sym_val_d;

endmodule
