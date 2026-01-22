
# Einstellungen

$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$LogDir    = "$env:ProgramData\PowerShellScript"
$LogFile   = Join-Path $LogDir "gpo_log_$timestamp.txt"
$AutoReboot = $false   # Optional: automatischer Neustart

# Logging

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("White","Green","Yellow","Red","Cyan")][string]$Color = "White"
    )

    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$ts - $Message"

    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $line
}

# Log-Verzeichnis sicherstellen

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Admin-Prüfung

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Log "Dieses Skript muss als Administrator ausgeführt werden." -Color Red
    exit 1
}

# Registry-Hilfsfunktionen
function New-RegistryKeyIfNotExists {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
        Write-Log "Registry-Key erstellt: $Path" -Color Cyan
    }
}

function Set-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][ValidateSet("String","DWord")][string]$Type
    )

    Try {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
        Write-Log "Wert gesetzt: $Path → $Name = $Value" -Color Green
    }
    Catch {
        Write-Log ("Fehler beim Setzen von {0} in {1}: {2}" -f $Name, $Path, $_) -Color Red
    }
}

# 1) Desktop-Hintergrund sperren (HKCU)

$desktopPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
)

foreach ($path in $desktopPaths) {
    New-RegistryKeyIfNotExists -Path $path
    Set-RegistryValue -Path $path -Name "NoChangingWallpaper"  -Value 1 -Type DWord
    Set-RegistryValue -Path $path -Name "NoChangingWallPaper"  -Value 1 -Type DWord
}

# 2) Sperrbildschirm sperren (HKLM)

$lockPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
New-RegistryKeyIfNotExists -Path $lockPath
Set-RegistryValue -Path $lockPath -Name "NoChangingLockScreen" -Value 1 -Type DWord

# Optional:
# Set-RegistryValue -Path $lockPath -Name "LockScreenImage" -Value "C:\Windows\Web\Wallpaper\MyLock.jpg" -Type String

# Richtlinien aktualisieren

Write-Log "Richtlinien werden aktualisiert..." -Color Yellow

Try {
    gpupdate /target:computer /force | Out-Null
    gpupdate /target:user /force | Out-Null
    Write-Log "gpupdate erfolgreich ausgeführt." -Color Green
}
Catch {
    Write-Log "gpupdate fehlgeschlagen: $_" -Color Red
}

# Optionaler Neustart

if ($AutoReboot) {
    Write-Log "System wird in 10 Sekunden neu gestartet..." -Color Yellow
    Start-Sleep -Seconds 10
    Restart-Computer -Force
}

Write-Log "Alle Policy-Registrywerte wurden erfolgreich gesetzt." -Color Green
Write-Host "`nEin Ab-/Anmelden oder Neustart kann erforderlich sein." -ForegroundColor Cyan