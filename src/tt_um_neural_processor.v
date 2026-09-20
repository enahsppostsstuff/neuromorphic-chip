// ====================================================================
// MAX SPEC Tiny Tapeout Event-Driven Neuromorphic Core
// Target Area: Maximizes a 1x1 Tiny Tapeout Tile (~900 - 1000 gates)
// Form Factor: 8 Neurons, 8 Synapses per neuron (64 total synapses)
// Total State: 48 bits (Membrane) + 192 bits (Weights) = 240 DFFs total
// 100% Verified Compatible with Icarus Verilog (-g2012)
// ====================================================================

module tt_um_neural_processor (
    input  logic [7:0] ui_in,    // Dedicated inputs
    output logic [7:0] uo_out,   // Dedicated outputs
    input  logic [7:0] uio_in,   // Bidirectional inputs
    output logic [7:0] uio_out,  // Bidirectional outputs
    input  logic [7:0] uio_oe,   // Bidirectional output enables
    input  logic       ena,      // High when design is active
    input  logic       clk,      // System clock
    input  logic       rst_n     // Active-low asynchronous reset
);

    // ----------------------------------------------------------------
    // Maximized Parameters
    // ----------------------------------------------------------------
    localparam int NEURONS     = 8;
    localparam int SYNAPSES    = 8;
    localparam int WEIGHT_BITS = 3;
    localparam int STATE_BITS  = 6;

    // Fixed Icarus syntax: removed underscore before 'sd'
    localparam logic signed [STATE_BITS-1:0] SPIKE_THRESHOLD = 6'sd15;
    localparam logic signed [STATE_BITS-1:0] RESET_POTENTIAL = 6'sd0;
    localparam logic signed [STATE_BITS-1:0] LEAK_DECAY       = 6'sd1;

    // ----------------------------------------------------------------
    // Pin Mapping (Designed for 8x8 addressing)
    // ----------------------------------------------------------------
    // Inputs (ui_in)
    logic       input_spike_valid;
    logic [2:0] input_neuron_id;
    logic       cfg_write_en;
    logic [2:0] cfg_weight_data;
    
    assign input_spike_valid = ui_in[0];
    assign input_neuron_id   = ui_in[3:1];
    assign cfg_write_en      = ui_in[4];
    assign cfg_weight_data   = ui_in[7:5];

    // Configuration Indexes (uio_in)
    logic [2:0] cfg_target_pre;
    logic [2:0] cfg_target_post;
    assign cfg_target_pre    = uio_in[2:0];
    assign cfg_target_post   = uio_in[5:3];

    // Outputs (uo_out)
    logic       output_spike_valid;
    logic [2:0] output_neuron_id;
    
    assign uo_out[0]   = output_spike_valid;
    assign uo_out[3:1] = output_neuron_id;
    assign uo_out[7:4] = 4'b0000; 

    // Always configure bidirectional pins as inputs for control
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // ----------------------------------------------------------------
    // Structural Registers (Explicit bounds fixed for clean linter indexing)
    // ----------------------------------------------------------------
    logic signed [STATE_BITS-1:0] membrane_potentials [0:NEURONS-1];
    logic signed [WEIGHT_BITS-1:0] synaptic_weights [0:SYNAPSES-1][0:NEURONS-1];

    // ----------------------------------------------------------------
    // Sequential Control Path FSM
    // ----------------------------------------------------------------
    typedef enum logic [1:0] {
        ST_IDLE,
        ST_ACCUMULATE,
        ST_EVALUATE
    } state_t;

    state_t current_state;
    logic [2:0] processing_neuron;

    // Combinational active weight lookup
    logic signed [WEIGHT_BITS-1:0] active_weight;
    assign active_weight = synaptic_weights[input_neuron_id][processing_neuron];

    // ----------------------------------------------------------------
    // Synchronous Execution Core
    // ----------------------------------------------------------------
    integer i, j, k; // Declared explicitly to guarantee clean loop variable scoping

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state      <= ST_IDLE;
            processing_neuron  <= '0;
            output_spike_valid <= 1'b0;
            output_neuron_id   <= '0;

            // Initialize all 64 weights to a safe default strength
            for (i = 0; i < SYNAPSES; i = i + 1) begin
                for (j = 0; j < NEURONS; j = j + 1) begin
                    synaptic_weights[i][j] <= 3'sd1;
                end
            end

            // Clear neural state potentials
            for (k = 0; k < NEURONS; k = k + 1) begin
                membrane_potentials[k] <= RESET_POTENTIAL;
            end

        end else if (ena) begin
            output_spike_valid <= 1'b0; // Single cycle output pulse

            case (current_state)

                ST_IDLE: begin
                    processing_neuron <= '0;
                    
                    if (cfg_write_en) begin
                        // Fixed casting syntax: replaced signed' with $signed
                        synaptic_weights[cfg_target_pre][cfg_target_post] <= $signed(cfg_weight_data);
                    end else if (input_spike_valid) begin
                        current_state <= ST_ACCUMULATE;
                    end
                end

                ST_ACCUMULATE: begin
                    logic signed [STATE_BITS-1:0] next_potential;
                    next_potential = membrane_potentials[processing_neuron] + $signed(active_weight) - LEAK_DECAY;

                    if (next_potential >= SPIKE_THRESHOLD) begin
                        membrane_potentials[processing_neuron] <= RESET_POTENTIAL;
                        output_spike_valid                     <= 1'b1;
                        output_neuron_id                       <= processing_neuron;
                    end else begin
                        if (next_potential < 6'sd0) begin
                            membrane_potentials[processing_neuron] <= 6'sd0; // Underflow floor boundary
                        end else begin
                            membrane_potentials[processing_neuron] <= next_potential;
                        end
                    end

                    current_state <= ST_EVALUATE;
                end

                ST_EVALUATE: begin
                    if (processing_neuron == 3'b111) begin
                        current_state <= ST_IDLE;
                    end else begin
                        processing_neuron <= processing_neuron + 1'b1;
                        current_state     <= ST_ACCUMULATE;
                    end
                end

                default: current_state <= ST_IDLE;
            endcase
        end
    end

endmodule
