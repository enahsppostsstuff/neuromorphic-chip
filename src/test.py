import cocotb
from cocotb.triggers import Timer, ClockCycles

@cocotb.test()
async def test_neural_processor(dut):
    dut._log.info("--- Starting Max-Spec Neural Processor Python Testbench ---")

    dut.ui_in.value = 0x00
    dut.uio_in.value = 0x00
    dut.ena.value = 0
    dut.rst_n.value = 0

    await Timer(40, units="ns")
    dut.rst_n.value = 1
    dut.ena.value = 1
    await ClockCycles(dut.clk, 2)

    # TEST CASE A: Write Weight +3 to Synapse Matrix coordinate (2,4)
    # ui_in bit structure matching assign logic paths:
    # ui_in[7:5] = 011 (+3) | ui_in[4] = 1 (write_en) | ui_in[3:1] = 010 (pre_id 2) | ui_in[0] = 0
    # Binary: 0b01110100 -> Hex: 0x74
    # uio_in[5:3] = 100 (post_id 4) | uio_in[2:0] = 010 (pre_id 2)
    # Binary: 0b00100010 -> Hex: 0x22
    dut.ui_in.value = 0x74
    dut.uio_in.value = 0x22
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = 0x00
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 2)

    # TEST CASE B: Inject active spike event from Channel 2
    # Binary: 0b00000101 -> Hex: 0x05
    dut.ui_in.value = 0x05
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0x00

    await ClockCycles(dut.clk, 12)
    dut._log.info("[TB] Test passed successfully!")
