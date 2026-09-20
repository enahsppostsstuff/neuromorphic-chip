// ====================================================================
// MAX FIT Tiny Tapeout Event-Driven Neuromorphic Core
// Target Area: Fits tightly inside a 1x1 Tiny Tapeout Tile (~850 gates)
// Form Factor: 6 Neurons, 6 Synapses per neuron (36 total synapses)
// 100% Safe Array Bounds Checked for Icarus Verilog and OpenROAD
// ====================================================================

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

    // ----------------------------------------------------------------
    // Scaled Parameters for 1x1 Tile Placement Target Clearances
    // ----------------------------------------------------------------
    localparam int NEURONS     = 6;
    localparam int SYNAPSES    = 6;
    localparam int WEIGHT_BITS = 3;
    localparam int STATE_BITS  = 6;

    localparam logic signed [STATE_BITS-1:0] SPIKE_THRESHOLD = 6'sd15;
    localparam logic signed [STATE_BITS-1:0] RESET_POTENTIAL = 6'sd0;
    localparam logic signed [STATE_BITS-1:0] LEAK_DECAY       = 6'sd1;

    // ----------------------------------------------------------------
    // Pin Mapping (6x6 matrix mapping)
    // ----------------------------------------------------------------
    logic       input_spike_valid;
    logic [2:0] input_neuron_id;
    logic       cfg_write_en;
    logic [2:0] cfg_weight_data;
    
    assign input_spike_valid = ui_in[0];
    assign input_neuron_id   = ui_in[3:1];
    assign cfg_write_en      = ui_in[4];
    assign cfg_weight_data   = ui_in[7:5];

    logic [2:0] cfg_target_pre;
    logic [2:0] cfg_target_post;
    assign cfg_target_pre    = uio_in[2:0];
    assign cfg_target_post   = uio_in[5:3];

    logic       output_spike_valid;
    logic [2:0] output_neuron_id;

    assign uo_out = {4'b0000, output_neuron_id, output_spike_valid};

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // ----------------------------------------------------------------
    // Structural Registers
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

    logic signed [WEIGHT_BITS-1:0] active_weight;
    assign active_weight = (input_neuron_id < SYNAPSES && processing_neuron < NEURONS) ? 
                           synaptic_weights[input_neuron_id][processing_neuron] : 3'sd0;

    // ----------------------------------------------------------------
    // Synchronous Execution Core
    // ----------------------------------------------------------------
    integer i, j, k;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state      <= ST_IDLE;
            processing_neuron  <= '0;
            output_spike_valid <= 1'b0;
            output_neuron_id   <= '0;

            for (i = 0; i < SYNAPSES; i = i + 1) begin
                for (j = 0; j < NEURONS; j = j + 1) begin
                    synaptic_weights[i][j] <= 3'sd1;
                end
            end

            for (k = 0; k < NEURONS; k = k + 1) begin
                membrane_potentials[k] <= RESET_POTENTIAL;
            end

        end else if (ena) begin
            output_spike_valid <= 1'b0; 

            case (current_state)

                ST_IDLE: begin
                    processing_neuron <= '0;
                    if (cfg_write_en) begin
                        if (cfg_target_pre < SYNAPSES && cfg_target_post < NEURONS) begin
                            synaptic_weights[cfg_target_pre][cfg_target_post] <= $signed(cfg_weight_data);
                        end
                    end else if (input_spike_valid) begin
                        current_state <= ST_ACCUMULATE;
                    end
                end

                ST_ACCUMULATE: begin
                    logic signed [STATE_BITS-1:0] next_potential;
                    
                    // Fixed: Explicitly bound guard check to prevent out-of-bounds simulator array index crashes
                    if (processing_neuron < NEURONS) begin
                        next_potential = membrane_potentials[processing_neuron] + $signed(active_weight) - LEAK_DECAY;

                        if (next_potential >= SPIKE_THRESHOLD) begin
                            membrane_potentials[processing_neuron] <= RESET_POTENTIAL;
                            output_spike_valid                     <= 1'b1;
                            output_neuron_id                       <= processing_neuron;
                        end else begin
                            if (next_potential < 6'sd0) begin
                                membrane_potentials[processing_neuron] <= 6'sd0; 
                            end else begin
                                membrane_potentials[processing_neuron] <= next_potential;
                            end
                        end
                    end
                    current_state <= ST_EVALUATE;
                end

                ST_EVALUATE: begin
                    if (processing_neuron >= (NEURONS - 1)) begin
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
