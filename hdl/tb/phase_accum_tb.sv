
// data generated in pythone and read into RX path


module msk_tb_py_data_RX;

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

//-------------------------------------------------------------------------------------------------
// adc_0, adc_Tp30, adc_Tp10, adc_Tp05, adc_Tp40, adc_Tp49
// adc_Tp30_C40_Jp01
//-------------------------------------------------------------------------------------------------

  file_read_simple #(
    .DATA_WIDTH(16),.CLKLESS(0),.PERIOD_NS(),.DATA_FORMAT("dec"),.FILE_DIR("sub/common/hdl/tb/data/"),
    .FILE_NAME("adc_2.dat")
  ) file_read_simple_inst0 (
    .rst(~reset_n),.clk(clk),
    .data_out(adc0),
    .data_val(adc0_val)
  );

//  file_read_simple #(
//    .DATA_WIDTH(16),.CLKLESS(0),.PERIOD_NS(),.DATA_FORMAT("dec"),.FILE_DIR("sub/common/hdl/tb/data/"),
//    .FILE_NAME("adc_Tp10.dat") 
//  ) file_read_simple_inst1 (
//    .rst(~reset_n),.clk(clk),
//    .data_out(adc1),
//    .data_val(adc1_val)
//  );

//-------------------------------------------------------------------------------------------------
//
//-------------------------------------------------------------------------------------------------


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

//  duc_ddc_lpf_top #(
//    .FS(200e6)
//  ) duc_ddc_top_inst1 (
//    .clk      (clk      ),
//    .rstn     (reset_n ),
//    //DDC
//    .adc_in   (adc1),//dac_awgn ), // from ADC
//    .I_out    (  ), // to demod
//    .Q_out    (  ), // to demod
//    //DUC
//    .I_in     (), // from modulator
//    .Q_in     (), // from modulator
//    .dac_out  ()  // to DAC
//  );


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
    .e_valid_o    (ek_val   )
  );


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
    .ctrl_o     (lf_ctrl      ),
    .ctrl_val_o (lf_ctrl_val  )
  );

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
    .ctrl_o     (      ),
    .ctrl_val_o (  )
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



  int cnt=0;
  logic [19:0] sr='0;
  logic cnt_stb='0, sym_val_dbg;

  always_ff @(posedge clk) begin
    if (iq_val) begin 
      cnt_stb <= '0;
      if (cnt == 19) begin 
        cnt <= 0;
        cnt_stb <= '1;
      end else cnt <= cnt + 1;
      sr <= {sr[18:0],cnt_stb};
    end 
  end
  int cnt_sel = 11;
  assign sym_val_dbg =  (cnt_sel == 0)  ? sr[0] :
                        (cnt_sel == 1)  ? sr[1] :
                        (cnt_sel == 3)  ? sr[3] :
                        (cnt_sel == 4)  ? sr[4] :
                        (cnt_sel == 5)  ? sr[5] :
                        (cnt_sel == 6)  ? sr[6] :
                        (cnt_sel == 7)  ? sr[7] :
                        (cnt_sel == 8)  ? sr[8] :
                        (cnt_sel == 9)  ? sr[9] :
                        (cnt_sel == 10) ? sr[10] :
                        (cnt_sel == 11) ? sr[11] :
                        (cnt_sel == 12) ? sr[12] :
                        (cnt_sel == 13) ? sr[13] :
                        (cnt_sel == 14) ? sr[14] :
                        (cnt_sel == 15) ? sr[15] :
                        (cnt_sel == 16) ? sr[16] :
                        (cnt_sel == 17) ? sr[17] :
                        (cnt_sel == 18) ? sr[18] :
                        (cnt_sel == 19) ? sr[19] : '0;



/*
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



//-------------------------------------------------------------------------------------------------
// old demod works
//-------------------------------------------------------------------------------------------------

  msk_demod #(
      .FS(200.0e6)
  ) msk_demod_inst (
      .clk(clk),
      .reset_n(reset_n),
      .midpoint_adj(1),
      .i_in(i_fir),
      .q_in(q_fir),
      .data_out()
  );
*/
  msk_demod #(
      .FS(200.0e6)
  ) msk_demod_inst2 (
      .clk(clk),
      .reset_n(reset_n),
      .midpoint_adj(1),
      .i_in(i_fir),
      .q_in(q_fir),
      .iq_val(iq_val),
      .data_out(demod_data)
  );





endmodule
