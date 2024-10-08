#!/bin/bash

# Ausgabe-HTML-Datei
OUTPUT_FILE="/var/www/html/system_data.html"

# Funktion zur Formatierung der CPU-Temperatur
format_temperature() {
    local temp=$1
    if (( $(echo "$temp > 70" | bc -l) )); then
        echo "<span class='temp high'>$temp</span>"
    elif (( $(echo "$temp > 50" | bc -l) )); then
        echo "<span class='temp medium'>$temp</span>"
    else
        echo "<span class='temp normal'>$temp</span>"
    fi
}

# Erstelle die HTML-Datei mit eingebettetem CSS
cat << EOF > $OUTPUT_FILE
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Systemdaten</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #2980b9;
            margin-top: 30px;
        }
        .card {
            background-color: #fff;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            padding: 20px;
            margin-bottom: 20px;
        }
        .temp {
            font-weight: bold;
        }
        .temp.high { color: #e74c3c; }
        .temp.medium { color: #f39c12; }
        .temp.normal { color: #27ae60; }
        pre {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        @media (max-width: 600px) {
            body {
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <h1>Systemdaten</h1>

    <div class="card">
        <h2>Hostname</h2>
        <p>$(hostname)</p>
    </div>

    <div class="card">
        <h2>Aktuelle Benutzer</h2>
        <pre>$(who)</pre>
    </div>

    <div class="card">
        <h2>Systemlast</h2>
        <p>$(uptime | awk -F'load average:' '{ print $2 }' | cut -d',' -f1)</p>
    </div>

    <div class="card">
        <h2>CPU-Informationen</h2>
        <pre>$(lscpu)</pre>
    </div>

    <div class="card">
        <h2>Speicherinformationen</h2>
        <pre>$(free -h)</pre>
    </div>

    <div class="card">
        <h2>CPU-Temperatur</h2>
EOF
if command -v sensors &> /dev/null; then
    echo "<pre>" >> $OUTPUT_FILE
    sensors | while IFS= read -r line; do
        if [[ $line == *"Package id 0:"* ]]; then
            temp=$(echo $line | awk '{print $4}' | tr -d '+°C')
            echo "$(format_temperature $temp)" >> $OUTPUT_FILE
        elif [[ $line == *"Core "* ]]; then
            core=$(echo $line | awk '{print $2}' | tr -d ':')
            temp=$(echo $line | awk '{print $3}' | tr -d '+°C')
            echo "Core $core: $(format_temperature $temp)" >> $OUTPUT_FILE
        else
            echo "$line" >> $OUTPUT_FILE
        fi
    done
    echo "</pre>" >> $OUTPUT_FILE
else
    echo "<p>lm-sensors ist nicht installiert.</p>" >> $OUTPUT_FILE
fi

# Schließe die HTML-Tags
echo "</div></body></html>" >> $OUTPUT_FILE

echo "Systeminformationen wurden in $OUTPUT_FILE geschrieben."
