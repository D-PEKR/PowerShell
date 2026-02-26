#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------
# Modul laden & Logging starten
# ------------------------------------------------------------
$modulePath = "C:\Users\Public\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop
Initialize-Logger -Level "INFO"
Write-Log -Level INFO -Message "Starte Benutzerkonfiguration: Installationen kontrollieren (optimiert, ohne using)"

# ------------------------------------------------------------
# Hilfsfunktionen: Schnelle Registry-Operationen via .NET
# ------------------------------------------------------------
function Open-BaseKey {
    param(
        [Parameter(Mandatory)][Microsoft.Win32.RegistryHive]$Hive
    )
    return [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, [Microsoft.Win32.RegistryView]::Default)
}

function Open-Or-CreateSubKey {
    param(
        [Parameter(Mandatory)][Microsoft.Win32.RegistryKey]$BaseKey,
        [Parameter(Mandatory)][string]$SubPath
    )
    # CreateSubKey erstellt bei Bedarf, öffnet andernfalls schreibbar
    return $BaseKey.CreateSubKey($SubPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
}

function Set-RegValueIfChanged {
    <#
      .SYNOPSIS
        Setzt einen Registry-Wert nur, wenn er sich geändert hat (minimiert I/O).
      .OUTPUTS
        [bool] True, wenn geschrieben wurde; sonst False.
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

function Require-AdminForHKLM {
    $id  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pri = [Security.Principal.WindowsPrincipal]::new($id)
    if (-not $pri.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Log -Level ERROR -Message "HKLM-Schreibzugriff erfordert Administratorrechte."
        throw "Administratorrechte erforderlich für HKLM-Änderungen."
    }
}

# ------------------------------------------------------------
# 1) Admin-Key prüfen (leichter Dateicheck)
# ------------------------------------------------------------
$AdminKeyFile = "C:\ProgramData\AdminInstall.key"
$AllowInstall = Test-Path -Path $AdminKeyFile -PathType Leaf

if ($AllowInstall) {
    Write-Log -Level INFO -Message "Admin-Key gefunden – Installationen werden ERLAUBT."
} else {
    Write-Log -Level INFO -Message "Kein Admin-Key – Installationen werden BLOCKIERT."
}

# ------------------------------------------------------------
# 2) SRP (Software Restriction Policies) effizient setzen (HKLM)
# ------------------------------------------------------------
Require-AdminForHKLM

$lm = Open-BaseKey -Hive ([Microsoft.Win32.RegistryHive]::LocalMachine)
$srpKey = $null
$changedHKLM = 0
try {
    $srpKey = Open-Or-CreateSubKey -BaseKey $lm -SubPath "Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers"

    # Basiswerte (nur bei Änderung schreiben)
    if (Set-RegValueIfChanged -Key $srpKey -Name "PolicyScope"        -Value 0 -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)) { $changedHKLM++ }
    if (Set-RegValueIfChanged -Key $srpKey -Name "TransparentEnabled" -Value 1 -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)) { $changedHKLM++ }
    if (Set-RegValueIfChanged -Key $srpKey -Name "AuthenticodeEnabled"-Value 0 -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)) { $changedHKLM++ }

    # DefaultLevel je nach Admin-Key
    $defaultLevel = if ($AllowInstall) { 0x40000 } else { 0x0 }  # 262144 = Unrestricted, 0 = Disallowed
    if (Set-RegValueIfChanged -Key $srpKey -Name "DefaultLevel" -Value $defaultLevel -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)) {
        $changedHKLM++
        Write-Log -Level INFO -Message ("SRP: DefaultLevel gesetzt auf {0}" -f ("0x{0:X}" -f $defaultLevel))
    } else {
        Write-Log -Level INFO -Message ("SRP: DefaultLevel unverändert (bereits {0})" -f ("0x{0:X}" -f $defaultLevel))
    }
}
finally {
    if ($srpKey) { $srpKey.Close() }
    if ($lm) { $lm.Close() }
}

# ------------------------------------------------------------
# 3) Optionale Benutzerbeschränkungen (HKCU) schnell & idempotent
# ------------------------------------------------------------
$user = Open-BaseKey -Hive ([Microsoft.Win32.RegistryHive]::CurrentUser)
$changedHKCU = 0
try {
    # Apps & Features ausblenden
    $explorerPol = Open-Or-CreateSubKey -BaseKey $user -SubPath "Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    if (Set-RegValueIfChanged -Key $explorerPol -Name "SettingsPageVisibility" -Value "hide:appsfeatures" -Kind ([Microsoft.Win32.RegistryValueKind]::String)) {
        $changedHKCU++
        Write-Log -Level INFO -Message "Apps & Features ausgeblendet (SettingsPageVisibility)."
    }
    $explorerPol.Close()

    # UWP-App-Deinstallation blockieren
    $appxPol = Open-Or-CreateSubKey -BaseKey $user -SubPath "Software\Policies\Microsoft\Windows\Appx"
    if (Set-RegValueIfChanged -Key $appxPol -Name "BlockRemoval" -Value 1 -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)) {
        $changedHKCU++
        Write-Log -Level INFO -Message "UWP-App-Deinstallation blockiert (BlockRemoval=1)."
    }
    $appxPol.Close()

    # Klassische Programme: Deinstallation blockieren
    $uninstPol = Open-Or-CreateSubKey -BaseKey $user -SubPath "Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall"
    if (Set-RegValueIfChanged -Key $uninstPol -Name "NoAddRemovePrograms" -Value 1 -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)) {
        $changedHKCU++
        Write-Log -Level INFO -Message "Deinstallation klassischer Programme blockiert (NoAddRemovePrograms=1)."
    }
    $uninstPol.Close()

    # Systemsteuerung Programme blockieren
    $cpol = Open-Or-CreateSubKey -BaseKey $user -SubPath "Software\Policies\Microsoft\Windows\Control Panel"
    if (Set-RegValueIfChanged -Key $cpol -Name "DisableProgramsControlPanel" -Value 1 -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)) {
        $changedHKCU++
        Write-Log -Level INFO -Message "Zugriff auf Programme/Systemsteuerung blockiert (DisableProgramsControlPanel=1)."
    }
    $cpol.Close()
}
finally {
    if ($user) { $user.Close() }
}

# ------------------------------------------------------------
# 4) Zusammenfassung
# ------------------------------------------------------------
if ($changedHKLM -eq 0 -and $changedHKCU -eq 0) {
    Write-Log -Level INFO -Message "Keine Änderungen erforderlich – alle Werte waren bereits korrekt."
} else {
    Write-Log -Level INFO -Message ("Änderungen angewendet: HKLM={0}, HKCU={1}" -f $changedHKLM, $changedHKCU)
}

Write-Log -Level INFO -Message "Benutzerkonfiguration abgeschlossen – Installationen kontrolliert (optimiert)"