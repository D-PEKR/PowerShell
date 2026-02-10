Import-Module "$PSScriptRoot\Logging.psm1"
Initialize-Logger -Level "DEBUG"

Write-Log -Level INFO -Message "Erfasse installierte Programme (64-bit & 32-bit)..."

$path64 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$path32 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

function Get-InstalledPrograms {
    param([string]$RegistryPath)

    if (Test-Path $RegistryPath) {
        Get-ChildItem $RegistryPath | ForEach-Object {
            $props = Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue
            if ($props.DisplayName) {
                [PSCustomObject]@{
                    Name        = $props.DisplayName
                    Version     = $props.DisplayVersion
                    Publisher   = $props.Publisher
                    InstallDate = $props.InstallDate
                }
            }
        }
    }
}

$programs64 = Get-InstalledPrograms -RegistryPath $path64
$programs32 = Get-InstalledPrograms -RegistryPath $path32

$allPrograms = $programs64 + $programs32

if ($allPrograms.Count -eq 0) {
    Write-Log -Level WARN -Message "Keine installierten Programme gefunden."
}
else {
    Write-Log -Level INFO -Message "Installierte Programme gefunden: $($allPrograms.Count)"

    foreach ($program in $allPrograms) {
        $line = "Name='$($program.Name)' Version='$($program.Version)' Publisher='$($program.Publisher)' InstallDate='$($program.InstallDate)'"
        Write-Log -Level DEBUG -Message $line
    }
}

Write-Log -Level INFO -Message "Software-Inventur abgeschlossen."
