`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// data generated in pythone and read into RX path


module msk_tb_xlnx_RX;

  // Clock and reset
  logic clk=0;
  logic reset_n;

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

  localparam int FDW = 256;
  localparam logic [FDW-1:0] FIXED_DATA = 'h901000000033000000FFFFFFFF010000007700ffff00000001010000ffa50ffe;

//-------------------------------------------------------------------------------------------------
// adc_long
// 
// adc_0, adc_Tp30, adc_Tp10, adc_Tp05, adc_Tp40, adc_Tp49
// adc_Tp30_C40_Jp01
// adc_2, adc_long, adc_ones, adc_alternating, adc_zeros
// adc_2_alt, adc_3_alt, adc_4_alt, adc_5_alt, adc_6_alt, adc_7_alt, adc_4_alt_T0_C0_J000
// 
// adc_5alt_Tp10, adc_5_alt_T10_C0_J000, adc_5_alt_T30_C0_J000, adc_5_alt_T0_C10_J000
// adc_5_alt_T0_C30_J000, adc_5_alt_T0_C0_J001, adc_5_alt_T0_C0_J003, adc_5_alt_T0_C0_J005
// adc_5_alt_T41_C0_J000, adc_5_alt_T0_C100_J000
// adc_5_alt_T43_C100_J005, 
//
// adc_data_nominal, adc_data_F1000.0
//-------------------------------------------------------------------------------------------------
  logic signed [15:0] adc0;

  file_read_simple #(
    .DATA_WIDTH(16),.CLKLESS(0),.PERIOD_NS(),.DATA_FORMAT("dec"),.FILE_DIR("sim/data/"),
    .FILE_NAME("adc_data_nominal.dat") //adc_5_alt_T30_C0_J000
  ) file_read_simple (
    .rst(~reset_n),.clk(clk),
    .data_out(adc0),
    .data_val(adc0_val)
  );

//-------------------------------------------------------------------------------------------------
//
//-------------------------------------------------------------------------------------------------
  localparam IQW = 16;
  
  logic signed [IQW-1:0] i_fir, i_mf;
  logic signed [IQW-1:0] q_fir, q_mf;

// ddc_lpf_mdl #(
//   .IF(50e6 ),
//   .FS(200e6) 
// ) ddc_lpf_MDL (
//   .clk    (clk),
//   .rst    (rst),
//   .adc_in (adc0),
//   .adc_val(adc0_val),
//   .I_out  (),
//   .Q_out  (),
//   .iq_out_val()
// );

  duc_ddc_lpf_top #(
    .DUC_EN(0),
    .DDC_EN(1),
    .FS(200e6)
  ) duc_ddc_lpf_top (
    .clk      (clk),
    .rst      (rst),
    //DDC
    .adc_in   (adc0), // from ADC
    .adc_val  (adc0_val),
    .I_out    (i_fir), // to demod
    .Q_out    (q_fir), // to demod
    .IQ_val   (iq_val),
    //DUC
    .I_in     (), // from modulator
    .Q_in     (), // from modulator
    .dac_out  ()  // to DAC
  );


//  msk_mf #(
//    .WI (IQW), .WO (IQW)
//  ) msk_mf_MDL_I (
//    .clk      (clk),
//    .din      (i_fir),
//    .din_val  (iq_val),
//    .dout     (),//i_mf
//    .dout_val ()
//  );
//
//  msk_mf #(
//    .WI (IQW), .WO (IQW)
//  ) msk_mf_MDL_Q (
//    .clk      (clk),
//    .din      (q_fir),
//    .din_val  (iq_val),
//    .dout     (),//q_mf
//    .dout_val ()
//  );


/**** MOVED these MF IPs into duc_ddc_lpf_top ******/
//  logic signed [39:0] mf_fullI, mf_fullQ;
//  logic signed [15:0] mf_I, mf_Q;
//
//  fir_mf msk_mf_I (
//    .aclk(clk),                              // input wire aclk
//    .s_axis_data_tvalid(iq_val  ),  // input wire s_axis_data_tvalid
//    .s_axis_data_tready(        ),  // output wire s_axis_data_tready
//    .s_axis_data_tdata(i_fir    ),    // input wire [15 : 0] s_axis_data_tdata
//    .m_axis_data_tvalid(mf_val  ),  // output wire m_axis_data_tvalid
//    .m_axis_data_tdata(mf_fullI )    // output wire [39 : 0] m_axis_data_tdata
//  );
//
//  fir_mf msk_mf_Q (
//    .aclk(clk),                              // input wire aclk
//    .s_axis_data_tvalid(iq_val  ),  // input wire s_axis_data_tvalid
//    .s_axis_data_tready(        ),  // output wire s_axis_data_tready
//    .s_axis_data_tdata(q_fir    ),    // input wire [15 : 0] s_axis_data_tdata
//    .m_axis_data_tvalid(        ),  // output wire m_axis_data_tvalid
//    .m_axis_data_tdata(mf_fullQ )    // output wire [39 : 0] m_axis_data_tdata
//  );
//
//  assign mf_I = mf_fullI[34:19];
//  assign mf_Q = mf_fullQ[34:19];
/*******************************************************/



  localparam int WIQ    = IQW;
  localparam int WO     = 18;
  localparam int WERR   = 18;
  localparam int INT_W  = 5;
  localparam int FRAC_W = 27;

  logic signed  [WIQ-1:0]     i_raw_delay, q_raw_delay;
  logic signed  [WO-1:0]      i_sym, q_sym;
  logic signed  [WERR-1:0]    ek, lf_ctrl;
  logic         [INT_W-1:0]   phase_int;
  logic         [FRAC_W-1:0]  mu;


// gardner_ted_mdl #(
//   .RAW_DLY  (5), // adjusted here to 5 to stabilize coarse CFO. need repeat data sequence of "0011" / "00001111" 
//   .OSF      (20),
//   .WI       (16),
//   .WO       (18)
// ) gardner_ted_MDL (
//   .clk          (clk          ),
//   .reset_n      (reset_n      ),
//   .i_in         (mf_I         ),
//   .q_in         (mf_Q         ),
//   .iq_val       (mf_val       ),
//   .sym_valid_i  (sym_val      ),
//   .e_out_o      (),
//   .e_valid_o    (),
//   .i_raw_delay_o(),
//   .q_raw_delay_o()
// );

  gardner_ted #(
    .RAW_DLY  (5), // adjusted here to 5 to stabilize coarse CFO. need repeat data sequence of "0011" / "00001111" 
    .OSF      (20),
    .WI       (16),
    .WO       (18)
  ) gardner_ted_SYN (
    .clk          (clk          ),
    .reset_n      (reset_n      ),
    .i_in         (i_fir        ),//mf_I         ),
    .q_in         (q_fir        ),//mf_Q         ),
    .iq_val       (iq_val       ),//mf_val       ),
    .sym_valid_i  (sym_val      ),
    .e_out_o      (ek           ),
    .e_valid_o    (ek_val       ),
    .i_raw_delay_o(i_raw_delay  ),
    .q_raw_delay_o(q_raw_delay  )
  );


//  pi_loop_filter_mdl #(
//    .WERR      (WERR),
//    .ACC_WIDTH (24)
//  ) pi_loop_filter_MDL (
//    .clk        (clk          ),
//    .reset_n    (reset_n      ),
//    .e_in_i     (ek           ),
//    .e_valid_i  (ek_val       ),
//    .ctrl_o     (      ),
//    .ctrl_val_o (  )
//  );


  pi_loop_filter #(
    .KP_SHIFT  (7 ),
    .KI_SHIFT  (11),
    .WERR      (WERR),
    .ACC_WIDTH (24)
  ) pi_loop_filter_SYN (
    .clk        (clk          ),
    .reset_n    (reset_n      ),
    .e_in_i     (ek           ),
    .e_valid_i  (ek_val       ),
    .ctrl_o     (lf_ctrl      ),
    .ctrl_val_o (lf_ctrl_val  )
  );


//  phase_accum_mdl #(
//    .OSF       (20),
//    .CTRL_W    (WERR),
//    .INT_W     (INT_W ),
//    .FRAC_W    (FRAC_W)
//  ) phase_accum_MDL (
//    .clk          (clk        ),
//    .reset_n      (reset_n    ),
//    .ctrl_i       (lf_ctrl    ),
//    .ctrl_val_i   (lf_ctrl_val),
//    .sym_valid_o  (  ),
//    .phase_int_o  (  ),
//    .mu_o         (  )
//  );

  phase_accum #(
    .OSF       (20),
    .CTRL_W    (WERR),
    .INT_W     (INT_W ),
    .FRAC_W    (FRAC_W)
  ) phase_accum_SYN (
    .clk          (clk        ),
    .reset_n      (reset_n    ),
    .ctrl_i       (lf_ctrl    ),
    .ctrl_val_i   (lf_ctrl_val),
    .sym_valid_o  (sym_val    ),
    .phase_int_o  (phase_int  ),
    .mu_o         (mu         ),
    .phase_val_o  (phase_val  )
  );


//-------------------------------------------------------------------------------------------------
// new interp mdl
//-------------------------------------------------------------------------------------------------
  localparam PIW = 16;
  logic signed [PIW-1:0] i_sym_interp, q_sym_interp;

//  polyphase_interp_mdl #(
//    .OSF       (20),
//    .TAPS_PPH  (INT_W ),
//    .WIQ       (WIQ),
//    .WO        (PIW)
//  ) polyphase_interp_MDL (
//    .clk          (clk            ),
//    .rst          (rst            ),
//    .i_raw_i      (i_raw_delay    ),
//    .q_raw_i      (q_raw_delay    ),
//    .iq_raw_val_i (iq_val         ), 
//    .phase_int_i  (phase_int      ),
//    .mu_i         (mu             ),
//    .phase_val_i  (phase_val      ),
//    .sym_valid_i  (sym_val        ),
//    .i_sym_o      (),
//    .q_sym_o      (),
//    .sym_valid_o  ()
//  );

  polyphase_interp #(
    .OSF       (20),
    .TAPS_PPH  (INT_W ),
    .WIQ       (WIQ),
    .WO        (PIW)
  ) polyphase_interp_SYN (
    .clk          (clk            ),
    .rst          (rst            ),
    .i_raw_i      (i_raw_delay    ),
    .q_raw_i      (q_raw_delay    ),
    .iq_raw_val_i (iq_val         ), 
    .phase_int_i  (phase_int      ),
    .mu_i         (mu             ),
    .phase_val_i  (phase_val      ),
    .sym_valid_i  (sym_val        ),
    .i_sym_o      (i_sym_interp   ),
    .q_sym_o      (q_sym_interp   ),
    .sym_valid_o  (sym_val_interp )
  );


//  msk_slicer_dec_mdl #(
//    .IW (PIW)
//  ) msk_slicer_dec_MDL_TIMING (
//    .clk          (clk          ),
//    .reset_n      (reset_n      ),
//    .i_sym_i      (i_sym_interp ),
//    .q_sym_i      (q_sym_interp ),
//    .sym_valid_i  (sym_val_interp  ),
//    .data_o       (data_TIMING     ),
//    .data_valid_o (data_val_TIMING )
//  );
//
  localparam shifterWid = 128;
//
//  shifter_viewer # (
//    .FDW(FDW),
//    .FIXED_DATA(FIXED_DATA),
//    .WIDTH(shifterWid)
//  ) shifter_viewer_TIMING (
//    .clk        (clk),
//    .rst        (!reset_n),
//    .data_i     (data_TIMING),
//    .data_val_i (data_val_TIMING)
//  );


//-------------------------------------------------------------------------------------------------
// carrier recovery
//-------------------------------------------------------------------------------------------------
  logic cfo_en;

//  variable_strobe # (.PTR(2)) 
//  variable_strobe_inst (
//    .clk(clk),.rst(rst),
//    .en_i('1),
//    .stb_o(sym_val_dbg));


  coarse_cfo_mdl coarse_cfo_MDL (
    .clk        (clk              ),
    .rst_n      (reset_n          ),
    .enable     (cfo_en           ), // high during acquisition
    .vld_in     (sym_val_interp   ), // one strobe per symbol
    .i_in       (i_sym_interp     ), // timing‑loop I sample
    .q_in       (q_sym_interp     ), // timing‑loop Q sample
    .freq_word  (), // coarse word for NCO
    .done       ()  // 1‑clk pulse when estimate valid
  );

  initial begin 
    cfo_en = '0;
    #400ns
    cfo_en = '1;
  end


  localparam DIW = 16;
  localparam DDSW = 16;
  localparam PW = 32;
 
  logic signed [DIW-1:0] derot_i, derot_q;
  logic signed [DDSW-1:0] dds_sin, dds_cos;


// derotator_mdl #(
//   .WIDTH        (DIW),
//   .DDS_WIDTH    (DDSW),
//   .PHASE_WIDTH  (PW)
// ) derotator_MDL (
//   .clk            (clk),
//   .rst            (rst),            
//   .sym_valid_in   (sym_val_interp && cfo_en), 
//   .din_i          (i_sym_interp),
//   .din_q          (q_sym_interp),
//   .cos_in         (dds_cos),
//   .sin_in         (dds_sin),
//   .sym_valid_out  (),  
//   .dout_i         (),
//   .dout_q         ()
// );

  derotator #(
    .WIDTH        (DIW),
    .DDS_WIDTH    (DDSW),
    .PHASE_WIDTH  (PW)
  ) derotator_SYN (
    .clk            (clk),
    .rst            (rst),            
    .sym_valid_in   (sym_val_interp && cfo_en), 
    .din_i          (i_sym_interp ),
    .din_q          (q_sym_interp ),
    .cos_in         (dds_cos      ),
    .sin_in         (dds_sin      ),
    .sym_valid_out  (derot_val    ),  
    .dout_i         (derot_i      ),
    .dout_q         (derot_q      )
  );

  localparam EW = 24;
  logic signed [EW-1:0] pdet_err;

//  phase_detector_mdl #(
//    .IW (DIW), 
//    .EW (EW)  
//  ) phase_detector_MDL (
//    .clk        (clk),
//    .rst        (rst),
//    .sym_valid  (derot_val && cfo_en),
//    .din_i      (derot_i),
//    .din_q      (derot_q),
//    .err_valid  (),
//    .phase_err  ()
//  );

  phase_detector #(
    .IW (DIW), 
    .EW (EW)  
  ) phase_detector_SYN (
    .clk        (clk),
    .rst        (rst),
    .sym_valid  (derot_val && cfo_en),
    .din_i      (derot_i),
    .din_q      (derot_q),
    .err_valid  (pdet_err_val),
    .phase_err  (pdet_err)
  );

  logic signed [PW-1:0] freq_word;

//  loop_filter_cfo_mdl #(
//    .ERR_WIDTH      (EW), 
//    .PHASE_WIDTH    (PW), 
//    .KP             (1.2e-6), 
//    .KI             (5.0e-8)  
//  ) loop_filter_cfo_MDL (
//    .clk            (clk),
//    .rst            (rst),
//    .err_valid_i    (pdet_err_val),   
//    .phase_err_i    (pdet_err),   // phase detect
//    .freq_valid_o   (),   
//    .freq_word_o    ()    
//  );


  loop_filter_cfo #(
    .ERR_WIDTH   (EW ), 
    .PHASE_WIDTH (PW ), 
    .KP_SHIFT    (22 ), 
    .KI_SHIFT    (22 ),
    .KP_COEFF    (322), 
    .KI_COEFF    (55 )  
  ) loop_filter_cfo_SYN (
    .clk          (clk),
    .rst          (rst),
    .err_valid_i  (pdet_err_val),
    .phase_err_i  (pdet_err),
    .freq_valid_o (freq_word_val),
    .freq_word_o  (freq_word    )
  );



//  nco_dds_mdl #(
//    .PHASE_WIDTH  (PW),
//    .AMP_WIDTH    (DDSW) 
//  ) nco_dds_MDL (
//    .clk          (clk),
//    .rst          (rst),
//    .freq_word_i  (freq_word),   // from loop filter
//    .phase_word_o (),   // n/c for debug/view
//    .cos_out      (),// do derotator
//    .sin_out      ()    
//  );

  nco_dds #(
    .PHASE_WIDTH  (32),
    .AMP_WIDTH    (16) 
  ) nco_dds (
    .clk              (clk),
    .rst              (rst),
    .freq_word_i      (freq_word), 
    .freq_word_val_i  (freq_word_val),
    .phase_word_o     (),   
    .cos_out          (dds_cos),   
    .sin_out          (dds_sin)    
  );


//-------------------------------------------------------------------------------------------------
// carrier recovery
//-------------------------------------------------------------------------------------------------


  msk_slicer_dec_mdl #(
    .IW (PIW)
  ) msk_slicer_dec_MDL_CFO(
    .clk          (clk          ),
    .reset_n      (reset_n      ),
    .i_sym_i      (derot_i      ),
    .q_sym_i      (derot_q      ),
    .sym_valid_i  (derot_val    ),
    .data_o       (data_CFO     ),
    .data_valid_o (data_val_CFO )
  );

//  localparam int FDW = 256;
//  localparam logic [FDW-1:0] FIXED_DATA = 'h901000000033000000FFFFFFFF010000007700ffff00000001010000ffa50ffe;

  shifter_viewer # (
    .FDW(FDW),
    .FIXED_DATA(FIXED_DATA),
    .WIDTH(shifterWid)
  ) shifter_viewer_CFO (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (data_CFO),
    .data_val_i (data_val_CFO)
  );


  msk_slicer_dec #(
    .IW (PIW)
  ) msk_slicer_dec_SYN(
    .clk          (clk          ),
    .reset_n      (reset_n      ),
    .i_sym_i      (derot_i      ),
    .q_sym_i      (derot_q      ),
    .sym_valid_i  (derot_val    ),
    .data_o       (data_SYN     ),
    .data_valid_o (data_val_SYN )
  );

  shifter_viewer # (
    .FDW(FDW),
    .FIXED_DATA(FIXED_DATA),
    .WIDTH(shifterWid)
  ) shifter_viewer_SYN (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (data_SYN),
    .data_val_i (data_val_SYN)
  );


//-------------------------------------------------------------------------------------------------
// debug
//-------------------------------------------------------------------------------------------------
//  logic spy_match,spy_match2;
//
//  always_ff @( posedge clk ) begin
//    //if ((msk_tb_xlnx_RX.gardner_ted_MDL.mId == msk_tb_xlnx_RX.gardner_ted_SYN.dsp_I_prod) && (msk_tb_xlnx_RX.gardner_ted_MDL.mQd == msk_tb_xlnx_RX.gardner_ted_SYN.dsp_Q_prod))
//    //if (msk_tb_xlnx_RX.gardner_ted_MDL.err_long2 == msk_tb_xlnx_RX.gardner_ted_SYN.iq_sum)
//    if (msk_tb_xlnx_RX.gardner_ted_MDL.err_long3 == msk_tb_xlnx_RX.gardner_ted_SYN.err_long)
//      spy_match = '1;
//    else spy_match = '0;
//    if (msk_tb_xlnx_RX.gardner_ted_MDL.err3 == msk_tb_xlnx_RX.gardner_ted_SYN.err)
//      spy_match2 = '1;
//    else spy_match2 = '0;
//  end


endmodule

//  9010_0000_0033_0000_00FF_FFFF_FF01_0000_0077_00ff_ff00_0000_0101_0000_ffa5_0ffe
//  901000000033000000FFFFFFFF010000007700ffff00000001010000ffa50ffe
