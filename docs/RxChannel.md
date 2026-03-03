---
layout: default
title: RxChannel
---

# RadarSim.RxChannel

[&larr; Back to index](index.md)

## Properties

| Name | Default |
|------|---------|
| `location_` |  |
| `polarization_` |  |
| `phi_` |  |
| `phi_ptn_` |  |
| `theta_` |  |
| `theta_ptn_` |  |
| `antenna_gain_` |  |

## Methods

### `obj = RxChannel(location, kwargs)`

Constructor for the RxChannel class. Initializes the receiver channel with specified location and optional parameters.

**Parameters:**

- location (1,3 double): The location coordinates of the receiver channel.
- kwargs.polarization (1,3 double): The polarization vector (default: [0,0,1]).
- kwargs.azimuth_angle (1,2 double): The azimuth angle range in degrees (default: [-90, 90]).
- kwargs.azimuth_pattern (1,2 double): The azimuth pattern (default: [0, 0]).
- kwargs.elevation_angle (1,2 double): The elevation angle range in degrees (default: [-90, 90]).
- kwargs.elevation_pattern (1,2 double): The elevation pattern (default: [0, 0]).

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
