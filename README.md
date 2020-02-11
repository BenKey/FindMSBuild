# FindMSBuild

Script files used for locating MSBuild even when it is not in the path. These script files can be used as part of a build process.

# Algorithm Details

The FindMSBuild function uses the following algorithm.

1. It first attempts to locate MSBuild using the [PATH environment variable][].
2. If MSBuild was not located using the [PATH environment variable][], it attempts to locate MSBuild using the [vswhere][] tool.
3. If MSBuild was not located using [vswhere][], it attempts to locate MSBuild using the HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions system registry key.

This algorithm is implemented in the following functions.

* FindVSWhere
  This helper function attempts to locate vswhere.exe. It is used by the [FindMSBuildUsingVSWhere][] function.
* FindMSBuildInPath
  This function attempts to locate MSBuild using the [PATH environment variable][].
* FindMSBuildUsingVSWhere
  This function first uses the [FindVSWhere][] function to locate vswhere.exe. If the [FindVSWhere][] function is successful, it uses vswhere.exe to locate MSBuild.
* FindMSBuildUsingRegistry
  This function attempts to locate MSBuild using the HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions system registry key.
* FindMSBuild
  The main function that implements the algorithm.

# Implementations

## FindMSBuild.bat

This is a Windows Batch file implementation of FindMSBuild. If successful, it sets the MSBuild environment variable.

To use FindMSBuild.bat from your own batch file, simply place FindMSBuild.bat in the same directory as your batch file and add the following lines to your batch file.

````
call FindMSBuild.bat
if not defined MSBuild goto :EOF
````

Then add code that relies on the MSBuild environment variable.

## FindMSBuild.ps1

This is a Windows PowerShell implementation of FindMSBuild. If successful, it sets the MSBuild environment variable.

To use FindMSBuild.ps1, simply place FindMSBuild.ps1 in the same directory as your PowerShell script and add the following line to your file.

````
. "$PSScriptRoot\FindMSBuild.ps1"
````

Then call the FindMSBuild function as you would any other function.

[PATH environment variable]: <https://en.wikipedia.org/wiki/PATH_(variable)>
[vswhere]: <https://github.com/microsoft/vswhere>
