# =====================================================================
#  Logging-Modul laden
# =====================================================================
$modulePath = 'C:\Users\Public\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1'
Import-Module -Name $modulePath -ErrorAction Stop

Initialize-Logger -Level 'INFO'
Write-Log -Level INFO -Message "Scriptstart: Geräteprüfung & Installation"

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =====================================================================
#  Helper-Funktionen
# =====================================================================

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p  = [Security.Principal.WindowsPrincipal]::new($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Test-HasHPCMSL {
    if (Get-InstalledModule -Name 'HPCMSL' -ErrorAction SilentlyContinue) { return $true }
    if (Get-Module -ListAvailable -Name 'HPCMSL') { return $true }
    return $false
}

function Ensure-PackageInfra {
    Write-Log INFO "Stelle Paket-Infrastruktur sicher..."

    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers -ErrorAction Stop | Out-Null
    } catch {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
    }

    try {
        $pg = Get-PSRepository -Name 'PSGallery' -ErrorAction Stop
        if ($pg.InstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
        }
    } catch {
        Register-PSRepository -Default -ErrorAction Stop
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
    }
}

function Install-LenovoSystemUpdate {
    $installerPath = "LenovoBiosInstall\system_update.exe"

    if (-not (Test-Path $installerPath)) {
        Write-Log ERROR "Lenovo Installer nicht gefunden: $installerPath"
        throw "Lenovo Installer fehlt."
    }

    Write-Log INFO "Starte Lenovo System Update Installation..."

    Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART" -Wait

    Write-Log INFO "Lenovo System Update erfolgreich installiert."
}

# =====================================================================
#  Gerätehersteller ermitteln
# =====================================================================

$manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer.Trim()
Write-Log INFO "Hersteller erkannt: $manufacturer"

# =====================================================================
#  Hauptlogik
# =====================================================================

try {

    switch -Wildcard ($manufacturer) {

        "HP*" {
            Write-Log INFO "HP-Gerät erkannt HPCMSL wird geprüft."

            if (Test-HasHPCMSL) {
                Write-Log INFO "HPCMSL bereits installiert. Vorgang beendet."
                exit 0
            }

            Write-Log INFO "HPCMSL nicht gefunden Installation wird vorbereitet..."
            Ensure-PackageInfra

            $scope = if (Test-IsAdmin) { 'AllUsers' } else { 'CurrentUser' }
            Write-Log INFO "Installations-Scope: $scope"

            Install-Module -Name 'HPCMSL' -Scope $scope -Force -AcceptLicense -ErrorAction Stop

            Import-Module HPCMSL -ErrorAction Stop
            $ver = (Get-Module HPCMSL).Version
            Write-Log INFO "HPCMSL erfolgreich installiert. Version: $ver"

            exit 0
        }

        "Lenovo*" {
            Write-Log INFO "Lenovo-Gerät erkannt Lenovo System Update wird installiert."
            Install-LenovoSystemUpdate
            exit 0
        }

        default {
            Write-Log WARNING "Unbekannter Hersteller: $manufacturer keine Installation durchgeführt."
            exit 0
        }
    }

}
catch {
    Write-Log ERROR "Fehler: $($_.Exception.Message)"
    exit 1
}




# Für lenovo
# https://support.lenovo.com/us/en/downloads/ds012808-lenovo-system-update-for-windows-10-7-32-bit-64-bit-desktop-notebook-workstation