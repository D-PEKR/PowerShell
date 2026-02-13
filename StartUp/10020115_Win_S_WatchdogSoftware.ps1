$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Logging.psm1"
Import-Module $modulePath
Initialize-Logger -FileName "Startup_Watchdog.log" -Level "INFO"

Write-Log -Level INFO -Message "Starte Startup-Watchdog"

# Hilfsfunktion: Skript ausführen
function Run-RelativeScript {
    param(
        [string]$RelativePath
    )

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

# Auszuführende Skripte

Run-RelativeScript "..\Programme\10020115_Win_Log_Software.ps1"
Run-RelativeScript "..\Update\10020115_Win_UpdateScript.ps1"

Write-Log -Level INFO -Message "Startup-Watchdog abgeschlossen"
exit 0