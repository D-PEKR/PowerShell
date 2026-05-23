# Ziel-MAC-Adresse
$targetMac = "98-FA-9B-28-B0-22"

Write-Host "Scanne Netzwerk nach MAC-Adresse $targetMac ..."

# ARP-Cache aktualisieren durch Ping-Broadcast
try {
    ping 255.255.255.255 -n 2 | Out-Null
} catch {}

# ARP-Tabelle auslesen
$arp = arp -a

# IP extrahieren
$ip = ($arp | Select-String -Pattern $targetMac -SimpleMatch) `
      -replace ".*\(", "" `
      -replace "\).*", ""

if (-not $ip) {
    Write-Host "Keine IP gefunden. Starte erweiterten Scan..."

    # Lokales Subnetz automatisch bestimmen
    $net = (Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object {$_.IPAddress -notlike "169.*"} |
            Select-Object -First 1).PrefixOrigin

    $ipInfo = Get-NetIPAddress -AddressFamily IPv4 |
              Where-Object {$_.IPAddress -notlike "169.*"} |
              Select-Object -First 1

    $subnet = "$($ipInfo.IPAddress)/$($ipInfo.PrefixLength)"

    Write-Host "Scanne Subnetz $subnet ..."

    # Nmap verwenden, falls installiert
    if (Get-Command nmap -ErrorAction SilentlyContinue) {
        nmap -sn $subnet | Out-Null
    } else {
        Write-Host "Nmap nicht installiert. Führe stattdessen Ping-Sweep aus..."
        for ($i=1; $i -le 254; $i++) {
            ping "$($ipInfo.IPAddress.Substring(0, $ipInfo.IPAddress.LastIndexOf('.')+1))$i" -n 1 -w 5 | Out-Null
        }
    }

    # Erneut ARP prüfen
    $arp = arp -a
    $ip = ($arp | Select-String -Pattern $targetMac -SimpleMatch) `
          -replace ".*\(", "" `
          -replace "\).*", ""
}

if (-not $ip) {
    Write-Host "IP konnte nicht gefunden werden."
    exit
}

Write-Host "Gefundene IP: $ip"
Write-Host "Starte SSH-Verbindung..."

ssh "$env:USERNAME@$ip"
