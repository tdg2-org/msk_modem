// designed for my msk demod - LPF after DDC
// compare to xilinx IP and sim in qusta
//
// -----------------------------------------------------------------------------
// 23-tap symmetric low-pass FIR   (non-synthesizable reference model)
//   • Runs one multiply-accumulate every valid input sample
//   • Coefficients hard-coded (Q1.15 signed)  —  NO scaling / shifting applied
//   • Output width = input-width + 15 for easy head-room
//
// Tap list (symmetrical):
//   -374 -579 -822 -908 -693 -74 969 2343 3849 5215 6171
//    6514 6171 5215 3849 2343  969  -74 -693 -908 -822 -579 -374
// -----------------------------------------------------------------------------
module lpf_fixed_mdl #
(
  parameter int NTAPS   = 23,   // fixed
  parameter int WI      = 16,   // input sample width
  parameter int WCOEFF  = 16,   // coefficient width
  parameter int WO      = 31    // output width  (WI + 15)
)
(
  input  logic                  clk,
  input  logic                  rst,
  input  logic signed [WI-1:0]  d_in,
  input  logic                  d_in_val,   
  output logic signed [WI-1:0]  d_out,
  output logic                  d_out_val 
);

  localparam signed [WCOEFF-1:0] coeffs [NTAPS-1:0] = {-374, -579, -822, -908, -693, -74, 969, 2343, 
                                                      3849, 5215, 6171, 6514, 6171, 5215, 3849, 2343, 
                                                      969, -74, -693, -908, -822, -579, -374};


  logic signed [WI-1:0] d_delay [NTAPS-1:0] = '{default:'0};
  logic unsigned [$clog2(NTAPS+1)-1:0] cnt='0; // count up to max NTAPS
  logic delay_full;

  always_ff @(posedge clk) begin 
    if (d_in_val) d_delay <= {d_delay[NTAPS-2:0],d_in};
    if (d_in_val && cnt<NTAPS) cnt <= cnt + 1; 
  end

  assign delay_full = (cnt == NTAPS) ? '1 : '0;

  localparam int PROD_W = WI + WCOEFF;      // 32-bit products
  localparam int ACC_W  = PROD_W + $clog2(NTAPS);  // 32 + 5 = 37 bits
  
  logic signed [ACC_W-1:0] acc_i = '0, acc_s = '0;

  always_ff @(posedge clk) begin 
    if (rst) d_out_val <= '0;
    else if (d_in_val) begin
      acc_s = '0; // BLOCKING: local running sum
      for (int k = 0; k < NTAPS; k++) begin
        acc_s = acc_s + (d_delay[k] * coeffs[k]); // += should work here (blocking only)
      end
      acc_i <= acc_s; // NON-BLOCKING: update register
      d_out_val <= '1;//delay_full;
    end 
  end

  assign d_out      = acc_i[30:15];
  //assign d_out_val  = delay_full;

endmodule



/* instantiation template ------------------------------------------------------

lpf_fixed_mdl #(
  .NTAPS  (23),
  .WI     (16),
  .WO     (31)      // WI + 15 → plenty of head-room
) lpf_fixed_mdl_inst (
  .clk        (),
  .rst        (),
  .d_in       (),
  .d_in_val   (),
  .d_out      (),
  .d_out_val   ()
);

*/
