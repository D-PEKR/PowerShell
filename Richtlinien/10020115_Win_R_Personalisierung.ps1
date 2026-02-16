# Modul laden
$modulePath = "C:\Program Files\10020115_WinScripts\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"

Write-Log -Level INFO -Message "Starte Benutzerkonfiguration - Personalisierung"

# Registry-Pfade
$RegExplorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$RegSystem   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
$RegActive   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"

New-Item $RegExplorer -Force | Out-Null
New-Item $RegSystem   -Force | Out-Null
New-Item $RegActive   -Force | Out-Null

# 1 – Farbschema ändern verhindern
Set-ItemProperty -Path $RegSystem -Name "NoDispAppearancePage" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Farbschema ändern verhindern"

# 2 – Design ändern verhindern
Set-ItemProperty -Path $RegExplorer -Name "NoThemesTab" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Design ändern verhindern"

# 3 – Farbe & Darstellung verhindern
Set-ItemProperty -Path $RegSystem -Name "NoDispAppearancePage" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Farbe & Darstellung verhindern"

# 4 – Desktop-Hintergrund ändern verhindern
Set-ItemProperty -Path $RegActive -Name "NoChangingWallPaper" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Desktop-Hintergrund ändern verhindern"

# 5 – Desktopsymbole ändern verhindern
Set-ItemProperty -Path $RegExplorer -Name "NoSaveSettings" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Desktopsymbole ändern verhindern"

# 6 – Mauszeiger ändern verhindern
Set-ItemProperty -Path $RegSystem -Name "NoDispCPL" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Mauszeiger ändern verhindern"

# 7 – Bestimmtes Design laden
$ThemePath = "C:\Users\DLRG-JugendAndernach\OneDrive - DLRG OG Andernach e.V\Bilder\Hintergrundbilder\Desktop.png"
Set-ItemProperty -Path $RegExplorer -Name "ThemeFile" -Value $ThemePath -Type String
Write-Log -Level INFO -Message "GPO gesetzt: Bestimmtes Design laden ($ThemePath)"

Write-Log -Level INFO -Message "Benutzerkonfiguration - Personalisierung abgeschlossen"