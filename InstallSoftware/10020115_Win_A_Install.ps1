# Modul laden
$modulePath = "C:\Program Files\10020115_WinScripts\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "Install Software"
# ------------------------------------------------------------
# Funktion: Install-MSI (mit Logging)
# ------------------------------------------------------------
function Install-MSI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [string]$Arguments = "/qn /norestart"
    )

    if (-not (Test-Path $Path)) {
        Write-Log -Level "ERROR" -Message "MSI-Datei nicht gefunden: $Path"
        return
    }

    Write-Log -Level "INFO" -Message "Starte Installation: $Path"

    try {
        Start-Process "msiexec.exe" -ArgumentList "/i `"$Path`" $Arguments" -Wait -ErrorAction Stop
        Write-Log -Level "INFO" -Message "Installation erfolgreich abgeschlossen: $Path"
    }
    catch {
        Write-Log -Level "ERROR" -Message "Fehler bei Installation von $Path: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Funktion: Uninstall-MSI (mit Logging)
# ------------------------------------------------------------
function Uninstall-MSI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProductCode,

        [string]$Arguments = "/qn /norestart"
    )

    Write-Log -Level "INFO" -Message "Starte Deinstallation: $ProductCode"

    try {
        Start-Process "msiexec.exe" -ArgumentList "/x $ProductCode $Arguments" -Wait -ErrorAction Stop
        Write-Log -Level "INFO" -Message "Deinstallation erfolgreich abgeschlossen: $ProductCode"
    }
    catch {
        Write-Log -Level "ERROR" -Message "Fehler bei Deinstallation von $ProductCode: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Beispiel: Installation
# ------------------------------------------------------------
Install-MSI -Path "C:\Install\7zip.msi"
Install-MSI -Path "C:\Install\VLC.msi"

# ------------------------------------------------------------
# Beispiel: Deinstallation
# ------------------------------------------------------------
# Beispiel-GUID
# {23170F69-40C1-2702-0920-000001000000}

Uninstall-MSI -ProductCode "{23170F69-40C1-2702-0920-000001000000}"