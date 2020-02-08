@echo off

call :FindMSBuild MSBuild
echo MSBuild  found at '%MSBuild%'.

goto :EOF

:GetDirName
	setlocal
	set _DirName=%~dp1
	set _DirName=%_DirName:~0,-1%
	endlocal & set %2=%_DirName%
	exit /B 0
GOTO :EOF

:FindVSWhere
	setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
	set _vswhere=
	set _InstallDir=
	set _regView=
	if "%PROCESSOR_ARCHITECTURE%"=="x86" (
		if "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
			set _regView=/reg:64
		)
	)
	set setupRegKey=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\VisualStudio\Setup
	for /F "skip=2 tokens=2,*" %%D IN ('reg query %setupRegKey% /v SharedInstallationPath %_regView% 2^>nul') do set _InstallDir=%%E
	if defined _InstallDir goto :foundInstallDir
	goto :noInstallDir
	:foundInstallDir
	call :GetDirName "%_InstallDir%" _vswhere
	set _vswhere=%_vswhere%\Installer\vswhere.exe
	if exist "%_vswhere%" goto :foundVSWhere
	:noInstallDir
	set _vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe
	if exist "%_vswhere%" goto :foundVSWhere
	set _vswhere=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe
	if exist "%_vswhere%" goto :foundVSWhere
	for %%f in (vswhere.exe) do set _vswhere=%%~$PATH:f
	if exist "%_vswhere%" goto :foundVSWhere
	exit /b 1
	:foundVSWhere
	endlocal & set %1=%_vswhere%
	exit /B 0
GOTO :EOF

:FindMSBuildInPath
    setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    for %%f in (MSBuild.exe) do (
        set _MSBuild=%%~$PATH:f
    )    
    endlocal & set %1=%_MSBuild%
    exit /b 0
goto :EOF

@echo off

:FindMSBuildUsingVSWhere
    setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    call :FindVSWhere _vswhere
    if not defined _vswhere goto :FindMSBuildUsingVSWhereFailed
	set _MSBuild=
	for /f "usebackq tokens=*" %%i in (`"%_vswhere%" -latest -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do set _MSBuild=%%i
	if not defined _MSBuild goto :FindMSBuildUsingVSWhereFailed
    endlocal & set %1=%_MSBuild%
    exit /b 0
	:FindMSBuildUsingVSWhereFailed
	endlocal
	exit /b 1
goto :EOF

:FindMSBuildUsingRegistry
    setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
	set _MSBuild=
	for %%v in (2.0, 3.5, 4.0, 12.0, 14.0) do (
		for /F "skip=2 tokens=2,*" %%D IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\%%v" /v MSBuildToolsPath 2^>nul') do (
			set _MSBuild=%%EMSBuild.exe
		)
	)
    endlocal & set %1=%_MSBuild%
    exit /b 0
goto :EOF

:FindMSBuild
    setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    call :FindMSBuildInPath _MSBuild
    if not defined _MSBuild call :FindMSBuildUsingVSWhere _MSBuild
    if not defined _MSBuild call :FindMSBuildUsingRegistry _MSBuild
    if not defined _MSBuild endlocal & exit /B 1
    endlocal & set %1=%_MSBuild%
    exit /b 0
goto :EOF
