# Pfade
$baseDir = 'C:\Users\Public\10020115_WinScripte'
$counterFile = Join-Path $baseDir 'counter.txt'
$lastDateFile = Join-Path $baseDir 'lastincrement.txt'

# Sicherstellen, dass Verzeichnis existiert
if (-not (Test-Path -Path $baseDir)) {
    New-Item -Path $baseDir -ItemType Directory -Force | Out-Null
}

# Hilfsfunktion: lese Zahl aus Datei, sonst 0
function Get-CounterValue {
    param($path)
    if (Test-Path -Path $path) {
        $text = Get-Content -Path $path -ErrorAction SilentlyContinue
        if ($text -match '^\s*\d+\s*$') { return [int]$text.Trim() }
    }
    return 0
}

# Hilfsfunktion: schreibe Zahl in Datei (überschreibt vorherige)
function Set-CounterValue {
    param($path, $value)
    $value.ToString() | Out-File -FilePath $path -Encoding UTF8 -Force
}

# Hilfsfunktion: lese Datum aus Datei (yyyy-MM-dd), sonst leer
function Get-LastIncrementDate {
    param($path)
    if (Test-Path -Path $path) {
        $txt = Get-Content -Path $path -ErrorAction SilentlyContinue
        try {
            return [datetime]::ParseExact($txt.Trim(), 'yyyy-MM-dd', $null)
        } catch {
            return $null
        }
    }
    return $null
}

# Hilfsfunktion: schreibe heutiges Datum in Datei
function Set-LastIncrementDate {
    param($path)
    (Get-Date).ToString('yyyy-MM-dd') | Out-File -FilePath $path -Encoding UTF8 -Force
}

# Hauptlogik
$currentCounter = Get-CounterValue -path $counterFile
$lastDate = Get-LastIncrementDate -path $lastDateFile
$today = (Get-Date).Date

# Wenn noch nicht heute erhöht, dann erhöhen
if ($null -eq $lastDate -or $lastDate.Date -lt $today) {
    $currentCounter = $currentCounter + 1
    Set-CounterValue -path $counterFile -value $currentCounter
    Set-LastIncrementDate -path $lastDateFile
}

# Wenn Zähler 20 erreicht oder überschreitet -> MessageBox anzeigen
if ($currentCounter -ge 20) {
    Add-Type -AssemblyName System.Windows.Forms
    $title = 'IT & Support'
    $message = 'Dein gerät war mehr als 20x nicht im WLAN, bitte stelle eine WLAN Verbindung her, um dein gerät wieder besser zu schützen.'
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    Set-CounterValue -path $counterFile -value 0
}