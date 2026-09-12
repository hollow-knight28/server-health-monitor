set -eou pipefail

LOG_FILE="logs/monitor.log"

CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80
MAX_LOG_SIZE=102400

REQUIRED_COMMANDS=("top" "awk" "free" "df" "ping" "systemctl")

log() {
    echo "$(date) - $1" >> "$LOG_FILE"
}

rotate_log() {
	if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -ge "$MAX_LOG_SIZE" ]; then
		mv "$LOG_FILE" "${LOG_FILE}.old"
		touch "$LOG_FILE"
		log "Log rotated"
	fi
}

trap 'echo "Monitor stopped by user"; log "Monitor stopped by user"; exit 0' INT

echo "=================="
echo " Linux Server Health Monitor "
echo "=================="

for cmd in "${REQUIRED_COMMANDS[@]}"
do
	if ! command -v "$cmd" > /dev/null 2>&1; then
		echo "ERROR: Required commands not found: $cmd"
		log "ERROR: Required commands not found: $cmd"
		exit 1
	fi
done

echo "Monitor started"

log "Monitor started"

while true
do

    STATUS="OK"
    rotate_log

    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

    echo "CPU Usage: ${CPU_USAGE}%"
    log "CPU Usage: ${CPU_USAGE}%"

    if awk -v cpu="$CPU_USAGE" -v threshold="$CPU_THRESHOLD" 'BEGIN { exit !(cpu > threshold) }' </dev/null; then    
        echo "WARNING: High CPU usage"
        log "WARNING: High CPU usage"
	STATUS="WARNING"
    else
        echo "CPU usage normal"
        log "CPU usage normal"
    fi



    MEMORY_USAGE=$(free -m | awk '/Mem:/ {print ($3/$2)*100}')

    echo "Memory Usage: ${MEMORY_USAGE}%"
    log "Memory Usage: ${MEMORY_USAGE}%"

    if awk -v mem="$MEMORY_USAGE" -v threshold="$MEMORY_THRESHOLD" 'BEGIN { exit !(mem > threshold) }' </dev/null; then
        echo "WARNING: High memory usage"
        log "WARNING: High memory usage"
	STATUS="WARNING"
    else
        echo "Memory usage normal"
        log "Memory usage normal"
    fi


    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

    echo "Disk Usage: ${DISK_USAGE}%"
    log "Disk Usage: ${DISK_USAGE}%"

    if [ "$DISK_USAGE" -gt  "$DISK_THRESHOLD" ]; then
        echo "WARNING: High disk usage"
        log "WARNING: High disk usage"
	STATUS="WARNING"
    else
        echo "Disk usage normal"
        log "Disk usage normal"
    fi


    if systemctl is-active --quiet ssh; then
        echo "SSH Status: RUNNING"
        log "SSH Status: RUNNING"
    else
        echo "SSH Status: NOT RUNNING"
        log "SSH Status: NOT RUNNING"
	STATUS="WARNING"
    fi


    if ping -c 3 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo "Network Status: UP"
        log "Network Status: UP"
    else
        echo "Network Status: DOWN"
        log "Network Status: DOWN"
	STATUS="WARNING"
    fi
    
    echo "-----------------------------"
    echo "OVERALL STATUS: $STATUS"
    log "OVERALL STATUS: $STATUS"

    sleep 30

done
