# Modul laden
$modulePath = "C:\Program Files\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"

Write-Log -Level INFO -Message "Starte Computerkonfiguration - Personalisierung"

# Registry-Pfad
$RegPers = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"

# Registry-Key sicherstellen
if (-not (Test-Path $RegPers)) {
    New-Item -Path $RegPers -Force | Out-Null
    Write-Log -Level INFO -Message "Registry-Pfad erstellt: $RegPers"
}

# Bildpfad
$LockImage = "C:\Users\Win11ProTest\DLRG\DLRG OG Andernach Projekte-Jugendnotebooks - Jugendnotebooks\Win11_C\Bilder\Hintergrund\Desktop.png"

if (-not (Test-Path $LockImage)) {
    Write-Log -Level ERROR -Message "Bilddatei nicht gefunden: $LockImage"
} else {
    # Sperrbildschirmbild setzen
    Set-ItemProperty -Path $RegPers -Name "LockScreenImage" -Value $LockImage -Type String
    Write-Log -Level INFO -Message "GPO gesetzt: Sperrbildschirmbild ($LockImage)"

    # Desktop-Hintergrund setzen
    Set-ItemProperty -Path $RegPers -Name "DesktopWallpaper" -Value $LockImage -Type String
    Set-ItemProperty -Path $RegPers -Name "DesktopWallpaperStyle" -Value "10" -Type String   # Fill
    Write-Log -Level INFO -Message "GPO gesetzt: Desktop-Hintergrund ($LockImage)"
}

# Bildpfad für Sperrbildschirm
$LockImageScreen = "C:\Users\Win11ProTest\DLRG\DLRG OG Andernach Projekte-Jugendnotebooks - Jugendnotebooks\Win11_C\Bilder\Hintergrund\Sperrbildschirm.png"

if (-not (Test-Path $LockImageScreen)) {
    Write-Log -Level ERROR -Message "Sperrbildschirm-Bilddatei nicht gefunden: $LockImageScreen"
} else {
    # Sperrbildschirmbild setzen (GPO)
    Set-ItemProperty -Path $RegPers -Name "LockScreenImage" -Value $LockImageScreen -Type String
    Set-ItemProperty -Path $RegPers -Name "LockScreenImagePath" -Value $LockImageScreen -Type String
    Set-ItemProperty -Path $RegPers -Name "ForceLockScreenBackground" -Value 1 -Type DWord

    Write-Log -Level INFO -Message "GPO gesetzt: Sperrbildschirm-Hintergrund ($LockImageScreen)"
}

# Ändern des Sperrbildschirms verhindern
Set-ItemProperty -Path $RegPers -Name "NoChangingLockScreen" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Ändern des Sperrbildschirms verhindern"

Write-Log -Level INFO -Message "Computerkonfiguration abgeschlossen: Personalisierung"