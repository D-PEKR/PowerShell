$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath
Initialize-Logger -FileName "GPO_OEM_and_LegalNotice"

Write-Log -Level INFO -Message "Starte OEM-Branding & Legal Notice Konfiguration"

# 1) OEM INFORMATION (Systemeigenschaften)

$RegOEM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
New-Item -Path $RegOEM -Force | Out-Null

# OEM Logo in C:\Windows\Web\Wallpaper kopieren
$SourceLogo = "C:\Users\DLRG-JugendAndernach\OneDrive - DLRG OG Andernach e.V\Bilder\Logo\Logo.png"
$TargetLogo = "C:\Windows\Web\Wallpaper\OEMLogo.png"

try {
    Copy-Item -Path $SourceLogo -Destination $TargetLogo -Force
    Write-Log -Level INFO -Message "OEM-Logo erfolgreich kopiert nach $TargetLogo"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Kopieren des OEM-Logos: $_"
}

# OEM Registry-Einträge setzen
Set-ItemProperty -Path $RegOEM -Name "Manufacturer" -Value "DLRG-Jugend Andernach | EDV & Technik"
Set-ItemProperty -Path $RegOEM -Name "SupportHours" -Value "10-18 Uhr"
Set-ItemProperty -Path $RegOEM -Name "SupportPhone" -Value "+49 1575 6018834"
Set-ItemProperty -Path $RegOEM -Name "SupportURL" -Value "https://teams.microsoft.com/l/entity/0ae35b36-0fd7-422e-805b-d53af1579093/_djb2_msteams_prefix_1059335291?context=%7B%22channelId%22%3A%2219%3A65261044e15d4dcd8f67ad5676722fe7%40thread.tacv2%22%7D&tenantId=b540b637-4413-43d4-9ee2-3cba49e12e23"
Set-ItemProperty -Path $RegOEM -Name "Logo" -Value $TargetLogo

Write-Log -Level INFO -Message "OEM-Informationen erfolgreich gesetzt"

# 2) LEGAL NOTICE (Anmeldebildschirm)

$RegLegal = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
New-Item -Path $RegLegal -Force | Out-Null

# Beispieltexte – bitte anpassen
$LegalCaption = "DLRG-Jugend Andernach - IT Sicherheitshinweis"
$LegalText = @"
Dieses Gerät ist Eigentum der DLRG-Jugend Andernach.
Unbefugte Nutzung ist untersagt und wird strafrechtlich verfolgt.

Bei Problemen wenden Sie sich an:
EDV & Technik - https://andernach.dlrg-jugend.de/edv-technik/
"@

Set-ItemProperty -Path $RegLegal -Name "legalnoticecaption" -Value $LegalCaption
Set-ItemProperty -Path $RegLegal -Name "legalnoticetext" -Value $LegalText

Write-Log -Level INFO -Message "Legal Notice erfolgreich gesetzt"

# Abschluss

Write-Log -Level INFO -Message "OEM-Branding & Legal Notice Konfiguration abgeschlossen"