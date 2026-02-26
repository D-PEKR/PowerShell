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
Write-Log -Level INFO -Message "Starte PIN-Komplexität GPOs"


# ---------------------------------------------------------
# Registry-Pfad erstellen
# ---------------------------------------------------------

$RegPIN = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"

try {
    New-Item $RegPIN -Force | Out-Null
    Write-Log -Level INFO -Message "Registry-Pfad erstellt: $RegPIN"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Erstellen des Registry-Pfads: $($_.Exception.Message)"
}


# ---------------------------------------------------------
# PIN-Komplexität setzen
# ---------------------------------------------------------

try {
    Set-ItemProperty -Path $RegPIN -Name "Digits" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPIN -Name "LowercaseLetters" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPIN -Name "UppercaseLetters" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPIN -Name "SpecialCharacters" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPIN -Name "MinimumPINLength" -Value 8 -Type DWord
    Set-ItemProperty -Path $RegPIN -Name "Expiration" -Value 180 -Type DWord

    Write-Log -Level INFO -Message "GPO gesetzt: PIN-Komplexität vollständig angewendet"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen der PIN-Komplexität: $($_.Exception.Message)"
}


# ---------------------------------------------------------
# Fertig
# ---------------------------------------------------------

Write-Log -Level INFO -Message "PIN-Komplexität GPO-Konfiguration abgeschlossen"