param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("check-tools", "probe", "configure", "build", "flash", "reset", "serial-test")]
    [string]$Action,

    [int]$Seconds = 5
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$ConfigPath = Join-Path $Root "template.config.json"

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Missing template config: $ConfigPath"
}

$Config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json

function Get-StringValue {
    param([object]$Value)
    if ($null -eq $Value) {
        return ""
    }
    return [string]$Value
}

function Get-StringArray {
    param([object]$Value)
    if ($null -eq $Value) {
        return @()
    }
    return @($Value) | ForEach-Object { [string]$_ }
}

function Enable-ConfiguredToolchain {
    $ToolchainBin = Get-StringValue $Config.armToolchainBin
    if ([string]::IsNullOrWhiteSpace($ToolchainBin)) {
        $ToolchainBin = Get-StringValue $env:ARM_GNU_TOOLCHAIN_BIN
    }

    if (-not [string]::IsNullOrWhiteSpace($ToolchainBin)) {
        $Resolved = Resolve-Path -LiteralPath $ToolchainBin
        $env:ARM_GNU_TOOLCHAIN_BIN = $Resolved.Path
        $env:PATH = $Resolved.Path + [System.IO.Path]::PathSeparator + $env:PATH
    }
}

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [string[]]$ArgumentList = @()
    )

    Write-Host "> $FilePath $($ArgumentList -join ' ')"
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $FilePath"
    }
}

function Get-ElfPath {
    $ProjectName = Get-StringValue $Config.projectName
    $Preset = Get-StringValue $Config.buildPreset
    return Join-Path $Root "build\$Preset\$ProjectName.elf"
}

function Invoke-PyOCD {
    param([string[]]$ArgumentList)
    $env:PYTHONIOENCODING = "utf-8"
    $PyOCD = Get-StringValue $Config.pyocdPath
    Invoke-External -FilePath $PyOCD -ArgumentList $ArgumentList
}

Enable-ConfiguredToolchain

$CMake = Get-StringValue $Config.cmakePath
$Preset = Get-StringValue $Config.buildPreset
$PyOCDTarget = Get-StringValue $Config.pyocdTarget
$PyOCDOptions = Get-StringArray $Config.pyocdOptions

switch ($Action) {
    "check-tools" {
        Invoke-External -FilePath $CMake -ArgumentList @("--version")
        Invoke-External -FilePath "ninja" -ArgumentList @("--version")
        Invoke-External -FilePath "arm-none-eabi-gcc" -ArgumentList @("--version")
        Invoke-External -FilePath "arm-none-eabi-gdb" -ArgumentList @("--version")
        Invoke-External -FilePath "python" -ArgumentList @("--version")
        Invoke-PyOCD -ArgumentList @("--version")
    }
    "probe" {
        Invoke-PyOCD -ArgumentList @("list", "--targets", "--name", $PyOCDTarget)
        Invoke-PyOCD -ArgumentList (@("list", "--probes") + $PyOCDOptions)
    }
    "configure" {
        Invoke-External -FilePath $CMake -ArgumentList @("--preset", $Preset)
    }
    "build" {
        Invoke-External -FilePath $CMake -ArgumentList @("--build", "--preset", $Preset)
    }
    "flash" {
        $ElfPath = Get-ElfPath
        if (-not (Test-Path -LiteralPath $ElfPath)) {
            throw "ELF file not found: $ElfPath"
        }
        Invoke-PyOCD -ArgumentList (@("flash") + $PyOCDOptions + @("--target", $PyOCDTarget, $ElfPath))
    }
    "reset" {
        Invoke-PyOCD -ArgumentList (@("reset") + $PyOCDOptions + @("--target", $PyOCDTarget))
    }
    "serial-test" {
        $Serial = $Config.serial
        $PortName = Get-StringValue $Serial.port
        $BaudRate = [int]$Serial.baudRate
        $DataBits = [int]$Serial.dataBits
        $Parity = [Enum]::Parse([System.IO.Ports.Parity], (Get-StringValue $Serial.parity), $true)
        $StopBits = [Enum]::Parse([System.IO.Ports.StopBits], (Get-StringValue $Serial.stopBits), $true)

        $Port = [System.IO.Ports.SerialPort]::new($PortName, $BaudRate, $Parity, $DataBits, $StopBits)
        $Port.ReadTimeout = 500
        try {
            try {
                $Port.Open()
            }
            catch [System.UnauthorizedAccessException] {
                throw "Cannot open $PortName. The serial port is probably open in another terminal, VS Code Serial Monitor, or another tool."
            }
            $Deadline = (Get-Date).AddSeconds($Seconds)
            $Text = ""
            while ((Get-Date) -lt $Deadline) {
                $Chunk = $Port.ReadExisting()
                if ($Chunk.Length -gt 0) {
                    $Text += $Chunk
                }
                Start-Sleep -Milliseconds 100
            }
            $Text
        }
        finally {
            if ($Port.IsOpen) {
                $Port.Close()
            }
        }
    }
}
