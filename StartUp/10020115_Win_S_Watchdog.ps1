# ---------------------------------------------------------
# GLOBAL ERROR HANDLING
# ---------------------------------------------------------

$ErrorActionPreference = "Stop"
$Global:PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Globaler Fehler-Logger
Register-EngineEvent PowerShell.OnScriptError -Action {
    $msg = $_.SourceArgs[0].Exception.Message
    Write-Log -Level "ERROR" -Message "PowerShell-Fehler: $msg"
} | Out-Null


# ---------------------------------------------------------
# LOGGER – direkt integriert
# ---------------------------------------------------------

# Globale Variablen
$Global:LogFilePath = $null
$Global:LogLevel = "INFO"
$Global:EnableConsoleOutput = $true
$Global:MaxLogSizeMB = 5
$Global:DefaultLogFolder = "C:\Users\Public\10020115_WinScripts\Logs\"

function Initialize-Logger {
    param(
        [string]$FileName = "log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log",

        [ValidateSet("DEBUG","INFO","WARN","ERROR")]
        [string]$Level = "INFO",

        [bool]$ConsoleOutput = $true,

        [int]$MaxSizeMB = 5
    )

    if (-not (Test-Path $Global:DefaultLogFolder)) {
        New-Item -Path $Global:DefaultLogFolder -ItemType Directory -Force | Out-Null
    }

    $Path = Join-Path $Global:DefaultLogFolder $FileName

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType File -Force | Out-Null
    }

    $Global:LogFilePath = $Path
    $Global:LogLevel = $Level
    $Global:EnableConsoleOutput = $ConsoleOutput
    $Global:MaxLogSizeMB = $MaxSizeMB

    Write-Log -Level "INFO" -Message "Logger initialisiert. Logfile: $Path"
}

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

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("DEBUG","INFO","WARN","ERROR")]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

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

function Get-LogConfig {
    [PSCustomObject]@{
        LogFilePath     = $Global:LogFilePath
        LogLevel        = $Global:LogLevel
        ConsoleOutput   = $Global:EnableConsoleOutput
        MaxLogSizeMB    = $Global:MaxLogSizeMB
        DefaultFolder   = $Global:DefaultLogFolder
    }
}

# ---------------------------------------------------------
# Logger initialisieren
# ---------------------------------------------------------
Initialize-Logger -Level "INFO"
Write-Log -Level INFO -Message "Starte kombinierten Import- und WatchDog-Prozess."

# ---------------------------------------------------------
# 1. IMPORT-SCHRITT
# ---------------------------------------------------------

try {
    $Source = "C:\Users\DLRG-JugendAndernach\DLRG\DLRG OG Andernach Projekte-Jugendnotebooks - Jugendnotebooks\Win11_C"
    $DestinationRoot = "C:\Users\Public\10020115_WinScripts"
    $Destination = Join-Path $DestinationRoot "Win11_C"

    Write-Log -Level INFO -Message "Starte Kopiervorgang für Win11_C"
    Write-Log -Level INFO -Message "Quelle: $Source"
    Write-Log -Level INFO -Message "Ziel: $Destination"

    Write-Log -Level INFO -Message "Entferne mögliche Offline-Attribute aus Quelldateien..."
    Get-ChildItem $Source -Recurse -Force | ForEach-Object {
        attrib -P $_.FullName 2>$null
    }

    if (Test-Path $Destination) {
        Write-Log -Level INFO -Message "Lösche vorhandenen Ordner Win11_C..."
        Remove-Item -Path $Destination -Recurse -Force
        Start-Sleep -Milliseconds 300
    }

    Write-Log -Level INFO -Message "Erstelle Zielordner Win11_C..."
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    Write-Log -Level INFO -Message "Kopiere Dateien nach Win11_C..."
    Copy-Item -Path "$Source\*" -Destination $Destination -Recurse -Force

    Write-Log -Level INFO -Message "Entferne versteckte Attribute..."
    Get-ChildItem -Path $Destination -Recurse -Force | ForEach-Object {
        $_.Attributes = 'Normal'
    }
    (Get-Item $Destination).Attributes = 'Normal'

    Write-Log -Level INFO -Message "Kopiervorgang abgeschlossen."
}
catch {
    Write-Log -Level ERROR -Message "Fehler im Import-Schritt: $($_.Exception.Message)"
}

# ---------------------------------------------------------
# 2. WARTEN (60 Sekunden)
# ---------------------------------------------------------
Write-Log -Level INFO -Message "Warte 60 Sekunden, bevor WatchDog startet..."
Start-Sleep -Seconds 60

# ---------------------------------------------------------
# 3. WATCHDOG – Skripte rekursiv ausführen
# ---------------------------------------------------------

Write-Log -Level INFO -Message "WatchDog gestartet."

try {
    $ScriptRoot = "C:\Users\Public\10020115_WinScripts\Win11_C\Software\Scripte"
    Write-Log -Level INFO -Message "Suche nach Skripten in: $ScriptRoot"

    $ExcludeFile = "C:\Users\Public\10020115_WinScripts\Win11_C\Software\Scripte\StartUp\10020115_Win_S_Watchdog.ps1"

    $Scripts = Get-ChildItem -Path $ScriptRoot -Filter "*.ps1" -Recurse |
        Where-Object { $_.FullName -ne $ExcludeFile }

    if ($Scripts.Count -gt 0) {
        foreach ($Script in $Scripts) {
            Write-Log -Level "INFO" -Message "Starte Script: $($Script.FullName)"
            try {
                powershell.exe -ExecutionPolicy Bypass -File $Script.FullName -Wait
                Write-Log -Level "INFO" -Message "Fertig: $($Script.Name)"
            }
            catch {
                Write-Log -Level "ERROR" -Message "Fehler in $($Script.Name): $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Log -Level "WARN" -Message "Keine Skripte gefunden."
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler im WatchDog: $($_.Exception.Message)"
}

Write-Log -Level INFO -Message "WatchDog abgeschlossen."
Write-Log -Level INFO -Message "Gesamter Prozess beendet."