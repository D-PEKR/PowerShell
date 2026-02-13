$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath
Initialize-Logger -FileName "GPO_PIN_Complexity.log"

Write-Log -Level INFO -Message "Starte PIN-Komplexität GPOs"

$RegPIN = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"
New-Item $RegPIN -Force | Out-Null

Set-ItemProperty -Path $RegPIN -Name "Digits" -Value 1 -Type DWord
Set-ItemProperty -Path $RegPIN -Name "LowercaseLetters" -Value 1 -Type DWord
Set-ItemProperty -Path $RegPIN -Name "UppercaseLetters" -Value 1 -Type DWord
Set-ItemProperty -Path $RegPIN -Name "SpecialCharacters" -Value 1 -Type DWord
Set-ItemProperty -Path $RegPIN -Name "MinimumPINLength" -Value 8 -Type DWord
Set-ItemProperty -Path $RegPIN -Name "Expiration" -Value 90 -Type DWord

Write-Log -Level INFO -Message "GPO gesetzt: PIN-Komplexität vollständig angewendet"