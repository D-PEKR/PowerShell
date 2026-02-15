$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath
Initialize-Logger -FileName "GPO_Computer_Personalization"

Write-Log -Level INFO -Message "Starte Computerkonfiguration - Personalisierung"

$RegPers = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
New-Item $RegPers -Force | Out-Null

# Sperrbildschirmbild erzwingen
$LockImage = "C:\Users\DLRG-JugendAndernach\DLRG\DLRG OG Andernach Projekte-Jugendnotebooks - Jugendnotebooks\Win11_C\Bilder\Hintergrund\Desktop.png"

Set-ItemProperty -Path $RegPers -Name "LockScreenImage" -Value $LockImage -Type String
Write-Log -Level INFO -Message "GPO gesetzt: Sperrbildschirmbild erzwingen ($LockImage)"

# Desktop-Hintergrund setzen
Set-ItemProperty -Path $RegPers -Name "DesktopWallpaper" -Value $LockImage -Type String
Set-ItemProperty -Path $RegPers -Name "DesktopWallpaperStyle" -Value "10" -Type String   # Fill
Write-Log -Level INFO -Message "GPO gesetzt: Desktop-Hintergrund ($LockImage)"

# Ändern des Sperrbildschirms verhindern
Set-ItemProperty -Path $RegPers -Name "NoChangingLockScreen" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Ändern des Sperrbildschirms verhindern"

Write-Log -Level INFO -Message "Computerkonfiguration - Personalisierung abgeschlossen"