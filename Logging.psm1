# Globale Variablen
$Global:LogFilePath = $null
$Global:LogLevel = "INFO"
$Global:EnableConsoleOutput = $true
$Global:MaxLogSizeMB = 5
$Global:DefaultLogFolder = "C:\Users\Public\10020115_WinScripts\Logs"

function Initialize-Logger {
    param(
        [ValidateSet("DEBUG","INFO","WARN","ERROR")]
        [string]$Level = "INFO",

        [bool]$ConsoleOutput = $true,

        [int]$MaxSizeMB = 5
    )

    # Sicherstellen, dass der Ordner existiert
    if (-not (Test-Path $Global:DefaultLogFolder)) {
        New-Item -Path $Global:DefaultLogFolder -ItemType Directory -Force | Out-Null
    }

    # Tagesbasierter Dateiname
    $date = Get-Date -Format "yyyy-MM-dd"
    $FileName = "log_$date.log"

    # Logdatei zusammensetzen
    $Path = Join-Path $Global:DefaultLogFolder $FileName

    # Datei erstellen falls nötig
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType File -Force | Out-Null
    }

    # Globale Variablen setzen
    $Global:LogFilePath = $Path
    $Global:LogLevel = $Level
    $Global:EnableConsoleOutput = $ConsoleOutput
    $Global:MaxLogSizeMB = $MaxSizeMB

    Write-Log -Level "INFO" -Message "Logger initialisiert. Logfile: $Path"
}

function Rotate-Log {
    if (-not (Test-Path $LogFilePath)) { return }

    # Größenrotation
    $sizeMB = (Get-Item $LogFilePath).Length / 1MB
    if ($sizeMB -ge $Global:MaxLogSizeMB) {
        $timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
        $archivePath = "$LogFilePath.$timestamp.bak"
        Move-Item -Path $LogFilePath -Destination $archivePath -Force
        New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
    }

    # Tagesrotation
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $expectedFile = Join-Path $Global:DefaultLogFolder "log_$currentDate.log"

    if ($expectedFile -ne $Global:LogFilePath) {
        $Global:LogFilePath = $expectedFile
        if (-not (Test-Path $expectedFile)) {
            New-Item -Path $expectedFile -ItemType File -Force | Out-Null
        }
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("DEBUG","INFO","WARN","ERROR")]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    # Log-Level-Filter
    $levels = @{ DEBUG = 1; INFO = 2; WARN = 3; ERROR = 4 }
    if ($levels[$Level] -lt $levels[$Global:LogLevel]) { return }

    Rotate-Log

    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp] [$Level] $Message"

    Add-Content -Path $Global:LogFilePath -Value $entry

    if ($Global:EnableConsoleOutput) {
        switch ($Level) {
            "ERROR" { Write-Host $entry -ForegroundColor Red }
            "WARN"  { Write-Host $entry -ForegroundColor Yellow }
            "INFO"  { Write-Host $entry -ForegroundColor Cyan }
            "DEBUG" { Write-Host $entry -ForegroundColor DarkGray }
        }
    }
}

function Get-LogConfig {
    [PSCustomObject]@{
        LogFilePath     = $Global:LogFilePath
        LogLevel        = $Global:LogLevel
        ConsoleOutput   = $Global:EnableConsoleOutput
        MaxLogSizeMB    = $Global:MaxLogSizeMB
        DefaultFolder   = $Global:DefaultLogFolder
    }
}