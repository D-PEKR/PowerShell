<#
.SYNOPSIS
    Führt Windows Updates, Treiberupdates und Software-Updates durch.
#>

# --- Hintergrundmodus abfragen ---
$runInBackground = Read-Host "Soll das Skript im Hintergrund ausgeführt werden? (j/n)"

if ($runInBackground -eq "j") {
    Write-Host "Starte Skript im Hintergrund..."

    # Pfad des aktuellen Skripts ermitteln
    $scriptPath = $MyInvocation.MyCommand.Path

    # Hintergrundjob starten
    Start-Job -ScriptBlock {
        param($path)
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path
    } -ArgumentList $scriptPath | Out-Null

    Write-Host "Das Skript läuft nun im Hintergrund. Log-Datei: $env:ProgramData\PowerShellScript\update_log.txt"
    exit
}

# --- Setzen der Berechtigung für die Ausführung ---
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# --- Einstellungen ---
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$LogFile = "$env:ProgramData\PowerShellScript\update_log_$timestamp.txt"
$AutoReboot = $true


# --- Logging Funktion ---
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp - $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $line
}

# --- Sicherstellen, dass Log-Verzeichnis existiert ---
$logDir = Split-Path $LogFile
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# --- PSWindowsUpdate installieren falls nötig ---
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Log "PSWindowsUpdate wird installiert..." "Cyan"
    try {
        Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
        Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
    } catch {
        Write-Log "Fehler bei der Installation von PSWindowsUpdate: $_" "Red"
        exit 1
    }
}

Import-Module PSWindowsUpdate

# --- Windows Updates suchen ---
Write-Log "Suche nach Windows Updates und Treiberupdates..." "Cyan"
$updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction SilentlyContinue

if (-not $updates -or $updates.Count -eq 0) {
    Write-Log "Keine Windows Updates verfügbar." "Green"
} else {
    Write-Log "Gefundene Updates:" "Yellow"
    $updates | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Log $_ }
    
    Write-Log "Installiere Updates..." "Cyan"
    if ($AutoReboot) {
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -ErrorAction SilentlyContinue
    } else {
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue
    }
    Write-Log "Windows Updates abgeschlossen." "Green"
}

# --- Treiberupdates aktivieren ---
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" `
    -Name "SearchOrderConfig" -Value 1
Write-Log "Treiberupdates aktiviert." "Green"

# --- Winget Software-Updates ---
Write-Log "Starte Software-Updates..." "Cyan"
try {
    winget source update
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Log "Software-Updates abgeschlossen." "Green"
} catch {
    Write-Log "Fehler bei Winget-Updates: $_" "Red"
}

Write-Log "Update-Skript erfolgreich beendet." "Green"