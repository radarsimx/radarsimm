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

## Troubleshooting

- If CMake fails to find CUDA, ensure CUDA_PATH environment variable is set correctly
