#!/bin/bash

# Ausgabe-HTML-Datei
OUTPUT_FILE="/var/www/html/system_data.html"

# Funktion zur Formatierung der CPU-Temperatur
format_temperature() {
    local temp=$1
    if (( $(echo "$temp > 70" | bc -l) )); then
        echo "<span class='temp high'>$temp°C</span>"
    elif (( $(echo "$temp > 50" | bc -l) )); then
        echo "<span class='temp medium'>$temp°C</span>"
    else
        echo "<span class='temp normal'>$temp°C</span>"
    fi
}

# Erstelle die HTML-Datei mit eingebettetem CSS und JavaScript
cat << EOF > $OUTPUT_FILE
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Systemdaten Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f0f2f5;
        }
        h1 {
            color: #2c3e50;
            text-align: center;
            margin-bottom: 30px;
        }
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        .card {
            background-color: #fff;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            padding: 20px;
            transition: transform 0.3s ease;
        }
        .card:hover {
            transform: translateY(-5px);
        }
        .card h2 {
            color: #3498db;
            margin-top: 0;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .temp {
            font-weight: bold;
            padding: 3px 6px;
            border-radius: 3px;
        }
        .temp.high { background-color: #e74c3c; color: white; }
        .temp.medium { background-color: #f39c12; color: white; }
        .temp.normal { background-color: #27ae60; color: white; }
        pre {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-size: 14px;
        }
        .chart-container {
            position: relative;
            height: 200px;
            width: 100%;
        }
        .toggle-btn {
            background-color: #3498db;
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 5px;
            cursor: pointer;
            margin-top: 10px;
        }
        .toggle-btn:hover {
            background-color: #2980b9;
        }
        .hidden {
            display: none;
        }
        @media (max-width: 600px) {
            .dashboard {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <h1>Systemdaten Dashboard</h1>

    <div class="dashboard">
        <div class="card">
            <h2>System-Informationen</h2>
            <p><strong>Hostname:</strong> $(hostname)</p>
            <p><strong>Betriebssystem:</strong> $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)</p>
            <p><strong>Kernel:</strong> $(uname -r)</p>
            <p><strong>Uptime:</strong> $(uptime -p)</p>
        </div>

        <div class="card">
            <h2>Systemlast</h2>
            <div class="chart-container">
                <canvas id="loadChart"></canvas>
            </div>
            <p>Aktuelle Last: $(uptime | awk -F'load average:' '{ print $2 }' | cut -d',' -f1)</p>
            <button class="toggle-btn" onclick="toggleVisibility('fullLoadInfo')">Vollständige Infos</button>
            <pre id="fullLoadInfo" class="hidden">$(uptime)</pre>
        </div>

        <div class="card">
            <h2>Speichernutzung</h2>
            <div class="chart-container">
                <canvas id="memoryChart"></canvas>
            </div>
            <button class="toggle-btn" onclick="toggleVisibility('fullMemoryInfo')">Vollständige Infos</button>
            <pre id="fullMemoryInfo" class="hidden">$(free -h)</pre>
        </div>

        <div class="card">
            <h2>CPU-Temperatur</h2>
            <div id="cpuTemp"></div>
        </div>

        <div class="card">
            <h2>Aktuelle Benutzer</h2>
            <pre>$(who)</pre>
        </div>

        <div class="card">
            <h2>CPU-Informationen</h2>
            <p><strong>Modell:</strong> $(lscpu | grep "Model name" | cut -d ':' -f2 | xargs)</p>
            <p><strong>Kerne:</strong> $(lscpu | grep "CPU(s):" | head -n1 | cut -d ':' -f2 | xargs)</p>
            <p><strong>Architektur:</strong> $(uname -m)</p>
            <p><strong>Max. Taktrate:</strong> $(lscpu | grep "CPU max MHz" | cut -d ':' -f2 | xargs) MHz</p>
            <button class="toggle-btn" onclick="toggleVisibility('fullCpuInfo')">Vollständige Infos</button>
            <pre id="fullCpuInfo" class="hidden">$(lscpu)</pre>
        </div>

        <div class="card">
            <h2>Festplatteninformationen</h2>
            <pre>$(df -h)</pre>
        </div>

        <div class="card">
            <h2>Netzwerkinformationen</h2>
            <p><strong>IP-Adresse:</strong> $(hostname -I | awk '{print $1}')</p>
            <p><strong>Standard-Gateway:</strong> $(ip route | grep default | awk '{print $3}')</p>
            <button class="toggle-btn" onclick="toggleVisibility('fullNetworkInfo')">Vollständige Infos</button>
            <pre id="fullNetworkInfo" class="hidden">$(ifconfig)</pre>
        </div>
    </div>

    <script>
    // Funktion zum Ein-/Ausblenden von Elementen
    function toggleVisibility(id) {
        var element = document.getElementById(id);
        if (element.classList.contains('hidden')) {
            element.classList.remove('hidden');
        } else {
            element.classList.add('hidden');
        }
    }

    // Systemlast-Chart
    const loadCtx = document.getElementById('loadChart').getContext('2d');
    const loadData = '$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/,//g')'.trim().split(' ');
    new Chart(loadCtx, {
        type: 'line',
        data: {
            labels: ['1 min', '5 min', '15 min'],
            datasets: [{
                label: 'Systemlast',
                data: loadData,
                borderColor: 'rgb(75, 192, 192)',
                tension: 0.1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });

    // Speichernutzung-Chart
    const memoryCtx = document.getElementById('memoryChart').getContext('2d');
    const memoryData = '$(free | awk 'NR==2{print $2","$3","$4","$6}')'.split(',');
    new Chart(memoryCtx, {
        type: 'doughnut',
        data: {
            labels: ['Verwendet', 'Frei', 'Puffer/Cache'],
            datasets: [{
                data: [memoryData[1], memoryData[2], memoryData[3]],
                backgroundColor: ['#e74c3c', '#2ecc71', '#3498db']
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
        }
    });

    // CPU-Temperatur
    const cpuTempElement = document.getElementById('cpuTemp');
EOF

# Füge CPU-Temperatur hinzu
if command -v sensors &> /dev/null; then
    echo "cpuTempElement.innerHTML = \`" >> $OUTPUT_FILE
    sensors | while IFS= read -r line; do
        if [[ $line == *"Package id 0:"* ]]; then
            temp=$(echo $line | awk '{print $4}' | tr -d '+°C')
            echo "$(format_temperature $temp)<br>" >> $OUTPUT_FILE
        elif [[ $line == *"Core "* ]]; then
            core=$(echo $line | awk '{print $2}' | tr -d ':')
            temp=$(echo $line | awk '{print $3}' | tr -d '+°C')
            echo "Core $core: $(format_temperature $temp)<br>" >> $OUTPUT_FILE
        fi
    done
    echo "\`;" >> $OUTPUT_FILE
else
    echo "cpuTempElement.innerHTML = 'lm-sensors ist nicht installiert.';" >> $OUTPUT_FILE
fi

# Schließe die HTML-Tags
echo "</script></body></html>" >> $OUTPUT_FILE

echo "Systeminformationen wurden in $OUTPUT_FILE geschrieben."
