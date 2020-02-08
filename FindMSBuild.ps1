function Get-RegistryValue($regKey, $valueName, $defaultValue) {
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
    $installDir = Get-RegistryValue $regKey $valueName $null
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
    $path = & "$vswhere" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1
    return $path
}

function FindMSBuildUsingRegistry {
    $MSBuild = $null
    $versions = "2.0", "3.5", "4.0", "12.0", "14.0"
    foreach ($version in $versions) {
        $regKey = "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$version"
        $valueName = "MSBuildToolsPath"
        $MSBuildToolsPath = Get-RegistryValue $regKey $valueName $null
        if ($MSBuildToolsPath -ne $null) {
            $MSBuild = Join-Path -Path $MSBuildToolsPath -ChildPath "MSBuild.exe"
        }
    }
    return $MSBuild
}

function FindMSBuild {
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

$MSBuild = FindMSBuild
if ($MSBuild -eq $null) {
    Write-Host "MSBuild Not Found."
}
Write-Host "MSBuild found at '$MSBuild'."
Set-Item -Path Env:MSBuild -Value $MSBuild
