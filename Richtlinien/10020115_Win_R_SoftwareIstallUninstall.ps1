# ------------------------------------------------------------
# GLOBAL ERROR HANDLING – ALLE FEHLER AUTOMATISCH INS LOG
# ------------------------------------------------------------

# Alle Fehler als "terminierend" behandeln
$ErrorActionPreference = "Stop"
$Global:PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Globaler Fehler-Logger
Register-EngineEvent PowerShell.OnScriptError -Action {
    $msg = $_.SourceArgs[0].Exception.Message
    Write-Log -Level "ERROR" -Message "PowerShell-Fehler: $msg"
} | Out-Null


# ------------------------------------------------------------
# Logging-Modul laden
# ------------------------------------------------------------

$modulePath = "C:\Users\Public\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"
Write-Log -Level INFO -Message "Starte Benutzerkonfiguration Installationen kontrollieren"


# ------------------------------------------------------------
# 1. Admin-Key prüfen
# ------------------------------------------------------------

$AdminKey = "C:\ProgramData\AdminInstall.key"

try {
    if (Test-Path $AdminKey) {
        Write-Log -Level INFO -Message "Admin-Key gefunden – Installationen werden ERLAUBT"
        $AllowInstall = $true
    }
    else {
        Write-Log -Level INFO -Message "Kein Admin-Key – Installationen werden BLOCKIERT"
        $AllowInstall = $false
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Prüfen des Admin-Keys: $($_.Exception.Message)"
}


# ------------------------------------------------------------
# 2. Software Restriction Policies (SRP) konfigurieren
# ------------------------------------------------------------

$SRPBase = "HKLM:\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers"

try {
    New-Item $SRPBase -Force | Out-Null

    Set-ItemProperty -Path $SRPBase -Name "PolicyScope" -Value 0 -Type DWord
    Set-ItemProperty -Path $SRPBase -Name "TransparentEnabled" -Value 1 -Type DWord
    Set-ItemProperty -Path $SRPBase -Name "AuthenticodeEnabled" -Value 0 -Type DWord

    Write-Log -Level INFO -Message "SRP-Basiswerte gesetzt"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen der SRP-Basiswerte: $($_.Exception.Message)"
}


# ------------------------------------------------------------
# 3. Installationen erlauben oder blockieren
# ------------------------------------------------------------

try {
    if ($AllowInstall) {
        # 0x40000 = Unrestricted
        Set-ItemProperty -Path $SRPBase -Name "DefaultLevel" -Value 0x40000 -Type DWord
        Write-Log -Level INFO -Message "SRP: Installationen sind ERLAUBT"
    }
    else {
        # 0x0 = Disallowed
        Set-ItemProperty -Path $SRPBase -Name "DefaultLevel" -Value 0x0 -Type DWord
        Write-Log -Level INFO -Message "SRP: Installationen sind BLOCKIERT"
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Setzen der Installationsrichtlinie: $($_.Exception.Message)"
}


# ------------------------------------------------------------
# 4. Optional: Einstellungen & Deinstallation verstecken
# ------------------------------------------------------------

# Apps & Features ausblenden
try {
    $SettingsVisibility = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    New-Item $SettingsVisibility -Force | Out-Null
    Set-ItemProperty -Path $SettingsVisibility -Name "SettingsPageVisibility" -Value "hide:appsfeatures" -Type String
    Write-Log -Level INFO -Message "Apps & Features ausgeblendet"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Ausblenden von Apps & Features: $($_.Exception.Message)"
}

# UWP-App-Deinstallation blockieren
try {
    $UwpPolicy = "HKCU:\Software\Policies\Microsoft\Windows\Appx"
    New-Item $UwpPolicy -Force | Out-Null
    Set-ItemProperty -Path $UwpPolicy -Name "BlockRemoval" -Value 1 -Type DWord
    Write-Log -Level INFO -Message "UWP-App-Deinstallation blockiert"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Blockieren der UWP-Deinstallation: $($_.Exception.Message)"
}

# Klassische Programme: Deinstallation blockieren
try {
    $UninstallPolicy = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall"
    New-Item $UninstallPolicy -Force | Out-Null
    Set-ItemProperty -Path $UninstallPolicy -Name "NoAddRemovePrograms" -Value 1 -Type DWord
    Write-Log -Level INFO -Message "Deinstallation klassischer Programme blockiert"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Blockieren klassischer Deinstallationen: $($_.Exception.Message)"
}

# Systemsteuerung Programme blockieren
try {
    $SystemPolicy = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel"
    New-Item $SystemPolicy -Force | Out-Null
    Set-ItemProperty -Path $SystemPolicy -Name "DisableProgramsControlPanel" -Value 1 -Type DWord
    Write-Log -Level INFO -Message "Zugriff auf Programme/Systemsteuerung blockiert"
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Blockieren der Systemsteuerung: $($_.Exception.Message)"
}


# ------------------------------------------------------------
# Fertig
# ------------------------------------------------------------

Write-Log -Level INFO -Message "Benutzerkonfiguration abgeschlossen – Installationen kontrolliert"