$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath
Initialize-Logger -FileName "GPO_Computer_Personalization.log"

Write-Log -Level INFO -Message "Starte Computerkonfiguration – Personalisierung"

$RegPers = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
New-Item $RegPers -Force | Out-Null

# Sperrbildschirmbild erzwingen
$LockImage = "C:\Users\DLRG-JugendAndernach\OneDrive - DLRG OG Andernach e.V\Bilder\Hintergrundbilder\Sperrbildschirm.png"
Set-ItemProperty -Path $RegPers -Name "LockScreenImage" -Value $LockImage -Type String
Set-ItemProperty -Path $RegPers -Name "LockScreenImageStatus" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Sperrbildschirmbild erzwingen ($LockImage)"

# Startmenühintergrund ändern verhindern
Set-ItemProperty -Path $RegPers -Name "NoChangingStartMenuBackground" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Startmenühintergrund ändern verhindern"

Write-Log -Level INFO -Message "Computerkonfiguration – Personalisierung abgeschlossen"