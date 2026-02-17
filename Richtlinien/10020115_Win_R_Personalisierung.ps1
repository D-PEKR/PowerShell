# ---------------------------------------------------------
# Modul laden & Logging starten
# ---------------------------------------------------------
$modulePath = "C:\Program Files\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"
Write-Log -Level INFO -Message "Starte Gesamt-Konfiguration - Personalisierung"


# =========================================================
# 1) ALLE EINSTELLUNGEN AUF STANDARD ZURÜCKSETZEN
# =========================================================

Write-Log -Level INFO -Message "Setze alle Personalisierungsrichtlinien auf Standard zurück"

# Benutzerpfade
$RegExplorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$RegSystem   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
$RegActive   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"

# Computerkonfiguration
$RegPers = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"

# Benutzer-Richtlinien entfernen
Remove-ItemProperty -Path $RegExplorer -Name "NoThemesTab"          -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegExplorer -Name "NoSaveSettings"       -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegExplorer -Name "ThemeFile"            -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegSystem   -Name "NoDispAppearancePage" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegSystem   -Name "NoDispCPL"            -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegActive   -Name "NoChangingWallPaper"  -ErrorAction SilentlyContinue

# Computer-Richtlinien entfernen
Remove-ItemProperty -Path $RegPers -Name "DesktopWallpaper"          -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegPers -Name "DesktopWallpaperStyle"     -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegPers -Name "LockScreenImage"           -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegPers -Name "LockScreenImagePath"       -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegPers -Name "ForceLockScreenBackground" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegPers -Name "NoChangingLockScreen"      -ErrorAction SilentlyContinue

Write-Log -Level INFO -Message "Alle Richtlinien erfolgreich zurückgesetzt"

# 🔧 FIX: Registry-Pfad wieder anlegen
if (-not (Test-Path $RegPers)) {
    New-Item -Path $RegPers -Force | Out-Null
    Write-Log -Level INFO -Message "Registry-Pfad neu erstellt: $RegPers"
}


# =========================================================
# 2) HINTERGRUND UND SPERRBILDSCHIRM SETZEN
# =========================================================

Write-Log -Level INFO -Message "Setze Desktop- und Sperrbildschirmbilder"

# Benutzer-Hintergrund
$UserWallpaper = "C:\Program Files\10020115_WinScripts\Win11_C\Bilder\Hintergrund\Desktop.png"

# Computer-Hintergründe
$DesktopImage = "C:\Program Files\10020115_WinScripts\Win11_C\Bilder\Hintergrund\Desktop.png"
$LockImageScreen = "C:\Program Files\10020115_WinScripts\Win11_C\Bilder\Hintergrund\Sperrbildschirm.png"

# Benutzer-Desktop setzen
if (Test-Path $UserWallpaper) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $UserWallpaper
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
    Write-Log -Level INFO -Message "Benutzer-Hintergrund gesetzt: $UserWallpaper"
} else {
    Write-Log -Level ERROR -Message "Benutzer-Hintergrund nicht gefunden: $UserWallpaper"
}

# Computer-Desktop setzen
if (Test-Path $DesktopImage) {
    Set-ItemProperty -Path $RegPers -Name "DesktopWallpaper" -Value $DesktopImage -Type String
    Set-ItemProperty -Path $RegPers -Name "DesktopWallpaperStyle" -Value "10" -Type String
    Write-Log -Level INFO -Message "Computer-Desktop gesetzt: $DesktopImage"
} else {
    Write-Log -Level ERROR -Message "Computer-Desktopbild nicht gefunden: $DesktopImage"
}

# Sperrbildschirm setzen
if (Test-Path $LockImageScreen) {
    Set-ItemProperty -Path $RegPers -Name "LockScreenImage" -Value $LockImageScreen -Type String
    Set-ItemProperty -Path $RegPers -Name "LockScreenImagePath" -Value $LockImageScreen -Type String
    Write-Log -Level INFO -Message "Sperrbildschirm gesetzt: $LockImageScreen"
} else {
    Write-Log -Level ERROR -Message "Sperrbildschirmbild nicht gefunden: $LockImageScreen"
}


# =========================================================
# 3) 5 SEKUNDEN WARTEN
# =========================================================

Write-Log -Level INFO -Message "Warte 5 Sekunden bevor Richtlinien wieder gesetzt werden"
Start-Sleep -Seconds 5


# =========================================================
# 4) RICHTLINIEN WIEDER AKTIVIEREN (SPERREN)
# =========================================================

Write-Log -Level INFO -Message "Setze Richtlinien erneut Änderungen werden gesperrt"

# Benutzer-Richtlinien
Set-ItemProperty -Path $RegSystem   -Name "NoDispAppearancePage" -Value 1 -Type DWord
Set-ItemProperty -Path $RegExplorer -Name "NoThemesTab"          -Value 1 -Type DWord
Set-ItemProperty -Path $RegActive   -Name "NoChangingWallPaper"  -Value 1 -Type DWord
Set-ItemProperty -Path $RegExplorer -Name "NoSaveSettings"       -Value 1 -Type DWord
Set-ItemProperty -Path $RegSystem   -Name "NoDispCPL"            -Value 1 -Type DWord
Set-ItemProperty -Path $RegExplorer -Name "ThemeFile"            -Value $UserWallpaper -Type String

# Computer-Richtlinien
Set-ItemProperty -Path $RegPers -Name "ForceLockScreenBackground" -Value 1 -Type DWord
Set-ItemProperty -Path $RegPers -Name "NoChangingLockScreen"      -Value 1 -Type DWord

Write-Log -Level INFO -Message "Alle Richtlinien erfolgreich gesetzt Änderungen nun gesperrt"
Write-Log -Level INFO -Message "Gesamt-Konfiguration abgeschlossen"