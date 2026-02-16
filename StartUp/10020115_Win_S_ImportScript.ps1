# Quelle und Ziel definieren
$Source = "C:\Users\Win11ProTest\DLRG\DLRG OG Andernach Projekte-Jugendnotebooks - Jugendnotebooks\Win11_C"
$Destination = "C:\Program Files\10020115_WinScripts\"

# Zielordner löschen, falls vorhanden
if (Test-Path $Destination) {
    Write-Host "Lösche vorhandenen Zielordner..."
    Remove-Item -Path $Destination -Recurse -Force
}

# Zielordner neu erstellen
Write-Host "Erstelle Zielordner..."
New-Item -ItemType Directory -Path $Destination | Out-Null

# Ordner rekursiv kopieren – inklusive versteckter Dateien
Write-Host "Kopiere Dateien..."
Copy-Item -Path $Source -Destination $Destination -Recurse -Force

# Alle Dateien und Ordner im Ziel sichtbar machen
Write-Host "Entferne versteckte Attribute..."
Get-ChildItem -Path $Destination -Recurse -Force | ForEach-Object {
    $_.Attributes = 'Normal'
}

# Auch den Zielordner selbst sichtbar machen
(Get-Item $Destination).Attributes = 'Normal'

Write-Host "Kopieren abgeschlossen. Alle Dateien und Ordner sind jetzt sichtbar."