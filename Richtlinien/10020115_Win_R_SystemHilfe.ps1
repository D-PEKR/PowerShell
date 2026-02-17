# ---------------------------------------------------------
# GLOBAL ERROR HANDLING
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
# Logging-Modul laden
# ---------------------------------------------------------

$modulePath = "C:\Users\Public\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"
Write-Log -Level INFO -Message "Starte OEM-Branding & Legal Notice Konfiguration"


# ---------------------------------------------------------
# 1) OEM INFORMATION (Systemeigenschaften)
# ---------------------------------------------------------

$RegOEM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"

try {
    New-Item -Path $RegOEM -Force | Out-Null
    Write-Log -Level INFO -Message "OEM-Registrypfad erstellt: $RegOEM"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Erstellen des OEM-Registry-Pfads: $($_.Exception.Message)"
}


# OEM Logo kopieren
$SourceLogo = "C:\Program Files\10020115_WinScripts\Win11_C\Bilder\Logo\OEMLogo.png"
$TargetLogo = "C:\Windows\Web\Wallpaper\OEMLogo.png"

try {
    Copy-Item -Path $SourceLogo -Destination $TargetLogo -Force
    Write-Log -Level INFO -Message "OEM-Logo erfolgreich kopiert nach $TargetLogo"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Kopieren des OEM-Logos: $($_.Exception.Message)"
}


# OEM Registry-Einträge setzen
try {
    Set-ItemProperty -Path $RegOEM -Name "Manufacturer" -Value "DLRG-Jugend Andernach | EDV & Technik"
    Set-ItemProperty -Path $RegOEM -Name "SupportHours" -Value "10-18 Uhr"
    Set-ItemProperty -Path $RegOEM -Name "SupportPhone" -Value "+49 1575 6018834"
    Set-ItemProperty -Path $RegOEM -Name "SupportURL" -Value "https://teams.microsoft.com/l/entity/0ae35b36-0fd7-422e-805b-d53af1579093/_djb2_msteams_prefix_1059335291?context=%7B%22channelId%22%3A%2219%3A65261044e15d4dcd8f67ad5676722fe7%40thread.tacv2%22%7D&tenantId=b540b637-4413-43d4-9ee2-3cba49e12e23"
    Set-ItemProperty -Path $RegOEM -Name "Logo" -Value $TargetLogo

    Write-Log -Level INFO -Message "OEM-Informationen erfolgreich gesetzt"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen der OEM-Informationen: $($_.Exception.Message)"
}


# ---------------------------------------------------------
# 2) LEGAL NOTICE (Anmeldebildschirm)
# ---------------------------------------------------------

$RegLegal = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

try {
    New-Item -Path $RegLegal -Force | Out-Null
    Write-Log -Level INFO -Message "Legal Notice Registry-Pfad erstellt"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Erstellen des Legal Notice Registry-Pfads: $($_.Exception.Message)"
}

# Texte anpassen
$LegalCaption = ""
$LegalText = ""

try {
    Set-ItemProperty -Path $RegLegal -Name "legalnoticecaption" -Value $LegalCaption
    Set-ItemProperty -Path $RegLegal -Name "legalnoticetext" -Value $LegalText

    Write-Log -Level INFO -Message "Legal Notice erfolgreich gesetzt"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen der Legal Notice: $($_.Exception.Message)"
}


# ---------------------------------------------------------
# Abschluss
# ---------------------------------------------------------

Write-Log -Level INFO -Message "OEM-Branding & Legal Notice Konfiguration abgeschlossen"