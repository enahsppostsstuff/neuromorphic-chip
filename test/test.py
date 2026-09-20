# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz).
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())

    # Reset the processor.
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    # ui_in[0] is input_spike_valid and ui_in[3:1] is input_neuron_id.
    # Send one spike to neuron 0. Keep the input asserted while the
    # processor starts so that the combinational neuron ID remains stable.
    dut._log.info("Send input spike to neuron 0")
    dut.ui_in.value = 0b00000001
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)

    # The processor evaluates six neurons, using one accumulate cycle and
    # one evaluate cycle per neuron. With the reset weights (1) and leak
    # (1), no neuron reaches the threshold, so the output remains idle.
    await ClockCycles(dut.clk, 12)

    assert int(dut.uo_out.value) == 0
