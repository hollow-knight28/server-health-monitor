set -e

LOG_FILE="logs/monitor.log"

log(){
	echo "$(date) - $1" >> "$LOG_FILE"
}

echo "================="
echo " Linux Server Health Monitor "
echo "================="

log "Monitor started"

echo "Monitor started"

while true
do

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
MEMORY_USAGE=$(free -m | awk '/Mem:/ {print ($3/$2)*100}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

if systemctl is-active --quiet ssh; then
	echo "SSH Status: RUNNING"
	log "SSH Staus: RUNNING"
else
	echo "SSH Status: NOT RUNNING"
	log "SSH Status: NOT RUNNING"
fi

if ping -c 3 -W 2 8.8.8.8 > /dev/null 2>&1; then
	echo "Network Status: UP"
	log "Network Status: UP"
else
	echo "Network Status: DOWN"
	log "Network Status: DOWN"
fi

echo "Cpu Usage: ${CPPU_USAGE}%"
log "Cpu usage: ${CPU_USAGE}%"

if awk -v cpu="$CPU_USAGE" 'BEGIN { exit !(cpu > 80) }' </dev/null; then
    echo "WARNING: High CPU usage"
    log "WARNING: High CPU usage"
else
    echo "CPU usage normal"
    log "CPU usage normal"
fi

echo "Memory Usage: ${MEMORY_USAGE}%"
log "Memory Usage: ${MEMORY_USAGE}%"

if awk -v mem="$MEMORY_USAGE" 'BEGIN { exit !(mem > 80) }' </dev/null; then
	echo "WARNING: High memory usage"
	log "WARNING: High memory usage"
else
	echo "Memory usage normal"
	log "Mmemory usage normal"
fi

echo "Disk Usage: ${DISK_USAGE}%"
log "Disk Usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -gt 80 ]; then
	echo "Disk usage: High disk usage"
	log "Disk usage: High disk usage"
else
	echo "Disk usage nornmal"
	log "Disk usage normal"
fi

done 
sleep 30


