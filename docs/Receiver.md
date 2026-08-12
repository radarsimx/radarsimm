---
layout: default
title: Receiver
---

# RadarSim.Receiver

[&larr; Back to index](index.md)

## Properties

| Name | Default |
|------|---------|
| `version_` | '' |
| `fs_` |  |
| `noise_figure_` |  |
| `rf_gain_` |  |
| `baseband_gain_` |  |
| `load_resistor_` |  |
| `noise_bandwidth_` |  |
| `bb_type_` |  |
| `gate_delay_` |  |
| `channels_` | {} |
| `rx_ptr` | 0 |

## Methods

### `obj = Receiver(fs, rf_gain, load_resistor, baseband_gain, kwargs)`

Constructor for the Receiver class. Initializes the receiver with specified parameters.

**Parameters:**

- fs (double): Sampling frequency.
- rf_gain (double): RF gain.
- load_resistor (double): Load resistor.
- baseband_gain (double): Baseband gain.
- kwargs.noise_figure (double): Noise figure (default: 0).
- kwargs.bb_type (char): Baseband type ('complex' or 'real') (default: 'complex').
- kwargs.gate_delay (double): Range-gate/deramp reference delay in seconds (default: 0). The receive window opens gate_delay after the chirp start and the deramp reference is delayed by the same amount, so a target at range c*gate_delay/2 produces a DC beat. 0 keeps the zero-delay deramp behavior.
- kwargs.channels (cell): Channels (default: {}).

### `add_rxchannel(obj, rx_ch)`

Add a receiver channel Adds a receiver channel to the Receiver object.

**Parameters:**

- rx_ch (RadarSim.RxChannel): The receiver channel object.

### `reset(obj)`

Reset the receiver Resets the Receiver object, freeing any allocated resources.

### `delete(obj)`

Delete the receiver Deletes the Receiver object, freeing its backend resources. radarsimc is deliberately left loaded: see RadarSim.Radar.delete.

---
*Copyright (C) 2023 - 2026 RadarSimX LLC*
