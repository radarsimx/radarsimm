# RadarSim.MeshTarget

[&larr; Back to index](index.md)

## Properties

| Name | Default |
|------|---------|
| `type_` | "mesh" |
| `points_` |  |
| `connectivity_list_` |  |
| `location_` |  |
| `speed_` |  |
| `rotation_` |  |
| `rotation_rate_` |  |
| `origin_` |  |
| `permittivity_` |  |
| `skip_diffusion_` |  |
| `density_` |  |
| `environment_` |  |

## Methods

### `obj = MeshTarget(points, connectivity_list, location, speed, rotation, rotation_rate, kwargs)`

Constructor for the MeshTarget class. Initializes the mesh target with specified parameters.

**Parameters:**

- points (double): Array of points defining the mesh.
- connectivity_list (int32): List defining the connectivity of the mesh points.
- location (1,3 double): Location of the target.
- speed (1,3 double): Speed of the target.
- rotation (1,3 double): Rotation of the target in degrees.
- rotation_rate (1,3 double): Rotation rate of the target in degrees per second.
- kwargs.origin (1,3 double): Origin of the target (default: [0,0,0]).
- kwargs.permittivity (char): Permittivity of the target (default: 'PEC').
- kwargs.skip_diffusion (logical): Flag indicating to skip the diffusion calculation (default: false).
- kwargs.density (double): Ray density for this target, 0 uses global density (default: 0).
- kwargs.environment (logical): Environment flag for target (default: false).

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
