# RadarSimM

<img src="https://raw.githubusercontent.com/radarsimx/.github/refs/heads/main/profile/radarsimm.svg" alt="logo" width="200"/>

[![MATLAB Tests](https://github.com/radarsimx/radarsimm/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/radarsimx/radarsimm/actions/workflows/matlab-tests.yml)

Radar Simulator for MATLAB.

## Introdcution

[`RadarSimM`](https://radarsimx.com/product/radarsimm/) is the MATLAB interface of RadarSimX. It utilizes the powerful C++/CUDA backend engine [`RadarSimCpp`](https://radarsimx.com/radarsimx/radarsimcpp/). This interface is designed to provide radar transceiver modeling and baseband simulation capabilities for both point targets and 3D models. It offers similar features as [`RadarSimPy`](https://radarsimx.com/product/radarsimpy/).

| RadarSimPy | RadarSimM |
| ---------- | --------- |
| <img src="./assets/fmcw_py.png" alt="radarsimpy"/> | <img src="./assets/fmcw_m.png" alt="radarsimpy"/> |
| <img src="./assets/arbitrary_py.png" alt="radarsimpy"/> | <img src="./assets/arbitrary_m.png" alt="radarsimpy"/> |
| <img src="./assets/imaging_py.png" alt="radarsimpy"/> | <img src="./assets/imaging_m.png" alt="radarsimpy"/> |
| <img src="./assets/interference_py.png" alt="radarsimpy"/> | <img src="./assets/interference_m.png" alt="radarsimpy"/> |

## Key Features

- ### Radar Modeling

  - Radar transceiver modeling
  - Arbitrary waveform
  - Phase noise
  - Phase/amplitude modulation
  - Fast-time/slow-time modulation

- ### Simulation

  - Simulation of radar baseband data from point targets
  - Simulation of radar baseband data from 3D modeled objects/environment
  - Simulation of interference
  - (TODO) Simulation of target's RCS
  - (TODO) Simulation of LiDAR point cloud from 3D modeled objects/environment

## Dependence

- MATLAB 64bit
- [MinGW-w64 C/C++ compiler](https://www.mathworks.com/support/requirements/supported-compilers.html) (Windows)

## Installation & Usage

- Download the compiled module from [RadarSimM](https://radarsimx.com/product/radarsimm/)
- Try the files in `examples`.

## Testing

Tests live in `tests/` and are written with the MATLAB unit testing
framework, split into two tiers:

- `tests/unit` — pure MATLAB. Covers the Tx/Rx channels, the point and mesh
  targets, the license guards, and the public class API. Runs without the
  compiled `radarsimc` backend.
- `tests/integration` — drives the real simulator end to end: baseband
  shape and timestamps, range-FFT peaks against known target ranges, noise,
  real vs. complex baseband, ray-traced mesh targets, and interference.
  Requires `radarsimc` and `radarsim.h` in `src/+RadarSim`, so it runs on
  Windows, where `loadlibrary` can parse the exported C API.

Run everything from the repository root:

```matlab
run_tests
```

Run one tier, or a single test class:

```matlab
run_tests('unit')

addpath('src');
runtests('tests/unit/TxChannelTest.m')
```

Or from a shell:

```bash
matlab -batch "run_tests"
matlab -batch "run_tests('unit')"
```

The [`MATLAB Tests`](.github/workflows/matlab-tests.yml) workflow runs both
tiers on GitHub Actions with [matlab-actions](https://github.com/matlab-actions):
the unit tests on Linux against R2022b, R2024b, and the latest MATLAB release,
and a second job on Windows that builds `radarsimc` from the `radarsimlib`
submodule with `build_win.bat`, stages it into `src/+RadarSim`, and then runs
the full suite against that build. JUnit results and Cobertura coverage are
uploaded as build artifacts.
