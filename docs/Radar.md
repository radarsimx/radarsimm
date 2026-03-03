# RadarSim.Radar

[&larr; Back to index](index.md)

## Properties

| Name | Default |
|------|---------|
| `version_` | '' |
| `tx_` |  |
| `rx_` |  |
| `num_tx_` |  |
| `num_rx_` |  |
| `num_frame_` |  |
| `frame_start_time_` |  |
| `samples_per_pulse_` |  |
| `timestamp_` |  |
| `radar_ptr` | 0 |

## Methods

### `obj = Radar(tx, rx, kwargs)`

Constructor for the Radar class. Initializes the radar system with the given transmitter and receiver.

**Parameters:**

- tx (RadarSim.Transmitter): The radar transmitter object.
- rx (RadarSim.Receiver): The radar receiver object.
- kwargs.location (1,3 double): Radar location coordinates (default: [0,0,0]).
- kwargs.speed (1,3 double): Radar speed (default: [0,0,0]).
- kwargs.rotation (1,3 double): Radar rotation in degrees (default: [0,0,0]).
- kwargs.rotation_rate (1,3 double): Radar rotation rate in degrees per second (default: [0,0,0]).

### `reset(obj)`

Reset radar Resets the radar system by freeing the radar pointer.

### `delete(obj)`

Delete radar Destructor for the Radar class. Frees the radar pointer and unloads the radar library if loaded.

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
