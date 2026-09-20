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

    # A valid spike on neuron 3 should generate a pulse with the valid bit set and
    # the neuron id encoded in bits [6:1].
    dut.ui_in.value = (1 << 0) | (3 << 1)
    await ClockCycles(dut.clk, 1)

    assert int(dut.uo_out.value & 1) == 1
    assert ((int(dut.uo_out.value) >> 1) & 0x3F) == 3
    assert int(dut.uio_oe.value) == 0
