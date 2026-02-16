# ================================
# WATCHDOG MIT LOGGER
# ================================

# Basisverzeichnis des Watchdogs
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Pfad zum PowerShell-Modul
$ModulePath = Join-Path $Root "PowerShell\Logging.psm1"

# Modul laden
$modulePath = "C:\Program Files\10020115_WinScripts\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"

Write-Log -Level "INFO" -Message "WatchDog gestartet."
Write-Log -Level "INFO" -Message "Arbeitsverzeichnis: $Root"


# ------------------------------------------------------------
# 1. ImportScript ausführen
# ------------------------------------------------------------
$ImportScript = Join-Path $Root "10020115_Win_S_ImportScript.ps1"

if (Test-Path $ImportScript) {
    Write-Log -Level "INFO" -Message "Starte ImportScript: $ImportScript"
    powershell.exe -ExecutionPolicy Bypass -File $ImportScript -Wait
    Write-Log -Level "INFO" -Message "ImportScript abgeschlossen."
} else {
    Write-Log -Level "ERROR" -Message "ImportScript nicht gefunden: $ImportScript"
}


# ------------------------------------------------------------
# 2. Richtlinien-Skripte (10020115_Win_R_...) ausführen
# ------------------------------------------------------------
$RichtlinienPfad = Join-Path $Root "PowerShell\Richtlinien"
Write-Log -Level "INFO" -Message "Suche Richtlinien-Skripte in: $RichtlinienPfad"

$Richtlinien = Get-ChildItem -Path $RichtlinienPfad -Filter "10020115_Win_R_*.ps1"

if ($Richtlinien.Count -gt 0) {
    foreach ($Script in $Richtlinien) {
        Write-Log -Level "INFO" -Message "Starte Richtlinien-Script: $($Script.FullName)"
        try {
            powershell.exe -ExecutionPolicy Bypass -File $Script.FullName -Wait
            Write-Log -Level "INFO" -Message "Fertig: $($Script.Name)"
        }
        catch {
            Write-Log -Level "ERROR" -Message "Fehler in $($Script.Name): $_"
        }
    }
} else {
    Write-Log -Level "WARN" -Message "Keine Richtlinien-Skripte gefunden."
}


# ------------------------------------------------------------
# 3. Log-Script ausführen
# ------------------------------------------------------------
$LogScript = Join-Path $Root "PowerShell\Programme\10020115_Win_Log_Software.ps1"

if (Test-Path $LogScript) {
    Write-Log -Level "INFO" -Message "Starte Log-Script: $LogScript"
    powershell.exe -ExecutionPolicy Bypass -File $LogScript -Wait
    Write-Log -Level "INFO" -Message "Log-Script abgeschlossen."
} else {
    Write-Log -Level "ERROR" -Message "Log-Script nicht gefunden: $LogScript"
}


# ------------------------------------------------------------
# 4. ListApps-Script ausführen
# ------------------------------------------------------------
$ListApps = Join-Path $Root "PowerShell\InstallSoftware\10020115_Win_A_ListApps.ps1"

if (Test-Path $ListApps) {
    Write-Log -Level "INFO" -Message "Starte ListApps-Script: $ListApps"
    powershell.exe -ExecutionPolicy Bypass -File $ListApps -Wait
    Write-Log -Level "INFO" -Message "ListApps-Script abgeschlossen."
} else {
    Write-Log -Level "ERROR" -Message "ListApps-Script nicht gefunden: $ListApps"
}


# ------------------------------------------------------------
# WatchDog Ende
# ------------------------------------------------------------
Write-Log -Level "INFO" -Message "WatchDog abgeschlossen."