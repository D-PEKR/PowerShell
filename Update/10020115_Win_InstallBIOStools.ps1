
# HP Install
# Als Admin in 64-bit PowerShell
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name HPCMSL -Force -AcceptLicense
# Hier fängt das Script für HP Software check an:
<#
    Zweck: HPCMSL nur installieren, wenn noch nicht vorhanden.
    Verhalten:
      - Prüft auf vorhandenes Modul (Gallery + manuell kopierte Module).
      - Bereitet NuGet/PSGallery vor (TLS 1.2, Provider, Trusted).
      - Installiert HPCMSL unattended.
      - Exit-Codes: 0 = OK (bereits vorhanden oder erfolgreich installiert), 1 = Fehler.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ---
function Test-IsAdmin {
try {
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$p  = New-Object Security.Principal.WindowsPrincipal($id)
return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { return $false }
}

function Test-HasHPCMSL {
# 1) Über PowerShellGet installiert?
$m1 = Get-InstalledModule -Name 'HPCMSL' -ErrorAction SilentlyContinue
if ($m1) { return $true }

# 2) Als Modul im Modulpfad vorhanden (z. B. manuell abgelegt)?
$m2 = Get-Module -ListAvailable -Name 'HPCMSL'
if ($m2) { return $true }

return $false
}

function Ensure-PackageInfra {
# TLS 1.2 (ältere Systeme)
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# NuGet Provider
try {
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers -ErrorAction Stop | Out-Null
} catch {
# Fallback: CurrentUser (falls keine Adminrechte)
try {
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
} catch {
throw "NuGet Provider konnte nicht installiert werden: $($_.Exception.Message)"
}
}

# PowerShell Gallery vertrauen / registrieren
try {
$pg = Get-PSRepository -Name 'PSGallery' -ErrorAction Stop
if ($pg.InstallationPolicy -ne 'Trusted') {
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
}
} catch {
try {
Register-PSRepository -Default -ErrorAction Stop
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
} catch {
Write-Warning "PSGallery konnte nicht gesetzt werden: $($_.Exception.Message)"
}
}
}

# --- Main ---
try {
if (Test-HasHPCMSL) {
Write-Host "HPCMSL ist bereits installiert. Vorgang wird beendet."
exit 0
}

Write-Host "HPCMSL nicht gefunden – Installation wird vorbereitet..."
Ensure-PackageInfra

$scope = if (Test-IsAdmin) { 'AllUsers' } else { 'CurrentUser' }
Write-Host "Installations-Scope: $scope"

Install-Module -Name 'HPCMSL' -Scope $scope -Force -AcceptLicense -ErrorAction Stop

# Optionaler Sanity-Check
Import-Module HPCMSL -ErrorAction Stop
$ver = (Get-Module HPCMSL).Version
Write-Host "HPCMSL erfolgreich installiert. Version: $ver"

exit 0
}
catch {
Write-Error "Installation von HPCMSL fehlgeschlagen: $($_.Exception.Message)"
exit 1
}




# Für lenovo
# https://support.lenovo.com/us/en/downloads/ds012808-lenovo-system-update-for-windows-10-7-32-bit-64-bit-desktop-notebook-workstation