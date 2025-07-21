
// generate data here, modulate it, 
// add distortions/noise/nonlinearities with 'mdl' models to signal
// feed signal straight to RX path demod

module msk_tb;

    // Clock and reset
    logic clk=0;
    logic reset_n;

    // Binary data input
    logic data_in,demod_data;

    // I/Q signals
    logic signed [15:0] i_out, q_out, i_demod, q_demod,dc_I,dc_Q, i_noisy, q_noisy;
    logic signed [15:0] i_cfo, q_cfo, i_jitter, q_jitter, i_faded, q_faded, i_nldist, q_nldist;
    logic signed [15:0] i_fir, q_fir;
    // Real-valued IF signal
    logic signed [15:0] dac_data;

    // Clock generation (200 MHz)
    always #2.5ns clk = ~clk; // 5 ns period (200 MHz)
    //always #625ps clk = ~clk; // 800 MHz



    msk_mod #(
        .FS(200.0e6)
    ) msk_mod_inst (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(data_in),
        .i_out(i_out),
        .q_out(q_out)
    );

//    timing_jitter_mdl #(
//        .JITTER_STD_DEV(0.05)
//    ) jitter_mdl_inst (
//      .clk(clk),
//      .reset(~reset_n),
//      .i_in(i_out),
//      .q_in(q_out),
//      .i_out(),
//      .q_out()
//    );

    timing_jitter_drift_mdl #(
        .INITIAL_OFFSET(0.0),
        .DRIFT_PER_SAMPLE(0.000),
        .ENABLE_RANDOM_JITTER(0)
    ) jitter_drift_mdl_inst (
      .clk(clk),
      .reset(~reset_n),
      .i_in(i_out),
      .q_in(q_out),
      .i_out(i_jitter),
      .q_out(q_jitter)
    );

    cfo_mdl #(
        .CFO_HZ(0),//500.0),
        .FS(200.0e6)
    ) cfo_mdl_inst (
      .clk(clk),
      .reset(~reset_n),
      .i_in(i_jitter),
      .q_in(q_jitter),
      .i_out(i_cfo),
      .q_out(q_cfo)
    );


    phase_noise_mdl #(
      .PHASE_NOISE_STD_DEV(0)//(0.04)
    ) phase_noise_mdl_inst (
      .clk(clk),
      .reset(~reset_n),
      .i_in(i_cfo),
      .q_in(q_cfo),
      .i_out(i_noisy),
      .q_out(q_noisy)
    );

    multipath_fading_mdl #(
    //  .NUM_PATHS(3), .DOPPLER_FREQ(100.0), .SAMPLE_RATE(200.0e6), .K_FACTOR(5)
      .NUM_PATHS(0), .DOPPLER_FREQ(0.0), .SAMPLE_RATE(200.0e6), .K_FACTOR(0)
    ) multipath_fading_mdl_inst (
      .clk(clk),
      .reset(~reset_n),
      .i_in(i_noisy),
      .q_in(q_noisy),
      .i_out(i_faded),
      .q_out(q_faded)
    );

    nonlinear_distortion_mdl #(
      //.ALPHA(0.005), .P(2.0)
      .ALPHA(0.0), .P(0.0)
    ) nonlinear_distortion_mdl_inst (
      .clk(clk),
      .reset(~reset_n),
      .i_in(i_faded),
      .q_in(q_faded),
      .i_out(i_nldist),
      .q_out(q_nldist)
    );

    duc_ddc_top #(
      .FS(200e6)
    ) duc_ddc_top_inst (
      .clk      (clk      ),
      .reset    (~reset_n ),
      //DDC
      .adc_in   (dac_awgn ), // from ADC
      .I_out    (dc_I     ), // to demod
      .Q_out    (dc_Q     ), // to demod
      //DUC
      .I_in     (i_nldist  ), // from modulator
      .Q_in     (q_nldist  ), // from modulator
      .dac_out  (dac_data )  // to DAC
    );

  logic signed [15:0] dac_atten, dac_awgn;

    signal_atten_mdl #(
      .SHIFT_VAL(0),
      .SCALE_FACTOR(0)
    ) dac_atten_inst (
      .signal_in(dac_data),
      .signal_out(dac_atten)
    );


    awgn_noise_gen_mdl #(
      .NOISE_STD_DEV(0)//(40.0)
    ) awgn_inst (
      .clk(clk),
      .reset(~reset_n),
      .signal_in(dac_atten),
      .signal_out(dac_awgn)
    );

    logic signed [31:0] fir_I_tdata, fir_Q_tdata;

    fir_lpf fir_lpf_dc_I (
      .aclk               (clk      ),    // input wire aclk
      .s_axis_data_tvalid ('1       ),   // input wire s_axis_data_tvalid
      .s_axis_data_tready (         ), // output wire s_axis_data_tready
      .s_axis_data_tdata  (dc_I        ),        // input wire [15 : 0] s_axis_data_tdata
      .m_axis_data_tvalid (         ), // output wire m_axis_data_tvalid
      .m_axis_data_tdata  (fir_I_tdata      )  // output wire [31 : 0] m_axis_data_tdata
    );

    fir_lpf fir_lpf_dc_Q (
      .aclk               (clk      ),    // input wire aclk
      .s_axis_data_tvalid ('1       ),   // input wire s_axis_data_tvalid
      .s_axis_data_tready (         ), // output wire s_axis_data_tready
      .s_axis_data_tdata  (dc_Q     ),        // input wire [15 : 0] s_axis_data_tdata
      .m_axis_data_tvalid (         ), // output wire m_axis_data_tvalid
      .m_axis_data_tdata  (fir_Q_tdata      )  // output wire [31 : 0] m_axis_data_tdata
    );

    assign i_fir = fir_I_tdata[30:15];
    assign q_fir = fir_Q_tdata[30:15];

    real ted_error;

    gardner_ted_mdl #(
      .MID_POINT(16)
    ) gardner_MDL (
        .clk(clk),
        .reset(~reset_n),
        .I_in(i_fir),
        .Q_in(q_fir),
        .error(ted_error),
        .symbol_valid()
    );

    loop_filter_mdl #(
      .Kp(0.05),
      .Ki(0.001)
    ) loop_filter_mdl_inst (
        .clk(clk),
        .reset(~reset_n),
        .error(ted_error),
        .control_signal()
    );


    msk_demod #(
        .FS(200.0e6)
    ) msk_demod_inst (
        .clk(clk),
        .reset_n(reset_n),
        .midpoint_adj(1),
        .i_in(i_out),   //(i_fir),
        .q_in(q_out),   //(q_fir),
        .data_out(demod_data)
    );


    // Test vector
    integer file;
    integer i,x;
    logic [7:0] test_vector[0:31] = '{8'h90, 8'h10, 0, 0, 0, 8'h33, 0, 0, 
                                      0, 8'hff, 8'hff, 8'hff, 8'hff, 8'h1a, 8'h01, 0,
                                      0, 0, 0, 0, 0, 0, 0, 0,
                                      0, 0, 0, 0, 0, 0, 0, 0};
//    logic [7:0] test_vector[0:31] = '{8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 
//                                      8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA,
//                                      8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA,
//                                      8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA, 8'hAA};
//    logic [7:0] test_vector[0:31] = '{8'hAA, 8'h55, 8'hFF, 8'h00, 8'hCC, 8'h33, 8'h0F, 8'hF0, 
//                                      8'hA5, 8'h5A, 8'h3C, 8'hC3, 8'h78, 8'h87, 8'hE1, 8'h1E,
//                                      8'h92, 8'h6D, 8'h4B, 8'hB4, 8'hF7, 8'h08, 8'hD3, 8'h2C,
//                                      8'h19, 8'hE6, 8'hAC, 8'h53, 8'h07, 8'hF8, 8'hB9, 8'h46};

logic rdy,data_in_val;

initial begin
  // Initialize signals
  clk = 0;
  reset_n = 0;
  data_in = 0;
  rdy = 0;

  // Apply reset
  #20 reset_n = 1;
  #100;
  //wait ((dc_fifo_I_s_tready == 1) && (dc_fifo_Q_s_tready == 1));
  rdy = 1;  
  @(posedge clk);

  // Open file for writing real IF data
  //file = $fopen("msk_real_output.txt", "w");
  // Feed binary test vector
  for (x = 0; x < 1000; x = x + 1) begin
    for (i = 0; i < 32; i = i + 1) begin
        // Send bits serially (each bit lasts 20 clock cycles, assuming 10 MHz symbol rate)
        for (int j = 0; j < 8; j = j + 1) begin
            data_in = test_vector[i][7 - j]; // MSB first
            data_in_val = 1;
            // Hold for 20 clock cycles
            @(posedge clk);
            data_in_val = 0;
            repeat (19) @(posedge clk); 
        end
    end
  end
  // Run for some extra cycles
  repeat (100) @(posedge clk);

end


endmodule
