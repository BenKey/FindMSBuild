<#
.SYNOPSIS
Finds MSBuild.exe and returns the path to the found file.

.DESCRIPTION
Finds MSBuild.exe and returns the path to the found file. Use one of the following techniques to find the file.

* Searches for the file on the PATH.

* Searches for the file using VSWhere.

* Searches for the file using information found in the "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions" registry key.

.NOTES

This script has the following side effects.

* It sets the $MSBuild variable to the value returned by the Find-MSBuild function.

* It sets the MSBuild environment variable to the value returned by the Find-MSBuild function.
#>


function GetRegistryValue($regKey, $valueName, $defaultValue) {
    $keyExists = Test-Path $regKey
    if (-NOT $keyExists) {
        return $defaultValue
    }
    $hasValue = Get-ItemProperty -Path $regkey -Name $valueName -ErrorAction SilentlyContinue
    If (($hasValue -eq $null) -or ($hasValue.Length -eq 0)) {
        return $defaultValue
    }
    return Get-ItemPropertyValue -Path $regKey -Name $valueName
}

function FindVSWhere {
    $regKey = "HKLM:\SOFTWARE\Microsoft\VisualStudio\Setup"
    $valueName = "SharedInstallationPath"
    $installDir = GetRegistryValue $regKey $valueName $null
    if ($installDir -ne $null) {
        $installDir = Split-Path -Path $installDir -Parent
        $vswhere = Join-Path -Path $installDir -ChildPath "Installer\vswhere.exe"
        if (Test-Path $vswhere -PathType Leaf) {
            return $vswhere
        }
    }
    $vswhere = "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere -PathType Leaf) {
        return $vswhere
    }
    $vswhere = "${Env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere -PathType Leaf) {
        return $vswhere
    }
    $command = Get-Command "vswhere.exe" -ErrorAction SilentlyContinue
    if ($command -ne $null) {
        $vswhere = $command.Path
        return $vswhere
    }
    return $null
}

function FindMSBuildInPath {
    $command = Get-Command "MSBuild.exe" -ErrorAction SilentlyContinue
    if ($command -ne $null) {
        $MSBuild = $command.Path
        return $MSBuild
    }
    return $null
}

function FindMSBuildUsingVSWhere {
    $vswhere = FindVSWhere
    if ($command -eq $null) {
        return $null
    }
    $path = & "$vswhere" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1
    return $path
}

function FindMSBuildUsingRegistry {
    $MSBuild = $null
    $versions = "2.0", "3.5", "4.0", "12.0", "14.0"
    foreach ($version in $versions) {
        $regKey = "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$version"
        $valueName = "MSBuildToolsPath"
        $MSBuildToolsPath = GetRegistryValue $regKey $valueName $null
        if ($MSBuildToolsPath -ne $null) {
            $MSBuild = Join-Path -Path $MSBuildToolsPath -ChildPath "MSBuild.exe"
        }
    }
    return $MSBuild
}

function Find-MSBuild {
    $MSBuild = FindMSBuildInPath
    if ($MSBuild -ne $null) {
        return $MSBuild
    }
    $MSBuild = FindMSBuildUsingVSWhere
    if ($MSBuild -ne $null) {
        return $MSBuild
    }
    $MSBuild = FindMSBuildUsingRegistry
    return $MSBuild
}

$MSBuild = Find-MSBuild
if ($MSBuild -eq $null) {
    Write-Host "MSBuild Not Found."
}
Write-Host "MSBuild found at '$MSBuild'."
Set-Item -Path Env:MSBuild -Value $MSBuild
