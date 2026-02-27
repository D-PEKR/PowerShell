# Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Rollback: Setze alle Änderungen auf Windows-Standard zurück..."

# ------------------------------------------------------------
# 1) HKLM – SRP komplett entfernen
# ------------------------------------------------------------
$srpPath = "HKLM:\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers"

if (Test-Path $srpPath) {
    Remove-Item -Path $srpPath -Recurse -Force
    Write-Host "SRP-Einstellungen entfernt (HKLM)."
} else {
    Write-Host "SRP-Einstellungen waren nicht gesetzt."
}

# ------------------------------------------------------------
# 2) HKCU – Benutzerbeschränkungen entfernen
# ------------------------------------------------------------

# Explorer – SettingsPageVisibility
$explorerPol = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (Test-Path $explorerPol) {
    Remove-ItemProperty -Path $explorerPol -Name "SettingsPageVisibility" -ErrorAction SilentlyContinue
    Write-Host "SettingsPageVisibility entfernt."
}

# Appx – BlockRemoval
$appxPol = "HKCU:\Software\Policies\Microsoft\Windows\Appx"
if (Test-Path $appxPol) {
    Remove-ItemProperty -Path $appxPol -Name "BlockRemoval" -ErrorAction SilentlyContinue
    Write-Host "BlockRemoval entfernt."
}

# Uninstall – NoAddRemovePrograms
$uninstPol = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall"
if (Test-Path $uninstPol) {
    Remove-ItemProperty -Path $uninstPol -Name "NoAddRemovePrograms" -ErrorAction SilentlyContinue
    Write-Host "NoAddRemovePrograms entfernt."
}

# Control Panel – DisableProgramsControlPanel
$cpol = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel"
if (Test-Path $cpol) {
    Remove-ItemProperty -Path $cpol -Name "DisableProgramsControlPanel" -ErrorAction SilentlyContinue
    Write-Host "DisableProgramsControlPanel entfernt."
}

Write-Host "Rollback abgeschlossen – alle Werte wieder auf Standard."