# Quelle und Ziel definieren
$Source = "C:\Programme\Zu\VerstecktemOrdner"
$Destination = "C:\Programme\10020115_WinScripts\"

# Zielordner erstellen, falls nicht vorhanden
if (!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
}

# Ordner rekursiv kopieren – auch versteckte Dateien
Copy-Item -Path $Source -Destination $Destination -Recurse -Force

# Alle Dateien und Ordner im Ziel sichtbar machen
Get-ChildItem -Path $Destination -Recurse -Force | ForEach-Object {
    # Attribute "Hidden" und "System" entfernen
    $_.Attributes = 'Normal'
}

# Auch den Zielordner selbst sichtbar machen
(Get-Item $Destination).Attributes = 'Normal'

Write-Host "Kopieren abgeschlossen. Alle Dateien und Ordner sind jetzt sichtbar."