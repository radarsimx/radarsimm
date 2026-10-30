@ECHO OFF
SETLOCAL

REM Packages RadarSimM for Windows from a radarsimlib GitHub release:
REM https://github.com/radarsimx/radarsimlib/releases
REM
REM radarsimlib publishes GPU builds only. They fall back to the CPU at runtime
REM when no usable CUDA device is present, so the package serves both.

set VERSION=

goto GETOPTS

:Help
ECHO:
ECHO Usages:
ECHO    --help      Show the usages of the parameters
ECHO    --version   radarsimlib release tag, e.g. v15.6.0.
ECHO                Default is the tag in .github\radarsimlib-version
ECHO:
goto EOF

:GETOPTS
if /I "%~1" == "--help" goto Help
if /I "%~1" == "--version" set "VERSION=%~2" & shift
shift
if not "%~1" == "" goto GETOPTS

if "%VERSION%" == "" (
    if not exist ".github\radarsimlib-version" (
        ECHO ERROR: .github\radarsimlib-version not found, pass --version
        exit /b 1
    )
    set /p VERSION=<".github\radarsimlib-version"
)
REM Drop any stray whitespace read from the version file.
set "VERSION=%VERSION: =%"

ECHO Automatic packaging script of RadarSimM for Windows
ECHO:
ECHO ----------
ECHO Copyright (C) 2023 - PRESENT  RadarSimX LLC
ECHO E-mail: info@radarsimx.com
ECHO Website: https://radarsimx.com
ECHO:
ECHO  ######                               #####           #     #
ECHO  #     #   ##   #####    ##   #####  #     # # #    #  #   #
ECHO  #     #  #  #  #    #  #  #  #    # #       # ##  ##   # #
ECHO  ######  #    # #    # #    # #    #  #####  # # ## #    #
ECHO  #   #   ###### #    # ###### #####        # # #    #   # #
ECHO  #    #  #    # #    # #    # #   #  #     # # #    #  #   #
ECHO  #     # #    # #####  #    # #    #  #####  # #    # #     #
ECHO:

set "ASSET=radarsimlib_%VERSION%_Windows_x86_64_GPU.zip"
set "URL=https://github.com/radarsimx/radarsimlib/releases/download/%VERSION%/%ASSET%"
set "WORK=.\radarsimlib_release"
set "PACKAGE=.\radarsimm_win_x86_64_gpu"

ECHO [Download radarsimlib %VERSION%]
ECHO %URL%

if exist "%WORK%" RMDIR /Q /S "%WORK%"
MD "%WORK%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%URL%' -OutFile '%WORK%\%ASSET%'; Expand-Archive -Path '%WORK%\%ASSET%' -DestinationPath '%WORK%' -Force"
if errorlevel 1 (
    ECHO ERROR: Failed to download or extract %ASSET%
    exit /b 1
)

set "LIB_DIR="
for /r "%WORK%" %%F in (radarsimc.dll) do if exist "%%F" set "LIB_DIR=%%~dpF"
if "%LIB_DIR%" == "" (
    ECHO ERROR: radarsimc.dll not found in %ASSET%
    exit /b 1
)
if not exist "%LIB_DIR%radarsim.h" (
    ECHO ERROR: radarsim.h not found next to radarsimc.dll in %ASSET%
    exit /b 1
)

ECHO [Assemble %PACKAGE%]

if exist "%PACKAGE%" RMDIR /Q /S "%PACKAGE%"
MD "%PACKAGE%"
XCOPY /E /Y /Q ".\src\*" "%PACKAGE%\" >NUL
if errorlevel 1 exit /b 1
XCOPY /Y /Q "%LIB_DIR%*" "%PACKAGE%\+RadarSim\" >NUL
if errorlevel 1 exit /b 1

RMDIR /Q /S "%WORK%"

ECHO [Package completed: %PACKAGE%]

:EOF
