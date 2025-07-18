`timescale 1ns / 1ps  // <time_unit>/<time_precision>


module coarse_cfo_tb;

  logic clk=0;
  logic rstn;

  // Clock generation (200 MHz)
  always #2.5ns clk = ~clk; // 5 ns period (200 MHz)

  initial begin
    clk = 0;
    rstn = 0;
    #20 rstn = 1;
  end

  logic rst;
  assign rst = !rstn;

//-------------------------------------------------------------------------------------------------
// 
//-------------------------------------------------------------------------------------------------

  localparam PIW = 16;
  logic signed [PIW-1:0] i_sym, q_sym;


  variable_strobe # (.PTR(0)) 
  variable_strobe_inst (
    .clk(clk),.rst(rst),
    .en_i('1),
    .stb_o(val));


//  coarse_cfo_mdl coarse_cfo_mdl_inst (
//    .clk        (clk            ),
//    .rst_n      (rstn           ),
//    .enable     ('1             ), // high during acquisition
//    .vld_in     (val            ), // one strobe per symbol
//    .i_in       (i_sym          ), // timing‑loop I sample
//    .q_in       (q_sym          ), // timing‑loop Q sample
//    .freq_word  (), // coarse word for NCO
//    .done       ()  // 1‑clk pulse when estimate valid
//  );


//-------------------------------------------------------------------------------------------------
// 
//-------------------------------------------------------------------------------------------------
  initial begin
    //i_sym = '0;
    //q_sym = '0;
    wait (rst == 0);
    #100ns;
  end


  localparam LEN = 4;
  logic signed [PIW-1:0] i_sym_a, q_sym_a [LEN-1:0];

  genvar i;
  generate for (i = 0; i < LEN; i++) begin 
    
    coarse_cfo_mdl coarse_cfo_mdl_inst (
      .clk        (clk            ),
      .rst_n      (rstn           ),
      .enable     ('1             ), // high during acquisition
      .vld_in     (val            ), // one strobe per symbol
      .i_in       (i_sym_a[i]     ), // timing‑loop I sample
      .q_in       (q_sym_a[i]     ), // timing‑loop Q sample
      .freq_word  (), // coarse word for NCO
      .done       ()  // 1‑clk pulse when estimate valid
    );

    cfo_test #(
      .SEL (i ),
      .OW  (16)  
    )cfo_test(
      .clk  (clk),
      .rst  (rst),
      .val  (val),
      .i_o  (i_sym_a[i]),   
      .q_o  (q_sym_a[i])    
    );
  end endgenerate 

endmodule