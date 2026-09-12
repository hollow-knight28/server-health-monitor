# Linux Server Health Monitor

A Bash-based Linux server monitoring tool that continuously checks system health and logs monitoring results.

## Features

- CPU usage monitoring
- Memory usage monitoring
- Disk usage monitoring
- SSH service status checking
- Internet connectivity checking
- Configurable resource thresholds
- Overall server health status
- Timestamped logging
- Log rotation
- Required command validation
- Graceful Ctrl+C handling
- Bash error handling with `set -euo pipefail`

## Project Structure

```text
server-health-monitor/
├── monitor.sh
├── .gitignore
└── logs/
    └── Runtime logs (ignored by Git)
