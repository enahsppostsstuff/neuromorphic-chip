# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    # Configure one of four synapse slots for pre-neuron 3. The design has
    # 64 neurons, 4 slots per neuron, and therefore 256 total synapses.
    # ui[7] = config write, ui[6:1] = pre-neuron, uio[7:2] = post-neuron.
    dut.ui_in.value = (1 << 7) | (3 << 1)
    dut.uio_in.value = (7 << 2) | 0  # post-neuron 7, slot 0
    await ClockCycles(dut.clk, 1)

    # A weight of three reaches the firing threshold in one event.
    dut.ui_in.value = (1 << 0) | (3 << 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)

    assert int(dut.uo_out.value & 1) == 1
    assert (int(dut.uo_out.value) >> 1) & 0x3F == 7
    assert int(dut.uio_oe.value) == 0
