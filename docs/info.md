## How it works
This is an 8x8 event-driven spiking neural processor. It processes input spikes sequentially by stepping an accumulation index through post-synaptic neurons, managing 3-bit weights and 6-bit states with leaky integrate-and-fire decay tracking.

## How to test
Provide an asynchronous system reset. Use the configuration write lines to clock values into the synaptic registers. Apply input valid pulses accompanied by target source indexes, then trace the dedicated output bitstream pins for firing events.
