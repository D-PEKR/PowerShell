# Skript immer im Hintergrund starten

if (-not $env:RUN_IN_BACKGROUND) {
    Write-Log -Level INFO -Message "Starte Skript im Hintergrund..."

    $scriptPath = $MyInvocation.MyCommand.Path

    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -RUN_IN_BACKGROUND 1" -WindowStyle Hidden

    Write-Log -Level INFO -Message "Skript läuft nun im Hintergrund."
    exit
}


# ExecutionPolicy setzen

Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Log -Level INFO -Message "Update-Skript gestartet."


# PSWindowsUpdate installieren falls nötig

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


# Windows Updates suchen

Write-Log -Level INFO -Message "Suche nach Windows Updates und Treiberupdates..."

$updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction SilentlyContinue

if (-not $updates -or $updates.Count -eq 0) {
    Write-Log -Level INFO -Message "Keine Windows Updates verfügbar."
}
else {
    Write-Log -Level INFO -Message "Gefundene Updates:"
    $updates | Format-Table -AutoSize | Out-String | ForEach-Object {
        Write-Log -Level DEBUG -Message $_
    }

    Write-Log -Level INFO -Message "Installiere Updates (ohne Neustart)..."

    try {
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue
        Write-Log -Level INFO -Message "Windows Updates abgeschlossen."
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler bei der Installation der Updates: $_"
    }
}


# Treiberupdates aktivieren

try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" `
        -Name "SearchOrderConfig" -Value 1

    Write-Log -Level INFO -Message "Treiberupdates aktiviert."
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Aktivieren der Treiberupdates: $_"
}


# Winget Software-Updates

Write-Log -Level INFO -Message "Starte Software-Updates über Winget..."

try {
    winget source update | Out-Null
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements | Out-Null

    Write-Log -Level INFO -Message "Software-Updates abgeschlossen."
}
catch {
    Write-Log -Level ERROR -Message "Fehler bei Winget-Updates: $_"
}

Write-Log -Level INFO -Message "Update-Skript erfolgreich beendet."