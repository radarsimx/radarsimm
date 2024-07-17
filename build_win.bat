@ECHO OFF

set TIER=standard
set ARCH=cpu

goto GETOPTS

:Help
ECHO:
ECHO Usages:
ECHO    --help	Show the usages of the parameters
ECHO    --tier	Build tier, choose 'standard' or 'free'. Default is 'standard'
ECHO    --arch	Build architecture, choose 'cpu' or 'gpu'. Default is 'cpu'
ECHO:
goto EOF

:GETOPTS
if /I "%1" == "--help" goto Help
if /I "%1" == "--tier" set TIER=%2 & shift
if /I "%1" == "--arch" set ARCH=%2 & shift
shift
if not "%1" == "" goto GETOPTS

if /I NOT %TIER% == free (
    if /I NOT %TIER% == standard (
        ECHO ERROR: Invalid --tier parameters, please choose 'free' or 'standard'
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
    if /I %TIER% == standard (
        ECHO ## Build standard GPU verion ##
        SET package_path=".\radarsimm_win_x86_64_gpu"
        SET lib_path=".\radarsimlib\radarsimlib_win_x86_64_gpu"
        CALL build_win.bat --arch gpu --tier standard
    ) else if /I %TIER% == free (
        ECHO ## Build freetier GPU verion ##
        SET package_path=".\radarsimm_win_x86_64_gpu_free"
        SET lib_path=".\radarsimlib\radarsimlib_win_x86_64_gpu_free"
        CALL build_win.bat --arch gpu --tier free
    )
) else if /I %ARCH% == cpu (
    if /I %TIER% == standard (
        ECHO ## Build standard CPU verion ##
        SET package_path=".\radarsimm_win_x86_64_cpu"
        SET lib_path=".\radarsimlib\radarsimlib_win_x86_64_cpu"
        CALL build_win.bat --arch cpu --tier standard
    ) else if /I %TIER% == free (
        ECHO ## Build freetier CPU verion ##
        SET package_path=".\radarsimm_win_x86_64_cpu_free"
        SET lib_path=".\radarsimlib\radarsimlib_win_x86_64_cpu_free"
        CALL build_win.bat --arch cpu --tier free
    )
)

CD ..

RMDIR /Q/S %package_path%
MD %package_path%
XCOPY /E /Y .\src\ %package_path%\src\
XCOPY /E /Y .\examples\ %package_path%\examples\
XCOPY /E /Y .\models\ %package_path%\models\
XCOPY /Y LICENSE %package_path%\
XCOPY /Y README.md %package_path%\
XCOPY /E /Y %lib_path%\* %package_path%\src\

ECHO ## Build completed ##
