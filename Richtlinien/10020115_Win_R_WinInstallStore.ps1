$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath
Initialize-Logger -FileName "GPO_AppControl"

Write-Log -Level INFO -Message "Starte AppControl GPOs"

# Windows Installer deaktivieren
$RegInstaller = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
New-Item $RegInstaller -Force | Out-Null
Set-ItemProperty -Path $RegInstaller -Name "DisableMSI" -Value 2 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Windows Installer deaktiviert (immer)"

# Store deaktivieren
$RegStore = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
New-Item $RegStore -Force | Out-Null
Set-ItemProperty -Path $RegStore -Name "RemoveWindowsStore" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Microsoft Store deaktiviert"

Write-Log -Level INFO -Message "AppControl GPOs abgeschlossen"