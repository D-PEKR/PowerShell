# PowerShell-Script: Microsoft Store deaktivieren
# Als Administrator ausführen

$regPath  = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
$valueName = "RemoveWindowsStore"

# Schlüssel anlegen, falls nicht vorhanden
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# DWORD-Wert setzen: 1 = Store deaktiviert
New-ItemProperty -Path $regPath -Name $valueName -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host "Microsoft Store wurde per Richtlinie deaktiviert. Bitte Windows neu starten."