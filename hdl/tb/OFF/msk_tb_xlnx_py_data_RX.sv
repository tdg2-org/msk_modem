
// data generated in pythone and read into RX path


module msk_tb_py_data_RX;

  // Clock and reset
  logic clk=0;
  logic reset_n;

  // I/Q signals
  logic signed [15:0] i_fir, i_fir1, i_raw_delay;
  logic signed [15:0] q_fir, q_fir1, q_raw_delay;
  // Real-valued IF signal
  logic signed [15:0] adc0, adc1;

  // Clock generation (200 MHz)
  always #2.5ns clk = ~clk; // 5 ns period (200 MHz)
  //always #625ps clk = ~clk; // 800 MHz

  initial begin
    // Initialize signals
    clk = 0;
    reset_n = 0;
    #20 reset_n = 1;

  end
  logic rst;
  assign rst = !reset_n;

//-------------------------------------------------------------------------------------------------
// adc_0, adc_Tp30, adc_Tp10, adc_Tp05, adc_Tp40, adc_Tp49
// adc_Tp30_C40_Jp01
// adc_long
//-------------------------------------------------------------------------------------------------

  file_read_simple #(
    .DATA_WIDTH(16),.CLKLESS(0),.PERIOD_NS(),.DATA_FORMAT("dec"),.FILE_DIR("sub/common/hdl/tb/data/"),
    .FILE_NAME("adc_long.dat")
  ) file_read_simple_inst0 (
    .rst(~reset_n),.clk(clk),
    .data_out(adc0),
    .data_val(adc0_val)
  );


//-------------------------------------------------------------------------------------------------
//
//-------------------------------------------------------------------------------------------------

  ddc_lpf_mdl #(
    .IF(50e6 ),
    .FS(200e6) 
  ) ddc_mdl_inst (
    .clk    (clk),
    .rst    (rst),
    .adc_in (adc0),
    .adc_val(adc0_val),
    .I_out  (),
    .Q_out  (),
    .iq_out_val()
  );



  duc_ddc_lpf_top #(
    .DUC_EN(0),
    .DDC_EN(1),
    .FS(200e6)
  ) duc_ddc_top_inst0 (
    .clk      (clk      ),
    .rstn     (reset_n  ),
    //DDC
    .adc_in   (adc0     ),//dac_awgn ), // from ADC
    .adc_val  (adc0_val ),
    .I_out    (i_fir    ), // to demod
    .Q_out    (q_fir    ), // to demod
    .IQ_val   (iq_val   ),
    //DUC
    .I_in     (), // from modulator
    .Q_in     (), // from modulator
    .dac_out  ()  // to DAC
  );



  localparam int WIQ    = 16;
  localparam int WO     = 18;
  localparam int WERR   = 18;
  localparam int INT_W  = 5;
  localparam int FRAC_W = 27;

  logic signed  [WO-1:0]      i_sym, q_sym;
  logic signed  [WERR-1:0]    ek, lf_ctrl;
  logic         [INT_W-1:0]   phase_int;
  logic         [FRAC_W-1:0]  mu;


  gardner_ted_mdl_3 #(
    .OSF  (20),
    .WIQ  (WIQ),
    .WERR (WERR) 
  ) gardner_ted_3_inst (
    .clk          (clk      ),
    .reset_n      (reset_n  ),
    .i_in         (i_fir    ),
    .q_in         (q_fir    ),
    .iq_val       (iq_val   ),
    .sym_valid_i  (sym_val  ),
    .e_out_o      (ek       ),
    .e_valid_o    (ek_val   ),
    .i_raw_delay_o(i_raw_delay),
    .q_raw_delay_o(q_raw_delay)
  );

/*
  pi_loop_filter_mdl_2 #(
    .WERR      (WERR),
    .KP_SHIFT  (7 ),
    .KI_SHIFT  (12),
    .ACC_WIDTH (24)
  ) pi_loop_filter_inst (
    .clk        (clk          ),
    .reset_n    (reset_n      ),
    .e_in_i     (ek           ),
    .e_valid_i  (ek_val       ),
    .ctrl_o     (  ),
    .ctrl_val_o (  )
  );
*/

  pi_loop_filter_mdl_3 #(
    .WERR      (WERR),
    .KP_SHIFT  (7 ),
    .KI_SHIFT  (12),
    .ACC_WIDTH (24)
  ) pi_loop_filter_inst3 (
    .clk        (clk          ),
    .reset_n    (reset_n      ),
    .e_in_i     (ek           ),
    .e_valid_i  (ek_val       ),
    .ctrl_o     (lf_ctrl      ),
    .ctrl_val_o (lf_ctrl_val  )
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
    .ctrl_val_i   (lf_ctrl_val),
    .sym_valid_o  (sym_val    ),
    .phase_int_o  (phase_int  ),
    .mu_o         (mu         )
  );





//-------------------------------------------------------------------------------------------------
// debug ted
//-------------------------------------------------------------------------------------------------

  polyphase_interp_mdl #(
    .OSF       (20),
    .TAPS_PPH  (INT_W ),
    .WIQ       (16),
    .WO        (WO)
  ) polyphase_interp_inst (
    .clk          (clk        ),
    .reset_n      (reset_n    ),
    .i_raw_i      (i_raw_delay),
    .q_raw_i      (q_raw_delay),
    .iq_raw_val_i (iq_val     ), 
    .phase_int_i  (phase_int  ),
    .mu_i         (mu         ),
    .sym_valid_i  (sym_val    ),
    .i_sym_o      (i_sym      ),
    .q_sym_o      (q_sym      ),
    .sym_valid_o  (sym_val_decoder)
  );

  logic slicer_data, slicer_val;
  logic [11:0] sym_var_sr = '0;

  always_ff @(posedge clk) sym_var_sr <= {sym_var_sr[10:0],sym_val_decoder};
  

  msk_slicer_dec_mdl #(
    .IW (18)
  ) msk_slicer_dec_inst (
    .clk          (clk      ),
    .reset_n      (reset_n  ),
    .i_sym_i      (i_sym    ),
    .q_sym_i      (q_sym    ),
    .sym_valid_i  (sym_val_decoder),
    .data_o       (slicer_data),
    .data_valid_o (slicer_val)
  );

  localparam shifterWid = 128;

  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_inst (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (slicer_data),
    .data_val_i (slicer_val)
  );



//-------------------------------------------------------------------------------------------------
// OVERSAMP BYPASS old demod works
// bypass loop
//-------------------------------------------------------------------------------------------------

  msk_demod #(
      .FS(200.0e6)
  ) msk_demod_OVERSAMP (
      .clk(clk),
      .reset_n(reset_n),
      .midpoint_adj(1),
      .i_in(i_fir), // bypass loop
      .q_in(q_fir),
      .iq_val(iq_val),
      .data_out(data_OVERSAMP),
      .data_val(data_val_OVERSAMP)
  );

  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_OVERSAMP (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (data_OVERSAMP),
    .data_val_i (data_val_OVERSAMP)
  );

  msk_demod_mdl #(
    .FS     (200.0e6),  
    .F_SYM  (10.0e6 )   
  )msk_demod_MDL(
    .clk          (clk),
    .reset_n      (reset_n),
    .midpoint_adj (1),
    .i_in         (i_fir),
    .q_in         (q_fir),
    .iq_val       (iq_val),
    .data_out     (data_MDL),
    .data_val     (data_val_MDL)
  );


  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_MDL (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (data_MDL),
    .data_val_i (data_val_MDL)
  );

//  9010_0000_0033_0000_00FF_FFFF_FF01_0000_0077_00ff_ff00_0000_0101_0000_ffa5_0ffe


//-------------------------------------------------------------------------------------------------
// fixed sym val
// bypass loop
//-------------------------------------------------------------------------------------------------

  variable_strobe # (.PTR(11)) 
  variable_strobe_FIXED_SYM_VALID (
    .clk(clk),.rst(rst),
    .en_i(iq_val),
    .stb_o(sym_val_dbg));

  msk_demod2 #(
      .FS(200.0e6)
  ) msk_demod2_FIXED_SYM_VALID (
      .clk(clk),
      .reset_n(reset_n),
      .sym_val_i(sym_val_dbg),
      .i_in(i_fir), // bypass loop
      .q_in(q_fir),
      .data_out(data_FIXED_SYM_VALID),
      .data_val(data_val_FIXED_SYM_VALID)
  );

  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_FIXED_SYM_VALID (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (data_FIXED_SYM_VALID),
    .data_val_i (data_val_FIXED_SYM_VALID)
  );


//-------------------------------------------------------------------------------------------------
// fixed sym val
// loop from INTERP_FIXED 
//-------------------------------------------------------------------------------------------------

  variable_strobe # (.PTR(11)) 
  variable_strobe_INTERP_FIXED(
    .clk(clk),.rst(rst),
    .en_i(iq_val),
    .stb_o(sym_val_INTERP_FIXED));


  msk_slicer_dec_mdl #(
    .IW (18)
  ) msk_slicer_dec_INTERP_FIXED (
    .clk          (clk      ),
    .reset_n      (reset_n  ),
    .i_sym_i      (i_sym    ),
    .q_sym_i      (q_sym    ),
    .sym_valid_i  (sym_val_INTERP_FIXED),
    .data_o       (data_INTERP_FIXED),
    .data_valid_o (dval_INTERP_FIXED)
  );


  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_INTERP_FIXED(
    .clk        (clk),
    .rst        (rst),
    .data_i     (data_INTERP_FIXED),
    .data_val_i (dval_INTERP_FIXED)
  );

//-------------------------------------------------------------------------------------------------
// fixed sym val
// bypass loop, try slicer
// BYPASS_FIXED_SLICER
//-------------------------------------------------------------------------------------------------

  variable_strobe # (.PTR(11)) 
  variable_strobe_BYPASS_FIXED_SLICER(
    .clk(clk),.rst(rst),
    .en_i(iq_val),
    .stb_o(sym_val_BYPASS_FIXED_SLICER));


  msk_slicer_dec_mdl #(
    .IW (16)
  ) msk_slicer_dec_BYPASS_FIXED_SLICER (
    .clk          (clk      ),
    .reset_n      (reset_n  ),
    .i_sym_i      (i_fir    ),
    .q_sym_i      (q_fir    ),
    .sym_valid_i  (sym_val_BYPASS_FIXED_SLICER),
    .data_o       (data_BYPASS_FIXED_SLICER),
    .data_valid_o (dval_BYPASS_FIXED_SLICER)
  );


  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_BYPASS_FIXED_SLICER(
    .clk        (clk),
    .rst        (rst),
    .data_i     (data_BYPASS_FIXED_SLICER),
    .data_val_i (dval_BYPASS_FIXED_SLICER)
  );


endmodule
