#!/bin/bash

# Ausgabe-HTML-Datei
OUTPUT_FILE="/var/www/html/system_data.html"

# Erstelle die HTML-Datei und schreibe den Header
echo "<html><head><title>Systemdaten</title></head><body>" > $OUTPUT_FILE
echo "<h1>Systemdaten</h1>" >> $OUTPUT_FILE

# Füge Hostname hinzu
echo "<h2>Hostname</h2>" >> $OUTPUT_FILE
echo "<p>$(hostname)</p>" >> $OUTPUT_FILE

# Füge aktuelle Benutzer hinzu
echo "<h2>Aktuelle Benutzer</h2>" >> $OUTPUT_FILE
echo "<p>$(who)</p>" >> $OUTPUT_FILE

# Füge Systemlast hinzu
echo "<h2>Systemlast</h2>" >> $OUTPUT_FILE
echo "<p>$(uptime | awk -F'load average:' '{ print $2 }' | cut -d',' -f1)</p>" >> $OUTPUT_FILE

# Füge CPU-Informationen hinzu
echo "<h2>CPU-Informationen</h2>" >> $OUTPUT_FILE
echo "<pre>$(lscpu)</pre>" >> $OUTPUT_FILE

# Füge Speicherinformationen hinzu
echo "<h2>Speicherinformationen</h2>" >> $OUTPUT_FILE
echo "<pre>$(free -h)</pre>" >> $OUTPUT_FILE

# Füge CPU-Temperatur hinzu
echo "<h2>CPU-Temperatur</h2>" >> $OUTPUT_FILE
if command -v sensors &> /dev/null; then
    echo "<pre>$(sensors)</pre>" >> $OUTPUT_FILE
else
    echo "<p>lm-sensors ist nicht installiert.</p>" >> $OUTPUT_FILE
fi

# Schließe die HTML-Tags
echo "</body></html>" >> $OUTPUT_FILE

echo "Systeminformationen wurden in $OUTPUT_FILE geschrieben."
