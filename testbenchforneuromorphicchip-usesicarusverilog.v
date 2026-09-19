`timescale 1ns/1ps

module tb_neural_processor;

    // ----------------------------------------------------------------
    // Testbench Clock and Interface Signals
    // ----------------------------------------------------------------
    logic [7:0] ui_in;
    logic [7:0] uo_out;
    logic [7:0] uio_in;
    logic [7:0] uio_out;
    logic [7:0] uio_oe;
    logic       ena;
    logic       clk;
    logic       rst_n;

    // ----------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // ----------------------------------------------------------------
    tt_um_neural_processor dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // ----------------------------------------------------------------
    // Clock Generation (50 MHz / 20ns period)
    // ----------------------------------------------------------------
    always begin
        #10 clk = ~clk;
    end

    // ----------------------------------------------------------------
    // Test Vectors Execution Flow
    // ----------------------------------------------------------------
    initial begin
        // Setup GTKWave VCD dump files
        $dumpfile("neural_processor_waves.vcd");
        $dumpvars(0, tb_neural_processor);

        // Initialize Signals
        clk   = 0;
        rst_n = 0;
        ena   = 0;
        ui_in  = 8'b0000_0000;
        uio_in = 8'b0000_0000;

        // Hold reset for 5 clock cycles
        repeat (5) @(posedge clk);
        #1;
        rst_n = 1;  // De-assert reset
        ena   = 1;  // Enable design
        $display("[TB] --- Hardware Out of Reset & Active ---");

        // Wait a cycle
        @(posedge clk);
        #1;

        // ============================================================
        // TEST CASE 1: Configure Synapse (Pre-synaptic 2 -> Post-synaptic 4)
        // Set its weight to +3 (Maximum positive weight)
        // ============================================================
        $display("[TB] Writing weight configuration: Synapse(Pre=2, Post=4) <= +3");
        ui_in[4]   = 1'b1;         // cfg_write_en = 1
        ui_in[7:5] = 3'b011;       // cfg_weight_data = +3 (signed 3-bit)
        uio_in[2:0] = 3'b010;      // cfg_target_pre = 2
        uio_in[5:3] = 3'b100;      // cfg_target_post = 4
        
        @(posedge clk);
        #1;
        // Turn off configuration write immediately
        ui_in  = 8'b0000_0000;
        uio_in = 8'b0000_0000;
        
        repeat (2) @(posedge clk);

        // ============================================================
        // TEST CASE 2: Send input spikes to stimulate the network
        // We will fire input channel 2 repeatedly.
        // It should accumulate (+3 weight - 1 leak) = +2 net gain per step.
        // Firing threshold is +15, so it should fire after ~8 spikes.
        // ============================================================
        $display("[TB] Beginning repeated spike injection cycle on Input 2...");
        
        for (int spike_count = 1; spike_count <= 10; spike_count = spike_count + 1) begin
            $display("[TB] Injecting input spike #%0d", spike_count);
            
            @(posedge clk);
            #1;
            ui_in[0]   = 1'b1;     // input_spike_valid = 1
            ui_in[3:1] = 3'b010;   // input_neuron_id = 2
            
            @(posedge clk);
            #1;
            ui_in = 8'b0000_0000;  // Turn off spike valid flag (Single cycle pulse)

            // Each input spike requires 8 internal accumulation cycles to process
            // through the entire 8-neuron post-synaptic list array.
            repeat (10) @(posedge clk);
        end

        // Wait a few cycles at rest
        repeat (10) @(posedge clk);

        $display("[TB] --- Simulation Run Completed Successfully ---");
        $finish;
    end

    // ----------------------------------------------------------------
    // Output Spike Monitor Logic
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        if (uo_out[0]) begin
            $display("[MONITOR ALERT] Spike Detected! Output Neuron ID: %0d fired at time %0t", uo_out[3:1], $time);
        end
    end

endmodule
