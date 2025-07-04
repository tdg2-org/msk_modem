
// data generated in pythone and read into RX path


module gardner_ted_tb;

  logic clk=0;
  logic reset_n;

  // Clock generation (200 MHz)
  always #2.5ns clk = ~clk; // 5 ns period (200 MHz)

  initial begin
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


//-------------------------------------------------------------------------------------------------
// sym_val fixed
//-------------------------------------------------------------------------------------------------

  int cnt_sel = 11; // use to fix position, 20samples/symbol

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







endmodule
