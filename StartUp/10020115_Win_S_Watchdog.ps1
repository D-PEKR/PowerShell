# ---------------------------------------------------------
# Logger initialisieren
# ---------------------------------------------------------
$modulePath = "C:\Program Files\10020115_WinScripts\Win11_C\Software\Scripte\Logging.psm1"
Import-Module $modulePath -ErrorAction Stop

Initialize-Logger -Level "INFO"

Write-Log -Level INFO -Message "Starte kombinierten Import- und WatchDog-Prozess."


# ---------------------------------------------------------
# 1. IMPORT-SCHRITT
# ---------------------------------------------------------

$Source = "C:\Users\Win11ProTest\DLRG\DLRG OG Andernach Projekte-Jugendnotebooks - Jugendnotebooks\Win11_C"
$DestinationRoot = "C:\Program Files\10020115_WinScripts"
$Destination = Join-Path $DestinationRoot "Win11_C"

Write-Log -Level INFO -Message "Starte Kopiervorgang für Win11_C"
Write-Log -Level INFO -Message "Quelle: $Source"
Write-Log -Level INFO -Message "Ziel: $Destination"

# Offline-Attribute entfernen
Write-Log -Level INFO -Message "Entferne mögliche Offline-Attribute aus Quelldateien..."
Get-ChildItem $Source -Recurse -Force | ForEach-Object {
    attrib -P $_.FullName 2>$null
}

# Zielordner löschen
if (Test-Path $Destination) {
    Write-Log -Level INFO -Message "Lösche vorhandenen Ordner Win11_C..."
    Remove-Item -Path $Destination -Recurse -Force
    Start-Sleep -Milliseconds 300
} else {
    Write-Log -Level INFO -Message "Ordner Win11_C existiert nicht – kein Löschen notwendig."
}

# Zielordner neu erstellen
Write-Log -Level INFO -Message "Erstelle Zielordner Win11_C..."
New-Item -ItemType Directory -Path $Destination -Force | Out-Null

# Dateien kopieren
Write-Log -Level INFO -Message "Kopiere Dateien nach Win11_C..."
Copy-Item -Path $Source -Destination $Destination -Recurse -Force

# Attribute normalisieren
Write-Log -Level INFO -Message "Entferne versteckte Attribute..."
Get-ChildItem -Path $Destination -Recurse -Force | ForEach-Object {
    $_.Attributes = 'Normal'
}
(Get-Item $Destination).Attributes = 'Normal'

Write-Log -Level INFO -Message "Kopiervorgang abgeschlossen."


# ---------------------------------------------------------
# 2. WARTEN (60 Sekunden)
# ---------------------------------------------------------
Write-Log -Level INFO -Message "Warte 60 Sekunden, bevor WatchDog startet..."
Start-Sleep -Seconds 60


# ---------------------------------------------------------
# 3. WATCHDOG – Skripte rekursiv ausführen
# ---------------------------------------------------------

Write-Log -Level INFO -Message "WatchDog gestartet."

$ScriptRoot = "C:\Program Files\10020115_WinScripts\Win11_C\Software\Scripte"
Write-Log -Level INFO -Message "Suche nach Skripten in: $ScriptRoot"

# Alle PS1-Dateien rekursiv suchen
$Scripts = Get-ChildItem -Path $ScriptRoot -Filter "*.ps1" -Recurse

if ($Scripts.Count -gt 0) {
    foreach ($Script in $Scripts) {
        Write-Log -Level "INFO" -Message "Starte Script: $($Script.FullName)"
        try {
            powershell.exe -ExecutionPolicy Bypass -File $Script.FullName -Wait
            Write-Log -Level "INFO" -Message "Fertig: $($Script.Name)"
        }
        catch {
            Write-Log -Level "ERROR" -Message "Fehler in $($Script.Name): $_"
        }
    }
} else {
    Write-Log -Level "WARN" -Message "Keine Skripte gefunden."
}

Write-Log -Level INFO -Message "WatchDog abgeschlossen."
Write-Log -Level INFO -Message "Gesamter Prozess beendet."