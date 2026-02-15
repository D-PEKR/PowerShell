# Modul laden
$modulePath = "C:\Program Files\10020115_WinScripts\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"

Write-Log -Level INFO -Message "=== Klassische Programme ==="

$classicPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

try {
    $classicApps = Get-ItemProperty $classicPaths |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher |
        Sort-Object DisplayName

    foreach ($app in $classicApps) {
        Write-Log -Level INFO -Message "Programm: $($app.DisplayName) | Version: $($app.DisplayVersion) | Publisher: $($app.Publisher)"
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Auslesen klassischer Programme: $($_.Exception.Message)"
}

Write-Log -Level INFO -Message "=== UWP / Store Apps ==="

try {
    $uwpApps = Get-AppxPackage |
        Select-Object Name, Version, Publisher |
        Sort-Object Name

    foreach ($app in $uwpApps) {
        Write-Log -Level INFO -Message "UWP-App: $($app.Name) | Version: $($app.Version) | Publisher: $($app.Publisher)"
    }
}
catch {
    Write-Log -Level ERROR -Message "Fehler beim Auslesen der UWP-Apps: $($_.Exception.Message)"
}