// Simple Tiny Tapeout-compatible design: sum of the two 8-bit inputs.
module tt_um_neural_processor (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    assign uo_out = ui_in + uio_in;
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

endmodule
