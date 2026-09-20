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

    # Valid pulse at neuron 3 should appear as 0b0000011? no, valid is bit 0: 0b0000011? etc.
    # Actual output format: bit[0]=valid, bits[6:1]=neuron_id.
    dut.ui_in.value = (1 << 0) | (3 << 1)
    await ClockCycles(dut.clk, 1)

    out = int(dut.uo_out.value)
    assert (out & 1) == 1
    assert ((out >> 1) & 0x3F) == 3
    assert int(dut.uio_oe.value) == 0
