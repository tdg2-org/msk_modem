`timescale 1ns / 1ps  // <time_unit>/<time_precision>

module msk_demod_mdl #(
    parameter real FS = 200.0e6,  // Sample rate (Hz)
    parameter real F_SYM = 10.0e6 // Symbol rate (Hz)
)(
    input logic clk,
    input logic reset_n,
    input int   midpoint_adj,
    input logic signed [15:0] i_in,  // In-phase (I) input from if_to_iq
    input logic signed [15:0] q_in,  // Quadrature (Q) input from if_to_iq
    input logic               iq_val,
    output logic data_out,            // Recovered binary data
    output logic data_val
);

  //debug
  logic greater=0,less=0;

  // Compute number of samples per symbol
  localparam int SAMPLES_PER_SYM = int'(FS / F_SYM);
  
  // Compute symbol sampling midpoint
  localparam int SAMPLE_MIDPOINT = (SAMPLES_PER_SYM / 2);
  logic signed [31:0] phase_prev, phase_curr;
  logic signed [31:0] phase_diff;
  integer sample_count, midpoint;
  logic sample_midpoint_active;
  // Compute atan2 in fixed-point format
  function automatic signed [31:0] atan2_fixed(input signed [15:0] y, input signed [15:0] x);
      automatic real phase_radians;
      phase_radians = $atan2(real'(y), real'(x)); // Compute atan2 in radians
      return int'(phase_radians * (2.0**30) / 3.14159265); // Scale to Q30 fixed-point
  endfunction
  
  assign midpoint = SAMPLE_MIDPOINT + midpoint_adj;
  
  logic signed [31:0] phase_new,delta;

  // -----------------------------------------------------------------------------
  // phase tracker and symbol-midpoint decision   (drop-in replacement)
  // -----------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    // ---------------------------------------------------------------------------
    // 1. synchronous reset
    // ---------------------------------------------------------------------------
    if (!reset_n) begin
      phase_prev            <= '0;
      phase_curr            <= '0;
      phase_diff            <= '0;
      sample_count          <= 0;
      data_out              <= 0;
      sample_midpoint_active<= 0;
      greater               <= 0;
      less                  <= 0;
    end

    // ---------------------------------------------------------------------------
    // 2. run only when a new I/Q sample is valid
    // ---------------------------------------------------------------------------
    else if (iq_val) begin
      //---------------------------------------------------------------------------
      // 2-a  compute atan2 *once* → temp variable
      //---------------------------------------------------------------------------
      phase_new = atan2_fixed(q_in, i_in);   // Q1.30

      //---------------------------------------------------------------------------
      // 2-b  update phase history and raw delta (1-sample spacing)
      //---------------------------------------------------------------------------
      phase_prev <= phase_curr;
      phase_curr <= phase_new;

      delta = phase_new - phase_curr;        // use *new* − *prev*

      //---------------------------------------------------------------------------
      // 2-c  unwrap (±π) with **signed 32-bit literals**
      //---------------------------------------------------------------------------
      greater <= 0; less <= 0;
      if      (delta > 32'sd1073741824)  begin   //  +π/2 in Q30
         delta   -= 32'sd2147483648;             //  −π
         greater <= 1;
      end
      else if (delta < -32'sd1073741824) begin   //  −π/2
         delta   += 32'sd2147483648;             //  +π
         less    <= 1;
      end
      phase_diff <= delta;       // store the final unwrapped delta

      //---------------------------------------------------------------------------
      // 2-d  midpoint counter & data decision
      //---------------------------------------------------------------------------
      sample_midpoint_active <= 0;
      sample_count  <= (sample_count == SAMPLES_PER_SYM-1) ? 0
                      : sample_count + 1;

      if (sample_count == midpoint) begin
        sample_midpoint_active <= 1;
        data_out <= (delta > 0);             // MSK differential decision
      end
    end
  end

  // output strobe
  assign data_val = iq_val & sample_midpoint_active;


endmodule

/*

msk_demod_mdl #(
  .FS     (),  
  .F_SYM  ()   
)msk_demodulator_mdl_inst(
  .clk          (),
  .reset_n      (),
  .midpoint_adj (),
  .i_in         (),
  .q_in         (),
  .data_out     ()
);


*/