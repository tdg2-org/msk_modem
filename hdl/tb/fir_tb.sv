module fir_tb;

    // Clock and reset
    logic clk;
    logic reset_n;

    
    // Clock generation (200 MHz)
    always #2.5ns clk = ~clk; // 5 ns period (200 MHz)
    //always #625ps clk = ~clk; // 800 MHz

    logic [7:0] test_vector[0:31] = '{8'hAA, 8'h55, 8'hFF, 8'h00, 8'hCC, 8'h33, 8'h0F, 8'hF0, 
                                      8'hA5, 8'h5A, 8'h3C, 8'hC3, 8'h78, 8'h87, 8'hE1, 8'h1E,
                                      8'h92, 8'h6D, 8'h4B, 8'hB4, 8'hF7, 8'h08, 8'hD3, 8'h2C,
                                      8'h19, 8'hE6, 8'hAC, 8'h53, 8'h07, 8'hF8, 8'hB9, 8'h46};


    logic               fir_I_tvalid, dc_fifo_I_tvalid,dc_fifo_I_tready;          
    logic signed [15:0] dc_fifo_I_tdata,fir_I_tdata;

    fir_lpf fir (
      .aclk               (clk                ),// input wire aclk
      .s_axis_data_tvalid (dc_fifo_I_tvalid   ),// input wire s_axis_data_tvalid
      .s_axis_data_tready (dc_fifo_I_tready   ),// output wire s_axis_data_tready
      .s_axis_data_tdata  (dc_fifo_I_tdata    ),// input wire [15 : 0] s_axis_data_tdata
      .m_axis_data_tvalid (fir_I_tvalid       ),// output wire m_axis_data_tvalid
      .m_axis_data_tdata  (fir_I_tdata        )// output wire [31 : 0] m_axis_data_tdata
    );

integer i;
logic rdy;

initial begin
  // Initialize signals
  clk = 0;
  reset_n = 0;
  dc_fifo_I_tdata = 0;
  rdy = 0;
  dc_fifo_I_tvalid =0;

  // Apply reset
  #20 reset_n = 1;
  repeat (500) @(posedge clk);
  wait (dc_fifo_I_tready == 1);
  rdy = 1;  
  @(posedge clk);
  dc_fifo_I_tvalid = 1;

  // Feed binary test vector
  for (i = 0; i < 32; i = i + 1) begin
      // Send bits serially (each bit lasts 20 clock cycles, assuming 10 MHz symbol rate)
      for (int j = 0; j < 8; j = j + 1) begin
          dc_fifo_I_tdata = test_vector[i][7 - j]; // MSB first
          repeat (20) @(posedge clk); // Hold for 20 clock cycles
      end
  end
  // Run for some extra cycles
  repeat (100) @(posedge clk);
  //$stop;
end



endmodule
