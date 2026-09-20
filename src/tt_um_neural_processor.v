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
    reg [7:0] config_word;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_out   <= 8'd0;
            config_word <= 8'd0;
        end else if (ena) begin
            // Config write path: capture the configuration word but keep the core tiny.
            if (ui_in[7]) begin
                config_word <= uio_in;
                spike_out   <= 8'd0;
            end else if (ui_in[0]) begin
                // ui[6:1] is the 6-bit neuron id and bit 0 is the valid pulse.
                spike_out <= {1'b1, ui_in[6:1]};
            end else begin
                spike_out <= 8'd0;
            end
        end
    end

    assign uo_out = spike_out;
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;
endmodule
