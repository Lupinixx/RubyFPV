#!/bin/bash
# Script to connect to WiFi network as client
# Arguments: $1=SSID, $2=Password

SSID="$1"
PASSWORD="$2"
WIFI_INTERFACE="wlan0"

if [ -z "$SSID" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: $0 <SSID> <Password>"
    exit 1
fi

# Check if WiFi interface exists
if ! ip link show "$WIFI_INTERFACE" > /dev/null 2>&1; then
    echo "Error: WiFi interface $WIFI_INTERFACE not found"
    exit 1
fi

echo "Connecting to WiFi network: SSID=$SSID"

# Stop any existing hostapd and dnsmasq
systemctl stop hostapd 2>/dev/null
systemctl stop dnsmasq 2>/dev/null
killall hostapd 2>/dev/null
killall dnsmasq 2>/dev/null
killall wpa_supplicant 2>/dev/null

# Create wpa_supplicant configuration
cat > /tmp/wpa_supplicant_rubyfpv.conf << EOF
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1

network={
    ssid="$SSID"
    psk="$PASSWORD"
    key_mgmt=WPA-PSK
}
EOF

# Bring interface down and up
ip link set dev "$WIFI_INTERFACE" down
ip link set dev "$WIFI_INTERFACE" up

# Start wpa_supplicant
wpa_supplicant -B -i "$WIFI_INTERFACE" -c /tmp/wpa_supplicant_rubyfpv.conf

# Wait a bit for connection
sleep 3

# Request DHCP address
dhclient "$WIFI_INTERFACE" 2>/dev/null || udhcpc -i "$WIFI_INTERFACE"

# Check if connected
if iw dev "$WIFI_INTERFACE" link | grep -q "Connected to"; then
    echo "WiFi client connected successfully"
    ip addr show "$WIFI_INTERFACE" | grep "inet "
    exit 0
else
    echo "Failed to connect to WiFi network"
    exit 1
fi
