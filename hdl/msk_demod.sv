
// runs at oversampled rate, choice for symbol sample point

module msk_demod #(
    parameter real FS = 200.0e6,  // Sample rate (Hz)
    parameter real F_SYM = 10.0e6 // Symbol rate (Hz)
)(
    input logic clk,
    input logic reset_n,
    input int   midpoint_adj,
    input logic signed [15:0] i_in,  // In-phase (I) input from if_to_iq
    input logic signed [15:0] q_in,  // Quadrature (Q) input from if_to_iq
    input logic               iq_val,
    output logic data_out,            // Recovered binary data
    output logic data_val
);

  localparam int SAMPLE_MIDPOINT = 10;

// Registers to store the previous I and Q samples.
  logic signed [15:0] I_prev;
  logic signed [15:0] Q_prev;
  logic midpoint_active;

  always_ff @(posedge clk) begin
    if (~reset_n) begin
      I_prev   <= '0;
      Q_prev   <= '0;
    end else if (midpoint_active) begin
      I_prev <= i_in;
      Q_prev <= q_in;
    end
  end

  integer sample_cnt, midpoint;
  assign midpoint = SAMPLE_MIDPOINT + midpoint_adj;

  always_ff @(posedge clk) begin
    if (~reset_n) begin
      sample_cnt <= 0;
      midpoint_active <= 0;
    end else if (iq_val) begin 
      midpoint_active <= 0;
      sample_cnt <= sample_cnt + 1;
      if (sample_cnt == 19) begin 
        sample_cnt <= 0;
      end
      if (sample_cnt == midpoint) begin 
        //sample_cnt <= 0;
        midpoint_active <= 1;
      end 
    end 
  end 


  logic signed [17:0] dsp_i_in,dsp_q_in,dsp_ip_in,dsp_qp_in;
  logic signed [47:0] mult_IxQP,mult_QxIP,imag_diff;

  assign dsp_i_in = signed'({i_in});
  assign dsp_q_in = signed'({q_in});
  assign dsp_ip_in = signed'({I_prev});
  assign dsp_qp_in = signed'({Q_prev});


  //   imag = q_in * I_prev - i_in * Q_prev
  // A*B-C
  dsp_macro_AxBmC IxQP (
    .CLK  (clk        ),// input wire CLK
    .CE   (midpoint_active     ),
    .A    (dsp_i_in   ),// input wire [17 : 0] A
    .B    (dsp_qp_in  ),// input wire [17 : 0] B
    .C    ('0         ),// input wire [47 : 0] C
    .P    (mult_IxQP  )// output wire [47 : 0] P
  );

  dsp_macro_AxBmC QxIP (
    .CLK  (clk        ),
    .CE   (midpoint_active     ),
    .A    (dsp_q_in   ),
    .B    (dsp_ip_in  ),
    .C    ('0         ),
    .P    (mult_QxIP  )
  );

// dsp has 3 CLK/CE delay to output
  logic mult_val, mult_val_stb, mult_ce_sr;
  logic [3:0] mult_val_sr;
  always_ff @(posedge clk) begin
    mult_ce_sr <= midpoint_active;
    if (~reset_n) mult_val_sr <= 0;
    else if (midpoint_active) mult_val_sr <= {mult_val_sr[2:0],midpoint_active};
  end

  assign mult_val_stb = (mult_val && mult_ce_sr && !midpoint_active);// dsp mult output valid this clock cycle
  assign mult_val = mult_val_sr[3];


  assign imag_diff = mult_QxIP - mult_IxQP;

  assign data_out = (imag_diff >= 0) ? 1:0;

  assign data_val = mult_val_stb;

endmodule
