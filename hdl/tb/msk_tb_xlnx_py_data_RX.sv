
// data generated in pythone and read into RX path


module msk_tb_py_data_RX;

  // Clock and reset
  logic clk=0;
  logic reset_n;

  // Binary data input
  logic data_in,demod_data;

  // I/Q signals
  logic signed [15:0] dc_I,dc_Q;
  logic signed [15:0] i_fir, q_fir;
  // Real-valued IF signal
  logic signed [15:0] adc_data;

  // Clock generation (200 MHz)
  always #2.5ns clk = ~clk; // 5 ns period (200 MHz)
  //always #625ps clk = ~clk; // 800 MHz

  initial begin
    // Initialize signals
    clk = 0;
    reset_n = 0;
    #20 reset_n = 1;

  end

//-------------------------------------------------------------------------------------------------
//
//-------------------------------------------------------------------------------------------------

  duc_ddc_top #(
    .FS(200e6)
  ) duc_ddc_top_inst (
    .clk      (clk      ),
    .reset    (~reset_n ),
    //DDC
    .adc_in   (adc_data),//dac_awgn ), // from ADC
    .I_out    (dc_I     ), // to demod
    .Q_out    (dc_Q     ), // to demod
    //DUC
    .I_in     (), // from modulator
    .Q_in     (), // from modulator
    .dac_out  ()  // to DAC
  );

  logic signed [31:0] fir_I_tdata, fir_Q_tdata;

  fir_lpf fir_lpf_dc_I (
    .aclk               (clk      ),// input wire aclk
    .s_axis_data_tvalid ('1       ),// input wire s_axis_data_tvalid
    .s_axis_data_tready (         ), // output wire s_axis_data_tready
    .s_axis_data_tdata  (dc_I     ),// input wire [15 : 0] s_axis_data_tdata
    .m_axis_data_tvalid (         ), // output wire m_axis_data_tvalid
    .m_axis_data_tdata  (fir_I_tdata)// output wire [31 : 0] m_axis_data_tdata
  );

  fir_lpf fir_lpf_dc_Q (
    .aclk               (clk      ),// input wire aclk
    .s_axis_data_tvalid ('1       ),// input wire s_axis_data_tvalid
    .s_axis_data_tready (         ), // output wire s_axis_data_tready
    .s_axis_data_tdata  (dc_Q     ),// input wire [15 : 0] s_axis_data_tdata
    .m_axis_data_tvalid (         ), // output wire m_axis_data_tvalid
    .m_axis_data_tdata  (fir_Q_tdata)// output wire [31 : 0] m_axis_data_tdata
  );

  assign i_fir = fir_I_tdata[30:15];
  assign q_fir = fir_Q_tdata[30:15];


  localparam int WIQ    = 16;
  localparam int WO     = 18;
  localparam int WERR   = 18;
  localparam int INT_W  = 5;
  localparam int FRAC_W = 27;

  logic signed  [WO-1:0]      i_sym, q_sym;
  logic signed  [WERR-1:0]    ted_err, lf_ctrl;
  logic         [INT_W-1:0]   phase_int;
  logic         [FRAC_W-1:0]  mu;


  gardner_ted_mdl_2 #(
    .OSF  (20),
    .WIQ  (WIQ),
    .WERR (WERR) 
  ) gardner_ted_inst (
    .clk          (clk          ),
    .reset_n      (reset_n      ),
    .i_in         (i_fir        ),
    .q_in         (q_fir        ),
    .sym_valid_i  (sym_val      ),
    .e_out_o      (      ),
    .e_valid_o    (  )
  );

  gardner_ted_mdl_3 #(
    .OSF  (20),
    .WIQ  (WIQ),
    .WERR (WERR) 
  ) gardner_ted_3_inst (
    .clk          (clk          ),
    .reset_n      (reset_n      ),
    .i_in         (i_fir        ),
    .q_in         (q_fir        ),
    .sym_valid_i  (sym_val      ),
    .e_out_o      (ted_err      ),
    .e_valid_o    (ted_err_val  )
  );


  pi_loop_filter_mdl_2 #(
    .WERR      (WERR),
    .KP_SHIFT  (7 ),
    .KI_SHIFT  (12),
    .ACC_WIDTH (24)
  ) pi_loop_filter_inst (
    .clk        (clk          ),
    .reset_n    (reset_n      ),
    .e_in_i     (ted_err      ),
    .e_valid_i  (ted_err_val  ),
    .ctrl_o     (lf_ctrl      )
  );

  phase_accum_mdl #(
    .OSF       (20),
    .CTRL_W    (WERR),
    .INT_W     (INT_W ),
    .FRAC_W    (FRAC_W)
  ) phase_accum_inst (
    .clk          (clk        ),
    .reset_n      (reset_n    ),
    .ctrl_i       (lf_ctrl    ),
    .sym_valid_o  (sym_val    ),
    .phase_int_o  (phase_int  ),
    .mu_o         (mu         )
  );

  polyphase_interp_mdl #(
    .OSF       (20),
    .TAPS_PPH  (INT_W ),
    .WIQ       (16),
    .WO        (WO)
  ) polyphase_interp_inst (
    .clk           (clk       ),
    .reset_n       (reset_n   ),
    .i_raw_i       (i_fir     ),
    .q_raw_i       (q_fir     ),
    .phase_int_i   (phase_int ),
    .mu_i          (mu        ),
    .sym_valid_i   (sym_val   ),
    .i_sym_o       (i_sym     ),
    .q_sym_o       (q_sym     ),
    .sym_valid_o   (sym_val_decoder)
  );


  msk_slicer_dec_mdl #(
    .IW (18)
  ) msk_slicer_dec_inst (
    .clk          (clk      ),
    .reset_n      (reset_n  ),
    .i_sym_i      (i_sym    ),
    .q_sym_i      (q_sym    ),
    .sym_valid_i  (sym_val_decoder),
    .data_o       (),
    .data_valid_o ()
  );





  msk_demod #(
      .FS(200.0e6)
  ) msk_demod_inst (
      .clk(clk),
      .reset_n(reset_n),
      .midpoint_adj(1),
      .i_in(i_fir),
      .q_in(q_fir),
      .data_out(demod_data)
  );

  msk_demod #(
      .FS(200.0e6)
  ) msk_demod_inst2 (
      .clk(clk),
      .reset_n(reset_n),
      .midpoint_adj(5),
      .i_in(i_fir),
      .q_in(q_fir),
      .data_out()
  );



  file_read_simple #(
    .DATA_WIDTH(16),
    .CLKLESS(0),
    .PERIOD_NS(),
    .DATA_FORMAT("dec"),
    //.FILE_NAME("/mnt/TDG_512/projects/2_zub_msk_udp_dma/sub/common/hdl/tb/adc_samples_TIMING_p30.txt")
    //.FILE_NAME("../../../../../sub/common/hdl/tb/adc_samples_TIMING_p30.txt")
    .FILE_DIR("sub/common/hdl/tb/"),
    .FILE_NAME("adc_0.txt")
  ) file_read_simple_inst (
    .clk(clk),
    .data_out(),
    .data_val()
  );

  file_read_simple #(
    .DATA_WIDTH(16),
    .CLKLESS(0),
    .PERIOD_NS(),
    .DATA_FORMAT("dec"),
    //.FILE_NAME("/mnt/TDG_512/projects/2_zub_msk_udp_dma/sub/common/hdl/tb/adc_samples.txt")
    //.FILE_NAME("../../../../../sub/common/hdl/tb/adc_0.txt")
    .FILE_DIR("sub/common/hdl/tb/"),
    .FILE_NAME("adc_Tp30_C40_Jp01.txt") // adc_0, adc_Tp30_C40_Jp01, 
  ) file_read_simple_inst2 (
    .clk(clk),
    .data_out(adc_data),
    .data_val()
  );


endmodule
