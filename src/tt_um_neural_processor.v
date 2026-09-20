// 1x1 neuromorphic processor: 64 neurons, 256 configurable synapses.
// The 512 MiB storage value is a logical/external storage capacity; it is not
// instantiated as on-chip flip-flops or SRAM. The synthesizable on-chip RAM is
// 32 KiB (8192 x 32-bit words).
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
    localparam integer NUM_NEURONS = 64;
    localparam integer NUM_SYNAPSES = 256;
    localparam integer RAM_BYTES = 32768;
    localparam integer STORAGE_BYTES = 536870912;
    localparam [7:0] FIRE_THRESHOLD = 8'd3;

    // 32 KiB on-chip working RAM. STORAGE_BYTES documents the external
    // storage capacity and deliberately does not allocate a 512 MiB array.
    reg [31:0] ram [0:8191];
    reg [5:0] syn_target [0:NUM_SYNAPSES-1];
    reg [1:0] syn_weight [0:NUM_SYNAPSES-1];
    reg       syn_valid  [0:NUM_SYNAPSES-1];
    reg [7:0] membrane   [0:NUM_NEURONS-1];

    reg       output_valid;
    reg [5:0] output_neuron;
    integer i;
    integer j;
    integer syn_index;
    integer target_index;
    integer accumulated;

    wire cfg_write = ui_in[7];
    wire spike_valid = ui_in[0];
    wire [5:0] neuron_id = ui_in[6:1];
    // Four synapse slots are available for each of the 64 pre-synaptic neurons.
    wire [7:0] cfg_synapse = {neuron_id, uio_in[1:0]};
    wire [5:0] cfg_target = uio_in[7:2];
    wire [1:0] cfg_weight = uio_in[1:0] + 2'd1;

    assign uo_out = {1'b0, output_neuron, output_valid};
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    always @(posedge clk) begin
        if (!rst_n) begin
            output_valid <= 1'b0;
            output_neuron <= 6'b0;
            for (i = 0; i < NUM_NEURONS; i = i + 1)
                membrane[i] <= 8'b0;
            for (i = 0; i < NUM_SYNAPSES; i = i + 1) begin
                syn_target[i] <= 6'b0;
                syn_weight[i] <= 2'b0;
                syn_valid[i] <= 1'b0;
            end
        end else if (ena) begin
            output_valid <= 1'b0;

            if (cfg_write) begin
                syn_target[cfg_synapse] <= cfg_target;
                syn_weight[cfg_synapse] <= cfg_weight;
                syn_valid[cfg_synapse] <= 1'b1;
            end

            if (spike_valid && !cfg_write) begin
                for (j = 0; j < 4; j = j + 1) begin
                    syn_index = {neuron_id, 2'b00} + j;
                    if (syn_valid[syn_index]) begin
                        target_index = syn_target[syn_index];
                        accumulated = membrane[target_index] + syn_weight[syn_index];
                        if (accumulated >= FIRE_THRESHOLD) begin
                            membrane[target_index] <= 8'b0;
                            output_valid <= 1'b1;
                            output_neuron <= syn_target[syn_index];
                        end else begin
                            membrane[target_index] <= accumulated[7:0];
                        end
                    end
                end
            end
        end
    end
endmodule
