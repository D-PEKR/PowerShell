#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Global:PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# ---------------------------------------------------------
# Logging-Modul laden
# ---------------------------------------------------------
$modulePath = "C:\Users\Public\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"
Write-Log -Level INFO -Message "Starte OEM-Branding & Legal Notice Konfiguration (optimiert)"

# ---------------------------------------------------------
# Fehler-Events nur in PS7+ nutzen (in 5.1 nicht vorhanden)
# ---------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -ge 7) {
    try {
        Register-EngineEvent -SourceIdentifier PowerShell.OnScriptError -Action {
            try {
                $msg = $_.SourceArgs[0].Exception.Message
                Write-Log -Level "ERROR" -Message "PowerShell-Fehler: $msg"
            } catch {}
        } | Out-Null
    } catch {}
}

# ---------------------------------------------------------
# Admin-Check (HKLM-Schreibzugriff)
# ---------------------------------------------------------
function Require-Admin {
    $id  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pri = [Security.Principal.WindowsPrincipal]::new($id)
    if (-not $pri.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Log -Level ERROR -Message "Dieses Skript muss als Administrator ausgeführt werden (HKLM-Schreibzugriff)."
        throw "Administratorrechte erforderlich."
    }
}
Require-Admin

# ---------------------------------------------------------
# Schnelle Registry-Hilfen (.NET)
# ---------------------------------------------------------
function Open-BaseKey {
    param([Parameter(Mandatory)][Microsoft.Win32.RegistryHive]$Hive)
    return [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, [Microsoft.Win32.RegistryView]::Default)
}

function Open-Or-CreateSubKey {
    param(
        [Parameter(Mandatory)][Microsoft.Win32.RegistryKey]$BaseKey,
        [Parameter(Mandatory)][string]$SubPath
    )
    return $BaseKey.CreateSubKey($SubPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
}

function Set-RegValueIfChanged {
    <#
      Setzt Registry-Wert nur, wenn er sich ändert → weniger I/O.
      Rückgabe: $true wenn geschrieben; sonst $false.
    #>
    param(
        [Parameter(Mandatory)][Microsoft.Win32.RegistryKey]$Key,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][Microsoft.Win32.RegistryValueKind]$Kind
    )
    $current = $Key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $equal = $false

    switch ($Kind) {
        ([Microsoft.Win32.RegistryValueKind]::DWord) {
            $target = [int]$Value
            if ($null -ne $current -and ([int]$current -eq $target)) { $equal = $true }
        }
        default {
            $target = [string]$Value
            if ($null -ne $current -and ([string]$current) -ceq $target) { $equal = $true }
        }
    }

    if (-not $equal) {
        $Key.SetValue($Name, $Value, $Kind)
        return $true
    }
    return $false
}

function Remove-RegValueIfEmpty {
    param(
        [Parameter(Mandatory)][Microsoft.Win32.RegistryKey]$Key,
        [Parameter(Mandatory)][string]$Name,
        [string]$Value
    )
    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($Key.GetValueNames() -contains $Name) {
            $Key.DeleteValue($Name, $false)
            return $true
        }
    }
    return $false
}

# ---------------------------------------------------------
# Parameter / Konstanten
# ---------------------------------------------------------
# Quelle: Du kannst diese Werte zentral pflegen
$Manufacturer = "DLRG-Jugend Andernach | EDV & Technik"
$SupportHours = "10-18 Uhr"
$SupportPhone = "+49 1575 6018834"
