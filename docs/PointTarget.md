# RadarSim.PointTarget

[&larr; Back to index](index.md)

PointTarget Class representing a point target in the radar simulation. This class defines the properties and methods for a point target, including its location, speed, radar cross section (RCS), and phase.

## Properties

| Name | Default |
|------|---------|
| `type_` | "point"; % Type of the target |
| `location_` |  |
| `rcs_` |  |
| `speed_` |  |
| `phase_` |  |

## Methods

### `obj = PointTarget(location, speed, rcs, kwargs)`

Constructor for the PointTarget class. Initializes the location, speed, RCS, and phase of the target.

**Parameters:**

- location (1,3 double): Location of the target [x, y, z].
- speed (1,3 double): Speed of the target [vx, vy, vz].
- rcs (double): Radar cross section of the target.
- kwargs.phase (double): Phase of the target in degrees (default: 0).

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
