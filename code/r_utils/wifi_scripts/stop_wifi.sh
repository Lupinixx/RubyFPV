#!/bin/bash
# Script to stop WiFi hotspot or client mode

WIFI_INTERFACE="wlan0"

echo "Stopping WiFi services..."

# Stop all WiFi services
systemctl stop hostapd 2>/dev/null
systemctl stop dnsmasq 2>/dev/null
killall hostapd 2>/dev/null
killall dnsmasq 2>/dev/null
killall wpa_supplicant 2>/dev/null
killall dhclient 2>/dev/null

# Reset interface
if ip link show "$WIFI_INTERFACE" > /dev/null 2>&1; then
    ip link set dev "$WIFI_INTERFACE" down
    ip addr flush dev "$WIFI_INTERFACE"
fi

# Clean up config files
rm -f /tmp/hostapd_rubyfpv.conf
rm -f /tmp/dnsmasq_rubyfpv.conf
rm -f /tmp/wpa_supplicant_rubyfpv.conf

echo "WiFi services stopped"
