#!/bin/bash

# Beispiel: Sammeln der CPU-Temperatur (funktioniert auf RPi)
TEMPERATURE=$(vcgencmd measure_temp | grep -o '[0-9]*\.[0-9]*')

# Generieren der HTML-Datei
cat <<EOF > /var/www/html/system_data.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="300">
    <title>System Data</title>
</head>
<body>
    <h1>System Data</h1>
    <p>CPU Temperature: ${TEMPERATURE}°C</p>
</body>
</html>
EOF
