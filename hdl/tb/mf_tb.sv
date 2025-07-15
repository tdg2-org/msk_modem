`timescale 1ns / 1ps  // <time_unit>/<time_precision>

// data generated in pythone and read into RX path


module mf_tb;

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
//
//-------------------------------------------------------------------------------------------------
  logic signed [15:0] di, dq;
  logic iq_val;

  rrc_mf_mdl_0  mf0 (
    .clk      (clk    ),
    .rst      (rst    ),
    .i_in     (di  ),
    .q_in     (dq  ),
    .iq_val_i (iq_val ),
    .i_out    (),
    .q_out    (),
    .iq_val_o ()
  );

  rrc_mf_mdl  mf (
    .clk      (clk    ),
    .rst      (rst    ),
    .i_in     (di  ),
    .q_in     (dq  ),
    .iq_val_i (iq_val ),
    .i_out    (),
    .q_out    (),
    .iq_val_o ()
  );


  msk_mf0 msk_mf0_inst (
    .clk (clk),
    .din (di),
    .dout()
  );

  msk_mf msk_mf_inst (
    .clk      (clk),
    .din_val  (iq_val),
    .din      (di),
    .dout     (),
    .dout_val ()
  );


//-------------------------------------------------------------------------------------------------
//
//-------------------------------------------------------------------------------------------------
  initial begin 
    di = 0;
    dq = 0;
    wait(rst == 0);
    #100ns;
    @(posedge clk);
    iq_val = 1;
    #200ns;
    @(posedge clk);
    di = 32767;
    dq = 32767;
    @(posedge clk);
    di = 0;
    dq = 0;

    #1300ns;
    @(posedge clk);
    di = 32767;
    dq = 32767;
    for (int n = 0;n < 20 ;n++ ) @(posedge clk);
    di = 0;
    dq = 0;

  end



endmodule

//  9010_0000_0033_0000_00FF_FFFF_FF01_0000_0077_00ff_ff00_0000_0101_0000_ffa5_0ffe
