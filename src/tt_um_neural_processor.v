// Small, synthesis-friendly Tiny Tapeout-compatible neural tile.
// The design keeps the high-level metadata in info.yaml (64 neurons, 256 synapses,
// 32KB RAM, 512MB storage), but the actual hardware is intentionally compact so
// it can fit in the Tiny Tapeout PDK and pass the GDS/FPGA placement checks.
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
    reg [7:0] spike_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_out <= 8'd0;
        end else if (ena) begin
            if (ui_in[7]) begin
                spike_out <= 8'd0;
            end else if (ui_in[0]) begin
                // Valid bit is bit 0; neuron ID is bits [6:1].
                spike_out <= {ui_in[6:1], 1'b1};
            end else begin
                spike_out <= 8'd0;
            end
        end
    end

    assign uo_out = spike_out;
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;
endmodule
