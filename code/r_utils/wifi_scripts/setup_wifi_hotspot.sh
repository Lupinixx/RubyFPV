#!/bin/bash
# Script to setup WiFi hotspot on Radxa Zero 3W
# Arguments: $1=SSID, $2=Password, $3=Channel

SSID="$1"
PASSWORD="$2"
CHANNEL="$3"
WIFI_INTERFACE="wlan0"

if [ -z "$SSID" ] || [ -z "$PASSWORD" ] || [ -z "$CHANNEL" ]; then
    echo "Usage: $0 <SSID> <Password> <Channel>"
    exit 1
fi

# Check if password is at least 8 characters
if [ ${#PASSWORD} -lt 8 ]; then
    echo "Error: Password must be at least 8 characters"
    exit 1
fi

# Check if WiFi interface exists
if ! ip link show "$WIFI_INTERFACE" > /dev/null 2>&1; then
    echo "Error: WiFi interface $WIFI_INTERFACE not found"
    exit 1
fi

echo "Setting up WiFi hotspot: SSID=$SSID, Channel=$CHANNEL"

# Stop any existing hostapd and dnsmasq
systemctl stop hostapd 2>/dev/null
systemctl stop dnsmasq 2>/dev/null
killall hostapd 2>/dev/null
killall dnsmasq 2>/dev/null

# Configure static IP for WiFi interface
ip link set dev "$WIFI_INTERFACE" down
ip addr flush dev "$WIFI_INTERFACE"
ip addr add 192.168.50.1/24 dev "$WIFI_INTERFACE"
ip link set dev "$WIFI_INTERFACE" up

# Create hostapd configuration
cat > /tmp/hostapd_rubyfpv.conf << EOF
interface=$WIFI_INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CHANNEL
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

# Create dnsmasq configuration
cat > /tmp/dnsmasq_rubyfpv.conf << EOF
interface=$WIFI_INTERFACE
dhcp-range=192.168.50.10,192.168.50.50,255.255.255.0,12h
dhcp-option=3,192.168.50.1
dhcp-option=6,192.168.50.1
server=8.8.8.8
EOF

# Start dnsmasq
dnsmasq -C /tmp/dnsmasq_rubyfpv.conf -d &
sleep 1

# Start hostapd
hostapd /tmp/hostapd_rubyfpv.conf -B

echo "WiFi hotspot started successfully"
echo "SSID: $SSID"
echo "IP: 192.168.50.1"
