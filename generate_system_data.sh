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
        .info-grid {
            display: grid;
            grid-template-columns: auto 1fr;
            gap: 10px;
            align-items: center;
        }
        .info-label {
            font-weight: bold;
            color: #2c3e50;
        }
        .info-value {
            color: #34495e;
        }
        .icon {
            width: 20px;
            height: 20px;
            margin-right: 10px;
            vertical-align: middle;
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
            <div class="info-grid">
                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                        <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                        <line x1="6" y1="6" x2="6.01" y2="6"></line>
                        <line x1="6" y1="18" x2="6.01" y2="18"></line>
                    </svg>
                    Hostname:
                </span>
                <span class="info-value">$(hostname)</span>

                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                        <polyline points="9 22 9 12 15 12 15 22"></polyline>
                    </svg>
                    Betriebssystem:
                </span>
                <span class="info-value">$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)</span>

                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="16 18 22 12 16 6"></polyline>
                        <polyline points="8 6 2 12 8 18"></polyline>
                    </svg>
                    Kernel:
                </span>
                <span class="info-value">$(uname -r)</span>

                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    Uptime:
                </span>
                <span class="info-value">$(uptime -p)</span>
            </div>
        </div>

        <div class="card">
            <h2>Systemlast</h2>
            <div class="chart-container">
                <canvas id="loadChart"></canvas>
            </div>
            
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
            <pre id="userList">
$(cut -d: -f1 /etc/passwd | head -n 5)
            </pre>
            <button class="toggle-btn" onclick="toggleVisibility('fullUserList')">Vollständige Benutzer anzeigen</button>
            <pre id="fullUserList" class="hidden">$(cut -d: -f1 /etc/passwd)</pre>
        </div>

        <div class="card">
            <h2>CPU-Informationen</h2>
            <div class="info-grid">
                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="4" y="4" width="16" height="16" rx="2" ry="2"></rect>
                        <rect x="9" y="9" width="6" height="6"></rect>
                        <line x1="9" y1="1" x2="9" y2="4"></line>
                        <line x1="15" y1="1" x2="15" y2="4"></line>
                        <line x1="9" y1="20" x2="9" y2="23"></line>
                        <line x1="15" y1="20" x2="15" y2="23"></line>
                        <line x1="20" y1="9" x2="23" y2="9"></line>
                        <line x1="20" y1="14" x2="23" y2="14"></line>
                        <line x1="1" y1="9" x2="4" y2="9"></line>
                        <line x1="1" y1="14" x2="4" y2="14"></line>
                    </svg>
                    Modell:
                </span>
                <span class="info-value">$(lscpu | grep "Model name" | cut -d ':' -f2 | xargs)</span>

                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 20V10"></path>
                        <path d="M12 20V4"></path>
                        <path d="M6 20v-6"></path>
                    </svg>
                    Kerne:
                </span>
                <span class="info-value">$(lscpu | grep "CPU(s):" | head -n1 | cut -d ':' -f2 | xargs)</span>

                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
                        <polyline points="2 17 12 22 22 17"></polyline>
                        <polyline points="2 12 12 17 22 12"></polyline>
                    </svg>
                    Architektur:
                </span>
                <span class="info-value">$(uname -m)</span>

                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    Max. Taktrate:
                </span>
                <span class="info-value">$(lscpu | grep "CPU max MHz" | cut -d ':' -f2 | xargs) MHz</span>
            </div>
            <button class="toggle-btn" onclick="toggleVisibility('fullCpuInfo')">Vollständige Infos</button>
            <pre id="fullCpuInfo" class="hidden">$(lscpu)</pre>
        </div>

        <div class="card">
            <h2>Festplatteninformationen</h2>
            <pre>$(df -h)</pre>
        </div>

        <div class="card">
            <h2>Netzwerkinformationen</h2>
            <div class="info-grid">
                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                        <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                        <line x1="6" y1="6" x2="6.01" y2="6"></line>
                        <line x1="6" y1="18" x2="6.01" y2="18"></line>
                    </svg>
                    IP-Adresse:
                </span>
                <span class="info-value">$(hostname -I | awk '{print $1}')</span>

                <span class="info-label">
                    <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <line x1="2" y1="12" x2="22" y2="12"></line>
                        <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                    </svg>
                    Standard-Gateway:
                </span>
                <span class="info-value">$(ip route | grep default | awk '{print $3}')</span>
            </div>
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
        if [[ $line == *"Core "* ]]; then
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
