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
Write-Log -Level INFO -Message "Starte Gesamt-Konfiguration - Personalisierung"


# =========================================================
# 1) ALLE EINSTELLUNGEN AUF STANDARD ZURÜCKSETZEN
# =========================================================

Write-Log -Level INFO -Message "Setze alle Personalisierungsrichtlinien auf Standard zurück"

$RegExplorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$RegSystem   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
$RegActive   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"
$RegPers     = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"

# Benutzer-Richtlinien entfernen
try {
    Remove-ItemProperty -Path $RegExplorer -Name "NoThemesTab"          -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegExplorer -Name "NoSaveSettings"       -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegExplorer -Name "ThemeFile"            -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegSystem   -Name "NoDispAppearancePage" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegSystem   -Name "NoDispCPL"            -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegActive   -Name "NoChangingWallPaper"  -ErrorAction SilentlyContinue
    Write-Log -Level INFO -Message "Benutzer-Richtlinien entfernt"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Entfernen der Benutzer-Richtlinien: $($_.Exception.Message)"
}

# Computer-Richtlinien entfernen
try {
    Remove-ItemProperty -Path $RegPers -Name "DesktopWallpaper"          -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegPers -Name "DesktopWallpaperStyle"     -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegPers -Name "LockScreenImage"           -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegPers -Name "LockScreenImagePath"       -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegPers -Name "ForceLockScreenBackground" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegPers -Name "NoChangingLockScreen"      -ErrorAction SilentlyContinue
    Write-Log -Level INFO -Message "Computer-Richtlinien entfernt"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Entfernen der Computer-Richtlinien: $($_.Exception.Message)"
}

Write-Log -Level INFO -Message "Alle Richtlinien erfolgreich zurückgesetzt"

# Registry-Pfad neu anlegen
try {
    if (-not (Test-Path $RegPers)) {
        New-Item -Path $RegPers -Force | Out-Null
        Write-Log -Level INFO -Message "Registry-Pfad neu erstellt: $RegPers"
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Erstellen des Registry-Pfads: $($_.Exception.Message)"
}


# =========================================================
# 2) HINTERGRUND UND SPERRBILDSCHIRM SETZEN
# =========================================================

Write-Log -Level INFO -Message "Setze Desktop- und Sperrbildschirmbilder"

$UserWallpaper   = "C:\Users\Public\10020115_WinScripts\Win11_C\Bilder\Hintergrund\Desktop.png"
$DesktopImage    = "C:\Users\Public\10020115_WinScripts\Win11_C\Bilder\Hintergrund\Desktop.png"
$LockImageScreen = "C:\Users\Public\10020115_WinScripts\Win11_C\Bilder\Hintergrund\Sperrbildschirm.png"

# Benutzer-Desktop setzen
try {
    if (Test-Path $UserWallpaper) {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $UserWallpaper
        RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
        Write-Log -Level INFO -Message "Benutzer-Hintergrund gesetzt: $UserWallpaper"
    }
    else {
        Write-Log -Level ERROR -Message "Benutzer-Hintergrund nicht gefunden: $UserWallpaper"
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen des Benutzer-Hintergrunds: $($_.Exception.Message)"
}

# Computer-Desktop setzen
try {
    if (Test-Path $DesktopImage) {
        Set-ItemProperty -Path $RegPers -Name "DesktopWallpaper" -Value $DesktopImage -Type String
        Set-ItemProperty -Path $RegPers -Name "DesktopWallpaperStyle" -Value "10" -Type String
        Write-Log -Level INFO -Message "Computer-Desktop gesetzt: $DesktopImage"
    }
    else {
        Write-Log -Level ERROR -Message "Computer-Desktopbild nicht gefunden: $DesktopImage"
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen des Computer-Desktops: $($_.Exception.Message)"
}

# Sperrbildschirm setzen
try {
    if (Test-Path $LockImageScreen) {
        Set-ItemProperty -Path $RegPers -Name "LockScreenImage" -Value $LockImageScreen -Type String
        Set-ItemProperty -Path $RegPers -Name "LockScreenImagePath" -Value $LockImageScreen -Type String
        Write-Log -Level INFO -Message "Sperrbildschirm gesetzt: $LockImageScreen"
    }
    else {
        Write-Log -Level ERROR -Message "Sperrbildschirmbild nicht gefunden: $LockImageScreen"
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen des Sperrbildschirms: $($_.Exception.Message)"
}


# =========================================================
# 3) 5 SEKUNDEN WARTEN
# =========================================================

Write-Log -Level INFO -Message "Warte 5 Sekunden bevor Richtlinien wieder gesetzt werden"
Start-Sleep -Seconds 5


# =========================================================
# 4) RICHTLINIEN WIEDER AKTIVIEREN (SPERREN)
# =========================================================

Write-Log -Level INFO -Message "Setze Richtlinien erneut – Änderungen werden gesperrt"

try {
    Set-ItemProperty -Path $RegSystem   -Name "NoDispAppearancePage" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegExplorer -Name "NoThemesTab"          -Value 1 -Type DWord
    Set-ItemProperty -Path $RegActive   -Name "NoChangingWallPaper"  -Value 1 -Type DWord
    Set-ItemProperty -Path $RegExplorer -Name "NoSaveSettings"       -Value 1 -Type DWord
    Set-ItemProperty -Path $RegSystem   -Name "NoDispCPL"            -Value 1 -Type DWord
    Set-ItemProperty -Path $RegExplorer -Name "ThemeFile"            -Value $UserWallpaper -Type String

    Set-ItemProperty -Path $RegPers -Name "ForceLockScreenBackground" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPers -Name "NoChangingLockScreen"      -Value 1 -Type DWord

    Write-Log -Level INFO -Message "Alle Richtlinien erfolgreich gesetzt – Änderungen nun gesperrt"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen der Richtlinien: $($_.Exception.Message)"
}

Write-Log -Level INFO -Message "Gesamt-Konfiguration abgeschlossen"