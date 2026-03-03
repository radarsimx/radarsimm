---
layout: default
title: Transmitter
---

# RadarSim.Transmitter

[&larr; Back to index](index.md)

## Properties

| Name | Default |
|------|---------|
| `version_` | '' |
| `f_` |  |
| `t_` |  |
| `power_` |  |
| `pulses_` |  |
| `pulse_duration_` |  |
| `prp_` |  |
| `pulse_start_time_` |  |
| `f_offset_` |  |
| `tx_ptr` | 0 |
| `channels_` | {} |
| `delay_` | [] |

## Methods

### `obj = Transmitter(f, t, kwargs)`

Constructor for Transmitter class. Initializes the Transmitter object with given frequency, time, and other parameters.

**Parameters:**

- f (double): Frequency.
- t (double): Time.
- kwargs.tx_power (double): Transmission power (default: 0).
- kwargs.pulses (uint32): Number of pulses (default: 1).
- kwargs.prp (double): Pulse repetition period (default: NaN).
- kwargs.f_offset (double): Frequency offset (default: NaN).
- kwargs.pn_f (double): PN frequency (default: NaN).
- kwargs.pn_power (double): PN power (default: NaN).
- kwargs.frame_time (double): Frame time (default: [0]).
- kwargs.channels (cell): Channels (default: {}).

### `add_txchannel(obj, tx_ch)`

Add transmitter channel Adds a transmitter channel to the Transmitter object.

**Parameters:**

- tx_ch (RadarSim.TxChannel): The transmitter channel object.

### `reset(obj)`

Reset transmitter Resets the Transmitter object, freeing any allocated resources.

### `delete(obj)`

Delete transmitter Deletes the Transmitter object and unloads the library if loaded.

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
