# !/bin/bash
PIDFILE="/var/run/haproxy.pid"
haproxy -f /etc/haproxy/haproxy.cfg -p "$PIDFILE"
