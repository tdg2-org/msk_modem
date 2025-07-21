`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// Downconversion module: converts a real ADC input at IF to I/Q baseband.
module ddc_lpf_mdl #(
    parameter real  IF = 50e6,   // Intermediate frequency in Hz.
    parameter real  FS = 200e6,   // Sample rate in Hz.
    parameter int   WI = 16,
    parameter int   WO = 16,
    parameter int   SIM_DELAY = 21
)(
    input  logic       clk,
    input  logic       rst,
    input  logic signed [WI-1:0]  adc_in,   // ADC input (digitized real signal).
    input  logic                  adc_val,
    output logic signed [WO-1:0]  I_out,    // Recovered In-phase component.
    output logic signed [WO-1:0]  Q_out,     // Recovered Quadrature component.
    output logic                  iq_out_val
);

   // Internal time tracking.
   real t;
   real sample_period = 1.0 / FS;
   real two_pi = 6.283185307179586;

  logic [15:0] i_ddc,q_ddc;
  logic iq_val;
  real adc_in_real, mix_I, mix_Q;

   initial begin
      t = 0.0;
   end

   always @(posedge clk) begin
      if (rst) begin
         t <= 0.0;
         i_ddc <= 0;
         q_ddc <= 0;
         iq_val <= '0;
      end else if (adc_val) begin
         // Convert the ADC input to real.
         adc_in_real = $itor(adc_in);
         // Mix the ADC input with cosine and -sine to extract I and Q.
         mix_I = adc_in_real * $cos(two_pi * IF * t);
         mix_Q = -adc_in_real * $sin(two_pi * IF * t);
         // Convert the mixed results back to 16-bit integers.
         i_ddc <= $rtoi(mix_I);
         q_ddc <= $rtoi(mix_Q);
         // Increment time.
         t <= t + sample_period;
         iq_val <= '1;
      end
   end


// INVERTING TO MATCH XILINX IP
  logic [15:0] i_ddc2,q_ddc2;
  assign i_ddc2 = -i_ddc;
  assign q_ddc2 = -q_ddc;

//-------------------------------------------------------------------------------------------------
// LPF
//-------------------------------------------------------------------------------------------------

  logic signed [15:0] i_fir, q_fir;

  lpf_fixed_mdl #(
    .NTAPS  (23),
    .WI     (16),
    .WO     (31) 
  ) lpf_fixed_mdl_inst_I (
    .clk        (clk    ),
    .rst        (rst    ),
    .d_in       (i_ddc2  ),
    .d_in_val   (iq_val ),
    .d_out      (i_fir  ),
    .d_out_val  (fir_val)
  );

  lpf_fixed_mdl #(
    .NTAPS  (23),
    .WI     (16),
    .WO     (31) 
  ) lpf_fixed_mdl_inst_Q (
    .clk        (clk    ),
    .rst        (rst    ),
    .d_in       (q_ddc2  ),
    .d_in_val   (iq_val ),
    .d_out      (q_fir  ),
    .d_out_val  ()
  );


//-------------------------------------------------------------------------------------------------
// simulate delay from xilinx ip (DDS,DSP48,LPF)
//-------------------------------------------------------------------------------------------------

  logic signed [15:0] idelay [SIM_DELAY-1:0];
  logic signed [15:0] qdelay [SIM_DELAY-1:0];
  logic [SIM_DELAY-1:0] val_delay;

  always_ff @(posedge clk) begin 
    idelay    <= {idelay[SIM_DELAY-2:0], i_fir};
    qdelay    <= {qdelay[SIM_DELAY-2:0], q_fir};
    val_delay <= {val_delay[SIM_DELAY-2:0], fir_val};
  end 

  // unequal delays, aligning valid and i/q to match xilinx IP
  assign I_out      = idelay[SIM_DELAY-2];
  assign Q_out      = qdelay[SIM_DELAY-2];
  assign iq_out_val = val_delay[SIM_DELAY-1];


endmodule
/*

ddc_mdl #(
  .IF( ),
  .FS(),
  .SIM_DELAY()
) ddc_mdl_inst (
  .clk    (),
  .reset  (),
  .adc_in (),
  .I_out  (),
  .Q_out  (),
  .iq_out_val()
);


*/
