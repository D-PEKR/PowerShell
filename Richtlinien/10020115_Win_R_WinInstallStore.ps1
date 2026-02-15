# Modul laden (falls benötigt)
$modulePath = "C:\Program Files\10020115_WinScripts\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction SilentlyContinue

Initialize-Logger -FileName "GPO_AppBlock_User"
Write-Log -Level INFO -Message "Starte Benutzerkonfiguration - App-Deinstallation blockieren"

# ------------------------------------------------------------
# 1. Einstellungen-Seite „Apps & Features“ ausblenden
# ------------------------------------------------------------
$SettingsVisibility = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
New-Item $SettingsVisibility -Force | Out-Null

Set-ItemProperty -Path $SettingsVisibility -Name "SettingsPageVisibility" -Value "hide:appsfeatures" -Type String
Write-Log -Level INFO -Message "Apps & Features in Einstellungen ausgeblendet"

# ------------------------------------------------------------
# 2. UWP-App-Deinstallation verhindern
# ------------------------------------------------------------
$UwpPolicy = "HKCU:\Software\Policies\Microsoft\Windows\Appx"
New-Item $UwpPolicy -Force | Out-Null

Set-ItemProperty -Path $UwpPolicy -Name "BlockRemoval" -Value 1 -Type DWord
Write-Log -Level INFO -Message "UWP-App-Deinstallation blockiert"

# ------------------------------------------------------------
# 3. Klassische Programme: Deinstallation verhindern
# ------------------------------------------------------------
$UninstallPolicy = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall"
New-Item $UninstallPolicy -Force | Out-Null

Set-ItemProperty -Path $UninstallPolicy -Name "NoAddRemovePrograms" -Value 1 -Type DWord
Write-Log -Level INFO -Message "Deinstallation klassischer Programme blockiert"

# ------------------------------------------------------------
# 4. Zugriff auf App-Management blockieren
# ------------------------------------------------------------
$SystemPolicy = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel"
New-Item $SystemPolicy -Force | Out-Null

Set-ItemProperty -Path $SystemPolicy -Name "DisableProgramsControlPanel" -Value 1 -Type DWord
Write-Log -Level INFO -Message "Zugriff auf Programme/Systemsteuerung blockiert"

# ------------------------------------------------------------
# Fertig
# ------------------------------------------------------------
Write-Log -Level INFO -Message "Benutzerkonfiguration abgeschlossen: App-Deinstallation vollständig blockiert"