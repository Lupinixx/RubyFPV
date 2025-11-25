#!/bin/bash
# Script to scan for available WiFi networks

WIFI_INTERFACE="wlan0"

# Check if WiFi interface exists
if ! ip link show "$WIFI_INTERFACE" > /dev/null 2>&1; then
    echo "Error: WiFi interface $WIFI_INTERFACE not found"
    exit 1
fi

echo "Scanning for WiFi networks..."

# Bring interface up if down
ip link set dev "$WIFI_INTERFACE" up 2>/dev/null

# Scan for networks
iw dev "$WIFI_INTERFACE" scan | grep -E "SSID:|signal:" | sed 'N;s/\n/ /' | sort -k2 -rn
