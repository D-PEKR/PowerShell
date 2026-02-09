# Globale Variablen
$Global:LogFilePath = $null
$Global:LogLevel = "INFO"
$Global:EnableConsoleOutput = $true
$Global:MaxLogSizeMB = 5
$Global:DefaultLogFolder = "C:\Users\Debeka\IdeaProjects\PowerShell\LOGS\"

function Initialize-Logger {
    param(
        [string]$FileName = "log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log",

        [ValidateSet("DEBUG","INFO","WARN","ERROR")]
        [string]$Level = "INFO",

        [bool]$ConsoleOutput = $true,

        [int]$MaxSizeMB = 5
    )

    # Sicherstellen, dass der Ordner existiert
    if (-not (Test-Path $Global:DefaultLogFolder)) {
        New-Item -Path $Global:DefaultLogFolder -ItemType Directory -Force | Out-Null
    }

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

# Funktion: Rotate-Log
function Rotate-Log {
    if (-not (Test-Path $LogFilePath)) { return }

    $sizeMB = (Get-Item $LogFilePath).Length / 1MB

    if ($sizeMB -ge $Global:MaxLogSizeMB) {
        $timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
        $archivePath = "$LogFilePath.$timestamp.bak"

        Move-Item -Path $LogFilePath -Destination $archivePath -Force
        New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
    }
}

# Funktion: Write-Log
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
    if ($levels[$Level] -lt $levels[$Global:LogLevel]) {
        return
    }

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

# Funktion: Get-LogConfig
function Get-LogConfig {
    [PSCustomObject]@{
        LogFilePath     = $Global:LogFilePath
        LogLevel        = $Global:LogLevel
        ConsoleOutput   = $Global:EnableConsoleOutput
        MaxLogSizeMB    = $Global:MaxLogSizeMB
        DefaultFolder   = $Global:DefaultLogFolder
    }
}