# ---------------------------------------------------------
# GLOBAL ERROR HANDLING – ALLE FEHLER AUTOMATISCH INS LOG
# ---------------------------------------------------------

# Alle Fehler als "terminierend" behandeln
$ErrorActionPreference = "Stop"
$Global:PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Globaler Fehler-Logger
Register-EngineEvent PowerShell.OnScriptError -Action {
    $msg = $_.SourceArgs[0].Exception.Message
    Write-Log -Level "ERROR" -Message "PowerShell-Fehler: $msg"
} | Out-Null


# ---------------------------------------------------------
# Modul laden & Logging starten
# ---------------------------------------------------------

$modulePath = "C:\Users\Public\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"
Write-Log -Level INFO -Message "=== Software-Inventur gestartet ==="


# ---------------------------------------------------------
# Registry-Pfade für klassische Programme
# ---------------------------------------------------------

$classicPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)


# ---------------------------------------------------------
# Funktion: Klassische Programme aus Registry lesen
# ---------------------------------------------------------

function Get-InstalledPrograms {
    param([string]$RegistryPath)

    try {
        if (Test-Path $RegistryPath) {
            Get-ChildItem $RegistryPath | ForEach-Object {
                try {
                    $props = Get-ItemProperty $_.PsPath
                    if ($props.DisplayName) {
                        [PSCustomObject]@{
                            Name        = $props.DisplayName
                            Version     = $props.DisplayVersion
                            Publisher   = $props.Publisher
                            InstallDate = $props.InstallDate
                        }
                    }
                }
                catch {
                    Write-Log -Level ERROR -Message "Fehler beim Lesen eines Registry-Eintrags: $($_.Exception.Message)"
                }
            }
        }
        else {
            Write-Log -Level WARN -Message "Registry-Pfad nicht gefunden: $RegistryPath"
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler beim Auslesen des Registry-Pfads $RegistryPath: $($_.Exception.Message)"
    }
}


# ---------------------------------------------------------
# KLASSISCHE PROGRAMME
# ---------------------------------------------------------

Write-Log -Level INFO -Message "=== Klassische Programme ==="

try {
    $classicApps = foreach ($path in $classicPaths) {
        Get-InstalledPrograms -RegistryPath $path
    }

    if (-not $classicApps -or $classicApps.Count -eq 0) {
        Write-Log -Level WARN -Message "Keine klassischen Programme gefunden."
    }
    else {
        foreach ($app in $classicApps | Sort-Object Name) {
            Write-Log -Level INFO -Message "Programm: $($app.Name) | Version: $($app.Version) | Publisher: $($app.Publisher)"
        }
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Auslesen klassischer Programme: $($_.Exception.Message)"
}


# ---------------------------------------------------------
# UWP / STORE APPS
# ---------------------------------------------------------

Write-Log -Level INFO -Message "=== UWP / Store Apps ==="

try {
    $uwpApps = Get-AppxPackage |
        Select-Object Name, Version, Publisher |
        Sort-Object Name

    foreach ($app in $uwpApps) {
        Write-Log -Level INFO -Message "UWP-App: $($app.Name) | Version: $($app.Version) | Publisher: $($app.Publisher)"
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Auslesen der UWP-Apps: $($_.Exception.Message)"
}


# ---------------------------------------------------------
# FERTIG
# ---------------------------------------------------------

Write-Log -Level INFO -Message "=== Software-Inventur abgeschlossen ==="