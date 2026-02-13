param(
    [switch]$RUN_IN_BACKGROUND,
    [string]$LOGFILE
)

# Logging-Modul importieren
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath

if (-not $RUN_IN_BACKGROUND) {

    # Einmaliges Logfile pro Ausführung erzeugen
    $logFileName = "update_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

    # Logger initialisieren
    Initialize-Logger -FileName $logFileName -Level "INFO" -ConsoleOutput $true -MaxSizeMB 5
    Write-Log -Level INFO -Message "Starte Skript im Hintergrund..."

    $scriptPath = $MyInvocation.MyCommand.Path

    # Hintergrundprozess starten (Parameter, keine Environment-Variablen)
    Start-Process powershell.exe `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -RUN_IN_BACKGROUND -LOGFILE `"$logFileName`"" `
        -WindowStyle Hidden

    Write-Log -Level INFO -Message "Skript läuft nun im Hintergrund."
    exit
}

if (-not $LOGFILE) {
    throw "Fehler: LOGFILE wurde nicht übergeben."
}

Initialize-Logger -FileName $LOGFILE -Level "INFO" -ConsoleOutput $true -MaxSizeMB 5
Write-Log -Level INFO -Message "Update-Skript gestartet (Hintergrundmodus)."

# ExecutionPolicy setzen
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Log -Level INFO -Message "PSWindowsUpdate wird installiert..."

    try {
        Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
        Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
        Write-Log -Level INFO -Message "PSWindowsUpdate erfolgreich installiert."
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler bei der Installation von PSWindowsUpdate: $_"
        exit 1
    }
}

Import-Module PSWindowsUpdate

Write-Log -Level INFO -Message "Suche nach Windows Updates..."

$windowsUpdates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction SilentlyContinue |
Where-Object { $_.UpdateType -ne "Driver" }

if (-not $windowsUpdates) {
    Write-Log -Level INFO -Message "Keine Windows Updates gefunden."
}
else {
    Write-Log -Level INFO -Message "Gefundene Windows Updates:"
    $windowsUpdates | ForEach-Object {
        Write-Log -Level INFO -Message ("Windows Update: " + $_.Title)
    }
}

Write-Log -Level INFO -Message "Suche nach Treiberupdates..."

$driverUpdates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction SilentlyContinue |
Where-Object { $_.UpdateType -eq "Driver" }

if (-not $driverUpdates) {
    Write-Log -Level INFO -Message "Keine Treiberupdates gefunden."
}
else {
    Write-Log -Level INFO -Message "Gefundene Treiberupdates:"
    $driverUpdates | ForEach-Object {
        Write-Log -Level INFO -Message ("Treiber: " + $_.Title)
    }
}

if ($windowsUpdates -or $driverUpdates) {
    Write-Log -Level INFO -Message "Installiere Updates (Windows + Treiber)..."

    try {
        $results = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue

        foreach ($res in $results) {
            $msg = "Update: $($res.Title) | Result: $($res.Result)"

            if ($res.HResult) {
                $msg += " | ExitCode: $($res.HResult)"
            }
            else {
                $msg += " | ExitCode: (nicht verfügbar)"
            }


            Write-Log -Level INFO -Message $msg
        }

        Write-Log -Level INFO -Message "Updates abgeschlossen."
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler bei der Installation der Updates: $_"
    }
}
else {
    Write-Log -Level INFO -Message "Keine Updates zur Installation vorhanden."
}

try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" `
        -Name "SearchOrderConfig" -Value 1

    Write-Log -Level INFO -Message "Treiberupdates aktiviert."
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Aktivieren der Treiberupdates: $_"
}

Write-Log -Level INFO -Message "Starte Software-Updates über Winget..."

try {
    winget source update | Out-Null

    # Upgrade-Liste als JSON abrufen
    $upgradeListJson = cmd /c "set LANG=en-US && winget upgrade --accept-source-agreements --accept-package-agreements --output json"
    $upgradeList = $upgradeListJson | ConvertFrom-Json

    if ($upgradeList) {
        foreach ($item in $upgradeList) {
            Write-Log -Level INFO -Message "Upgrade verfügbar: $($item.Id) | $($item.Name) | Installed: $($item.InstalledVersion) → Available: $($item.AvailableVersion)"
        }
    }
    else {
        Write-Log -Level INFO -Message "Keine Software-Updates verfügbar."
    }

    # Updates installieren
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements | Out-Null

    Write-Log -Level INFO -Message "Software-Updates abgeschlossen."
}
catch {
    Write-Log -Level ERROR -Message "Fehler bei Winget-Updates: $_"
}

Write-Log -Level INFO -Message "Update-Skript erfolgreich beendet."
