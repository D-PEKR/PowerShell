$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath
Initialize-Logger -FileName "GPO_Programs_User.log"

Write-Log -Level INFO -Message "Starte Benutzerkonfiguration - Programme hinzufügen/entfernen"

$RegUninstall = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall"
New-Item $RegUninstall -Force | Out-Null

Set-ItemProperty -Path $RegUninstall -Name "NoAddRemovePrograms" -Value 1 -Type DWord
Write-Log -Level INFO -Message "GPO gesetzt: Programme hinzufügen/entfernen deaktiviert"

Write-Log -Level INFO -Message "Benutzerkonfiguration - Programme abgeschlossen"