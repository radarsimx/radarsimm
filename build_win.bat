@ECHO OFF

set LICENSE=off
set ARCH=cpu

goto GETOPTS

:Help
ECHO:
ECHO Usages:
ECHO    --help      Show the usages of the parameters
ECHO    --license   Enable license verification, choose 'on' or 'off'. Default is 'off'
ECHO    --arch      Build architecture, choose 'cpu' or 'gpu'. Default is 'cpu'
ECHO:
goto EOF

:GETOPTS
if /I "%1" == "--help" goto Help
if /I "%1" == "--license" set LICENSE=%2 & shift
if /I "%1" == "--arch" set ARCH=%2 & shift
shift
if not "%1" == "" goto GETOPTS

if /I NOT %LICENSE% == on (
    if /I NOT %LICENSE% == off (
        ECHO ERROR: Invalid --license parameters, please choose 'on' or 'off'
        goto EOF
    )
)

if /I NOT %ARCH% == cpu (
    if /I NOT %ARCH% == gpu (
        ECHO ERROR: Invalid --arch parameters, please choose 'cpu' or 'gpu'
        goto EOF
    )
)

ECHO Automatic build script of radarsimlib for Windows
ECHO:
ECHO ----------
ECHO Copyright (C) 2023 - PRESENT  radarsimx.com
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

CD ".\radarsimlib"

if /I %ARCH% == gpu (
    ECHO [Build GPU version - license=%LICENSE%]
    SET package_path=".\radarsimm_win_x86_64_gpu"
    SET lib_path=".\radarsimlib\radarsimlib_win_x86_64_gpu\radarsimlib"
    CALL build.bat --arch gpu --license %LICENSE%
) else if /I %ARCH% == cpu (
    ECHO [Build CPU version - license=%LICENSE%]
    SET package_path=".\radarsimm_win_x86_64_cpu"
    SET lib_path=".\radarsimlib\radarsimlib_win_x86_64_cpu\radarsimlib"
    CALL build.bat --arch cpu --license %LICENSE%
)

CD ..

RMDIR /Q/S %package_path%
MD %package_path%
XCOPY /E /Y .\src\ %package_path%\
XCOPY /E /Y .\examples\ %package_path%\
XCOPY /E /Y .\models\ %package_path%\models\
XCOPY /E /Y %lib_path%\* %package_path%\+RadarSim\

ECHO [Build completed]
