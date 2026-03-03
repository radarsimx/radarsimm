---
layout: default
title: RadarSimulator
---

# RadarSim.RadarSimulator

[&larr; Back to index](index.md)

## Properties

| Name | Default |
|------|---------|
| `version_` | '' |
| `baseband_` |  |
| `noise_` |  |
| `timestamp_` |  |
| `interference_` |  |
| `targets_ptr` | 0 |

## Methods

### `obj = RadarSimulator()`

Constructor for the RadarSimulator class. Loads the 'radarsimc' library if not already loaded and retrieves the version.

### `Run(obj, radar, targets, kwargs)`

Runs the radar simulation.

**Parameters:**

- radar (RadarSim.Radar): The radar object.
- targets (cell): List of target objects.
- kwargs.density (double): Density (default: 1).
- kwargs.level (char): Level ('frame', 'pulse', 'sample') (default: 'frame').
- kwargs.noise (logical): Noise flag (default: true).
- kwargs.ray_filter (1,2 double): Ray filter (default: [0, 10]).
- kwargs.interf (struct): Interference (default: []).

### `add_point_target(obj, target)`

Adds a point target to the simulation.

**Parameters:**

- target (RadarSim.PointTarget): The point target object.

### `add_mesh_target(obj, target)`

Adds a mesh target to the simulation.

**Parameters:**

- target (RadarSim.MeshTarget): The mesh target object.

### `noise_mat = generate_noise(obj, radar)`

Generates noise for the radar simulation.

**Parameters:**

- radar (RadarSim.Radar): The radar object.

**Returns:** noise_mat (double): The generated noise matrix.

### `reset(obj)`

Resets the simulation by freeing targets.

### `delete(obj)`

Destructor for the RadarSimulator class. Frees targets and unloads the 'radarsimc' library if loaded.

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
