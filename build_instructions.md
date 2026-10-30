# RadarSimM Build Instructions

RadarSimM is the MATLAB interface to `radarsimc`, the C library built in
[`radarsimx/radarsimlib`](https://github.com/radarsimx/radarsimlib). RadarSimM
does not compile it: a package is the MATLAB code in `src/` plus a prebuilt
library from a
[radarsimlib release](https://github.com/radarsimx/radarsimlib/releases).

The release used by the scripts and GitHub Actions workflows is pinned in
[`.github/radarsimlib-version`](.github/radarsimlib-version).

## Project Structure

```text
radarsimm/
├── .github/
│   ├── radarsimlib-version               # Pinned radarsimlib release tag
│   └── workflows/                        # CI and release workflows
├── assets/                               # Documentation assets and images
├── docs/                                 # Documentation site
├── src/                                  # MATLAB interface (+RadarSim package, examples, models)
├── tests/                                # Unit and integration tests
├── build_win.bat                         # Windows packaging script
├── build_instructions.md                 # This file
└── README.md                             # Project documentation
```

## Release Builds

radarsimlib publishes GPU (CUDA) builds only. They use an NVIDIA GPU when one is
available and fall back to the CPU otherwise, so the same package serves both
kinds of machine.

| Platform | Release asset |
|---|---|
| Windows x86_64 | `radarsimlib_<tag>_Windows_x86_64_GPU.zip` |
| Ubuntu 22.04 x86_64 | `radarsimlib_<tag>_Ubuntu22_x86_64_GPU.zip` |
| Ubuntu 24.04 x86_64 | `radarsimlib_<tag>_Ubuntu24_x86_64_GPU.zip` |
| Ubuntu 26.04 x86_64 | `radarsimlib_<tag>_Ubuntu26_x86_64_GPU.zip` |

## Windows

```batch
REM Package the release pinned in .github\radarsimlib-version
build_win.bat

REM Or a specific release
build_win.bat --version v15.6.0
```

The script downloads the release asset, extracts it, and assembles the package
in `radarsimm_win_x86_64_gpu`: the contents of `src/` with `radarsimc.dll`,
`radarsimc.lib` and `radarsim.h` in `+RadarSim`.

## Linux

Download the Ubuntu asset matching your system from the release, then:

1. Copy the contents of `src/` into a new package directory.
2. Copy `libradarsimc.so` into `+RadarSim` as `radarsimc.so` (MATLAB's
   `loadlibrary` appends the extension to the name the package passes it).
3. Copy `radarsim.h` into `+RadarSim` with the
   `__attribute__((visibility("default")))` markers removed, which
   `loadlibrary` cannot parse:

   ```bash
   sed 's/__attribute__((visibility("default")))//g' radarsim.h > <package>/+RadarSim/radarsim.h
   ```

The [`Build Linux Libraries`](.github/workflows/release-linux.yml) workflow does
exactly this for every Ubuntu build in the release.

## Building radarsimlib from source

To build the library yourself, follow the instructions in the
[radarsimlib repository](https://github.com/radarsimx/radarsimlib) and place
the resulting library and `radarsim.h` in `src/+RadarSim` as described above.
