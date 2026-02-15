# ---------------------------------------------------------
# Gemeinsame Initialisierung
# ---------------------------------------------------------
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath
Initialize-Logger -FileName "System_Watchdog" -Level "INFO"

Write-Log -Level INFO -Message "Starte kombinierten System-Watchdog"

# ---------------------------------------------------------
# Hilfsfunktion: Skript relativ ausführen
# ---------------------------------------------------------
function Run-RelativeScript {
    param([string]$RelativePath)

    try {
        $FullPath = Join-Path $PSScriptRoot $RelativePath
        $FullPath = (Resolve-Path $FullPath).Path

        if (Test-Path $FullPath) {
            Write-Log -Level INFO -Message "Starte Script: $FullPath"
            powershell.exe -ExecutionPolicy Bypass -File $FullPath
        }
        else {
            Write-Log -Level ERROR -Message "Script nicht gefunden: $FullPath"
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler beim Ausführen von $RelativePath – $_"
    }
}

# ---------------------------------------------------------
# Hilfsfunktion: Registry-Werte prüfen
# ---------------------------------------------------------
function Test-PolicyValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Expected
    )

    if (-not (Test-Path $Path)) {
        Write-Log -Level WARN -Message "Pfad fehlt: $Path"
        return $false
    }

    $actual = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name

    if ($actual -ne $Expected) {
        Write-Log -Level WARN -Message "Abweichung erkannt: $Path\$Name (Ist: $actual | Soll: $Expected)"
        return $false
    }

    return $true
}

# ---------------------------------------------------------
# STARTUP-WATCHDOG
# ---------------------------------------------------------
Write-Log -Level INFO -Message "Starte Startup-Watchdog"

Run-RelativeScript "..\Programme\10020115_Win_Log_Software.ps1"
Run-RelativeScript "..\Update\10020115_Win_UpdateScript.ps1"

Write-Log -Level INFO -Message "Startup-Watchdog abgeschlossen"

# ---------------------------------------------------------
# GPO-WATCHDOG
# ---------------------------------------------------------
Write-Log -Level INFO -Message "Starte GPO-Watchdog Prüfung"

$Checks = @(
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"; Name="NoDispAppearancePage"; Expected=1 },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="NoThemesTab"; Expected=1 },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"; Name="NoChangingWallPaper"; Expected=1 },

    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall"; Name="NoAddRemovePrograms"; Expected=1 },

    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"; Name="NoChangingStartMenuBackground"; Expected=1 },

    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"; Name="DisableMSI"; Expected=2 },

    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"; Name="RemoveWindowsStore"; Expected=1 },

    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"; Name="MinimumPINLength"; Expected=8 },
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"; Name="Digits"; Expected=1 },
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"; Name="LowercaseLetters"; Expected=1 },
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"; Name="UppercaseLetters"; Expected=1 },
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"; Name="SpecialCharacters"; Expected=1 },

    @{ Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"; Name="Manufacturer"; Expected="DLRG-Jugend Andernach | EDV & Technik" },

    @{ Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="legalnoticecaption"; Expected="DLRG-Jugend Andernach – IT Sicherheitshinweis" }
)

$PolicyMismatch = $false

foreach ($check in $Checks) {
    if (-not (Test-PolicyValue @check)) {
        $PolicyMismatch = $true
    }
}

if ($PolicyMismatch -eq $false) {
    Write-Log -Level INFO -Message "Alle Richtlinien korrekt. Beende mit ExitCode 0."
    exit 0
}

Write-Log -Level WARN -Message "Abweichungen erkannt - GPO-Skripte werden erneut ausgeführt."

# ---------------------------------------------------------
# GPO-Skripte erneut anwenden
# ---------------------------------------------------------
$ScriptFolder = "C:\Programme\PowerShellScripte\Richtlinien\"

$Scripts = @(
    "10020115_Win_R_SystemHilfe.ps1",
    "10020115_Win_R_WinInstallStore.ps1",
    "10020115_Win_R_SoftwareInstallUninstall.ps1",
    "10020115_Win_R_Personalisierung.ps1",
    "10020115_Win_R_Passwort.ps1",
    "10020115_Win_R_DesktopMenue.ps1",
    "10020115_Win_R_BackgroundDesign.ps1"
)

foreach ($script in $Scripts) {
    $full = Join-Path $ScriptFolder $script
    if (Test-Path $full) {
        Write-Log -Level INFO -Message "Führe erneut aus: $script"
        powershell.exe -ExecutionPolicy Bypass -File $full
    } else {
        Write-Log -Level ERROR -Message "Script fehlt: $full"
    }
}

Write-Log -Level INFO -Message "GPO-Wiederherstellung abgeschlossen"
exit 0