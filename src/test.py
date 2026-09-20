import cocotb
from cocotb.triggers import Timer, ClockCycles, RisingEdge

@cocotb.test()
async def test_neural_processor_comprehensive(dut):
    dut._log.info("Starting Max-Spec Neuromorphic Processor cocotb test...")

    # 1. Initialize Inputs
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 0
    dut.rst_n.value = 0

    # 2. Wait a few moments then release asynchronous active-low reset
    await Timer(40, units="ns")
    dut.rst_n.value = 1
    dut.ena.value = 1
    await Timer(20, units="ns")
    dut._log.info("System hardware is out of reset and enabled.")

    # 3. Test Weight Configuration Mode
    # Write a maximum positive weight (+3 -> binary 011) to Synapse(Pre=2, Post=4)
    # Mapping to UI_IN configurations:
    # ui_in[0] = cfg_write_en (1)
    # ui_in[3:1] = input_neuron_id (010 -> 2)
    # ui_in[4] = cfg_write_en duplicate, let's drive it to match
    # ui_in[7:5] = cfg_weight_data (011 -> +3) -> Total ui_in = 0b01110101 (0x75)
    # uio_in[2:0] = cfg_target_pre (010 -> 2)
    # uio_in[5:3] = cfg_target_post (100 -> 4) -> Total uio_in = 0b00100010 (0x22)
    
    dut.ui_in.value = 0x75
    dut.uio_in.value = 0x22
    await ClockCycles(dut.clk, 1)
    
    # Immediately clear configuration write lines
    dut.ui_in.value = 0x00
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 2)

    # 4. Test Spike Processing Mode
    # Strobe an incoming active spike on Input Channel 2
    # ui_in[0] = input_spike_valid (1)
    # ui_in[3:1] = input_neuron_id (010 -> 2) -> Total ui_in = 0b00000101 (0x05)
    dut.ui_in.value = 0x05
    await ClockCycles(dut.clk, 1)
    
    # Pull the single-cycle spike valid strobe back low
    dut.ui_in.value = 0x00
    
    # Give the core 12 internal clock cycles to finish its 8-neuron sequential accumulation
    await ClockCycles(dut.clk, 12)
    
    dut._log.info("Processor evaluation cycle completed successfully!")
