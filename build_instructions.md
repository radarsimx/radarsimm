# RadarSimM Build Instructions

## Prerequisites for All Platforms

- CMake 3.20 or higher
- C++ compiler with C++20 support

## Project Structure

The RadarSimM project is organized as follows:

```text
radarsimm/
├── assets/                               # Documentation assets and images
├── examples/                             # MATLAB example scripts
├── models/                               # 3D model files for simulation
├── radarsimlib/                          # Core C++ library (submodule)
│   ├── src/                              # C++ source code
│   │   ├── includes/                     # C API header files
│   │   │   └── radarsim.h                # Main C API header
│   │   ├── radarsimcpp/                  # C++ source code
│   │   │   ├── gtest/                    # Google Test framework
│   │   │   ├── hdf5-lib-build/           # HDF5 library build files
│   │   │   │   ├── hdf5/                 # HDF5 source code (HDF Group)
│   │   │   │   ├── libs/                 # Platform-specific precompiled libraries
│   │   │   │   │   ├── lib_linux_gcc11_x86_64/
│   │   │   │   │   ├── lib_macos_arm64/
│   │   │   │   │   ├── lib_macos_x86_64/
│   │   │   │   │   └── lib_win_x86_64/
│   │   │   │   ├── build.bat             # Windows build script
│   │   │   │   ├── build.sh              # Linux/macOS build script
│   │   │   │   └── README.md
│   │   │   ├── includes/                 # Header files
│   │   │   │   ├── libs/                 # Core library headers
│   │   │   │   └── rsvector/             # Custom vector implementations
│   │   │   ├── src/                      # C++/CUDA implementation files
│   │   │   ├── CMakeLists.txt            # CMake configuration
│   │   │   └── README.md
│   │   └── radarsim.cpp                  # C API wrapper implementation
│   ├── tests/                            # Unit tests
│   └── CMakeLists.txt                    # CMake configuration
├── src/                                  # MATLAB interface
├── build_win.bat                         # Windows build script
├── build_instructions.md                 # This file
└── README.md                             # Project documentation
```

## Windows (MSVC)

1. Install required tools:
   - [Microsoft Visual Studio 2022](https://visualstudio.microsoft.com/) with "Desktop development with C++" workload
   - [CMake](https://cmake.org/download/) (Windows x64 Installer)
   - [CUDA Toolkit 12](https://developer.nvidia.com/cuda-downloads) (Required only for GPU version)

2. Build the project:

   ```batch
   # For CPU version
   build_win.bat --arch=cpu

   # For GPU version (requires CUDA)
   build_win.bat --arch=gpu
   ```

## Build Output

The compiled module will be available in the `radarsimm_win_x86_64_cpu` or `radarsimm_win_x86_64_gpu` folder.

## Build Options

- `--arch`: Build architecture (`cpu` or `gpu`)
- `--license`: Enable license verification (`on` or `off`)
- `--deps`: Prebuilt dependency source (`repo` or `release`)

## Prebuilt Dependency Source

RadarSimCpp links third-party libraries (HDF5, and mbedTLS when license
verification is enabled) as prebuilt static libraries. They are never compiled
as part of a RadarSimM build; `--deps` only chooses where they are read from.

| `--deps` | Where the libraries come from | Network needed |
|---|---|---|
| `repo` (default) | The committed `libs/` tree in the `radarsimx-deps` submodule, reached through `radarsimlib/src/radarsimcpp/deps` | No |
| `release` | The checksum-pinned release archives published by [`radarsimx/radarsimx-deps`](https://github.com/radarsimx/radarsimx-deps), downloaded and cached under `radarsimlib/src/radarsimcpp/.deps-cache/` | Yes, on the first build |

```batch
build_win.bat --deps=release
```

`build_win.bat` forwards the setting to `radarsimlib/build.bat`; on Linux, pass
it to `radarsimlib/build.sh --deps=release` directly.

`repo` is the default because it needs no network and pins the dependencies to
the submodule commit, which makes it the right choice for local and offline
builds. The GitHub Actions workflows all pass `--deps=release`, so CI links the
same tagged, checksum-verified archives every time.

## Troubleshooting

- If CMake fails to find CUDA, ensure CUDA_PATH environment variable is set correctly
