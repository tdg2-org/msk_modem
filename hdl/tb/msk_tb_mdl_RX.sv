`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// data generated in pythone and read into RX path


module msk_tb_mdl_RX;

  // Clock and reset
  logic clk=0;
  logic reset_n;

  // Binary data input
  logic demod_data;

  // I/Q signals
  logic signed [15:0] i_fir, i_fir1;
  logic signed [15:0] q_fir, q_fir1;
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
// adc_long
// 
// adc_0, adc_Tp30, adc_Tp10, adc_Tp05, adc_Tp40, adc_Tp49
// adc_Tp30_C40_Jp01
// adc_2, adc_long, adc_ones, adc_alternating, adc_zeros
// adc_2_alt, adc_3_alt, adc_4_alt, adc_5_alt, adc_6_alt, adc_7_alt, 
// 
// adc_5alt_Tp10, adc_5_alt_T10_C0_J000, adc_5_alt_T30_C0_J000, adc_5_alt_T0_C10_J000
// adc_5_alt_T0_C30_J000, adc_5_alt_T0_C0_J001, adc_5_alt_T0_C0_J003, adc_5_alt_T0_C0_J005
// adc_5_alt_T41_C0_J000, adc_5_alt_T0_C100_J000
// adc_5_alt_T43_C100_J005, 
//-------------------------------------------------------------------------------------------------

  file_read_simple #(
    .DATA_WIDTH(16),.CLKLESS(0),.PERIOD_NS(),.DATA_FORMAT("dec"),.FILE_DIR("sub/msk_modem/sim/data/"),
    .FILE_NAME("adc_long.dat") //adc_5_alt_T30_C0_J000
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
    .I_out  (i_fir),
    .Q_out  (q_fir),
    .iq_out_val(iq_val)
  );

  rrc_mf_mdl  rrc_mf_mdl_inst (
    .clk      (clk    ),
    .rst      (rst    ),
    .i_in     (i_fir  ),
    .q_in     (q_fir  ),
    .iq_val_i (iq_val ),
    .i_out    (),
    .q_out    (),
    .iq_val_o ()
  );

  rrc_mf_mdl_0  mf0 (
    .clk      (clk    ),
    .rst      (rst    ),
    .i_in     (i_fir  ),
    .q_in     (q_fir  ),
    .iq_val_i (iq_val ),
    .i_out    (),
    .q_out    (),
    .iq_val_o ()
  );


  localparam int WIQ    = 16;
  localparam int WO     = 18;
  localparam int WERR   = 18;
  localparam int INT_W  = 5;
  localparam int FRAC_W = 27;

  logic signed  [WIQ-1:0]     i_raw_delay, q_raw_delay;
  logic signed  [WO-1:0]      i_sym, q_sym;
  logic signed  [WERR-1:0]    ek, lf_ctrl;
  logic         [INT_W-1:0]   phase_int;
  logic         [FRAC_W-1:0]  mu;


  gardner_ted_mdl #(
    .OSF  (20),
    .WI   (WIQ),
    .WO   (WERR) 
  ) gardner_ted_inst (
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

  pi_loop_filter_mdl #(
    .WERR      (WERR),
//    .KP_SHIFT  (7 ),
//    .KI_SHIFT  (12),
    .ACC_WIDTH (24)
  ) pi_loop_filter_inst (
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
// new interp mdl
//-------------------------------------------------------------------------------------------------
  logic signed [34:0] i_fir_NEW, q_fir_NEW;

  polyphase_interp_mdl #(
    .OSF       (20),
    .TAPS_PPH  (INT_W ),
    .WIQ       (WIQ),
    .WO        (35)
  ) polyphase_interp_NEW (
    .clk          (clk        ),
    .rst          (rst        ),
    .i_raw_i      (i_raw_delay),
    .q_raw_i      (q_raw_delay),
    .iq_raw_val_i (iq_val     ), 
    .phase_int_i  (phase_int  ),
    .mu_i         (mu         ),
    .sym_valid_i  (sym_val    ),
    .i_sym_o      (i_fir_NEW  ),
    .q_sym_o      (q_fir_NEW  ),
    .sym_valid_o  (sym_val_NEW)
  );

  msk_slicer_dec_mdl #(
    .IW (35)
  ) msk_slicer_dec_NEW (
    .clk          (clk          ),
    .reset_n      (reset_n      ),
    .i_sym_i      (i_fir_NEW    ),
    .q_sym_i      (q_fir_NEW    ),
    .sym_valid_i  (sym_val_NEW  ),
    .data_o       (data_NEW     ),
    .data_valid_o (data_val_NEW )
  );

  localparam shifterWid = 128;

  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_NEW (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (data_NEW),
    .data_val_i (data_val_NEW)
  );


//-------------------------------------------------------------------------------------------------
// old interp mdl
//-------------------------------------------------------------------------------------------------
/*
  polyphase_interp_mdl_OLD #(
    .OSF       (20),
    .TAPS_PPH  (INT_W ),
    .WIQ       (WIQ),
    .WO        (WO)
  ) polyphase_interp_inst_OLD (
    .clk          (clk        ),
    .reset_n      (reset_n    ),
    .i_raw_i      (i_fir      ),
    .q_raw_i      (q_fir      ),
    .iq_raw_val_i (iq_val     ), 
    .phase_int_i  (phase_int  ),
    .mu_i         (mu         ),
    .sym_valid_i  (sym_val    ),
    .i_sym_o      (i_sym      ),
    .q_sym_o      (q_sym      ),
    .sym_valid_o  (sym_val_decoder)
  );

  msk_slicer_dec_mdl #(
    .IW (WO)
  ) msk_slicer_dec_OLD (
    .clk          (clk      ),
    .reset_n      (reset_n  ),
    .i_sym_i      (i_sym    ),
    .q_sym_i      (q_sym    ),
    .sym_valid_i  (sym_val_decoder),
    .data_o       (data_OLD),
    .data_valid_o (data_val_OLD)
  );


  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_OLD (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (data_OLD),
    .data_val_i (data_val_OLD)
  );
*/
//-------------------------------------------------------------------------------------------------
// OVERSAMP BYPASS old demod works
// bypass loop
//-------------------------------------------------------------------------------------------------

//  msk_demod #(
//      .FS(200.0e6)
//  ) msk_demod_OVERSAMP (
//      .clk(clk),
//      .reset_n(reset_n),
//      .midpoint_adj(1),
//      .i_in(i_fir), // bypass loop
//      .q_in(q_fir),
//      .iq_val(iq_val),
//      .data_out(data_OVERSAMP),
//      .data_val(data_val_OVERSAMP)
//  );

  msk_demod_mdl #(
    .FS     (200.0e6),  
    .F_SYM  (10.0e6 )   
  )msk_demod_mdl_OVERSAMP(
    .clk          (clk),
    .reset_n      (reset_n),
    .midpoint_adj (1),
    .i_in         (i_fir),
    .q_in         (q_fir),
    .iq_val       (iq_val),
    .data_out     (data_OVERSAMP),
    .data_val     (data_val_OVERSAMP)
  );


  shifter_viewer # (
    .WIDTH(shifterWid)
  ) shifter_viewer_OVERSAMP (
    .clk        (clk),
    .rst        (!reset_n),
    .data_i     (data_OVERSAMP),
    .data_val_i (data_val_OVERSAMP)
  );

endmodule

//  9010_0000_0033_0000_00FF_FFFF_FF01_0000_0077_00ff_ff00_0000_0101_0000_ffa5_0ffe
