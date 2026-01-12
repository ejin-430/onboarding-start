<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project is a simple SPI-controlled PWM output peripheral designed for Tiny Tapeout. It receives configuration data over an SPI interface and uses it to control 16 output pins.

Internally, SPI write transactions update a small set of registers that determine which outputs are enabled, which outputs use PWM mode, and what the PWM duty cycle is. A shared PWM generator produces a waveform based on the duty cycle register, and each output either stays low, stays high, or follows the PWM signal depending on its configuration.

The lower 8 outputs are driven through uo_out[7:0], and the upper 8 outputs are driven through uio_out[7:0], with all bidirectional pins configured as outputs.

## How to test

The project can be tested using the provided Cocotb testbench. SPI write transactions are sent to the design to configure the output enable registers and PWM settings.

Tests verify:
- Correct SPI write behavior
- PWM frequency and duty cycle correctness
- Output behavior when PWM is enabled or disabled

## External hardware

No external hardware required. This project is simulated using Cocotb.
