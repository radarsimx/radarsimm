# RadarSimM Build Instructions

## Prerequisites for All Platforms

- CMake 3.20 or higher
- C++ compiler with C++20 support

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
