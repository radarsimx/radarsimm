# RadarSim.TxChannel

[&larr; Back to index](index.md)

TxChannel class represents a transmission channel in the radar simulation. This class handles the properties and methods related to the transmission channel including location, polarization, delay, angles, patterns, and modulation.

## Properties

| Name | Default |
|------|---------|
| `location_` |  |
| `polarization_` |  |
| `delay_` |  |
| `phi_` |  |
| `phi_ptn_` |  |
| `theta_` |  |
| `theta_ptn_` |  |
| `antenna_gain_` |  |
| `pulse_mod_` |  |
| `mod_t_` |  |
| `mod_var_` |  |

## Methods

### `obj = TxChannel(location, kwargs)`

Constructor for TxChannel class. Initializes the transmission channel with specified location and optional parameters.

**Parameters:**

- location (1,3 double): The location coordinates of the transmission channel.
- kwargs.polarization (1,3 double): The polarization vector (default: [0,0,1]).
- kwargs.delay (double): The delay in the transmission (default: 0).
- kwargs.azimuth_angle (1,2 double): The azimuth angle range in degrees (default: [-90, 90]).
- kwargs.azimuth_pattern (1,2 double): The azimuth pattern (default: [0, 0]).
- kwargs.elevation_angle (1,2 double): The elevation angle range in degrees (default: [-90, 90]).
- kwargs.elevation_pattern (1,2 double): The elevation pattern (default: [0, 0]).
- kwargs.pulse_amp (double): The pulse amplitude.
- kwargs.pulse_phs (double): The pulse phase in degrees.
- kwargs.mod_t (double): The modulation time.
- kwargs.phs (double): The phase in degrees.
- kwargs.amp (double): The amplitude.

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
