#!/bin/bash

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Starting network hardening process..."

# ===============================
# Disable Unused Network Services
# ===============================
disable_service() {
  service=$1
  if systemctl is-enabled "$service" &>/dev/null; then
    systemctl disable "$service"
    echo "$service disabled."
  else
    echo "$service is already disabled."
  fi
}

echo "Disabling unused network services..."
services=("avahi-daemon" "cups" "nfs" "rpcbind" "postfix" "bluetooth" "apache2")
for service in "${services[@]}"; do
  disable_service "$service"
done

# ===============================
# Enable and Configure Firewall Rules (iptables)
# ===============================
echo "Configuring firewall rules..."

# Default INPUT policy to DROP
iptables -P INPUT DROP

# Allow SSH on port 22
if ! iptables -C INPUT -p tcp --dport 22 -j ACCEPT &>/dev/null; then
  iptables -A INPUT -p tcp --dport 22 -j ACCEPT
  echo "SSH allowed on port 22."
else
  echo "SSH rule already exists."
fi

# Allow related/established connections
if ! iptables -C INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT &>/dev/null; then
  iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  echo "Related and established connections allowed."
else
  echo "Related/established rule already exists."
fi

# ===============================
# Enable SYN Flood Protection
# ===============================
echo "Enabling SYN flood protection..."
sysctl -w net.ipv4.tcp_syncookies=1

# ===============================
# Disable IP Forwarding
# ===============================
echo "Disabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=0

# ===============================
# Disable ICMP Redirects
# ===============================
echo "Disabling ICMP redirects..."
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0

# ===============================
# Disable Source Routing
# ===============================
echo "Disabling source routing..."
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv4.conf.default.accept_source_route=0

# ===============================
# Enable ARP Protection
# ===============================
echo "Enabling ARP protection..."
sysctl -w net.ipv4.conf.all.arp_ignore=1
sysctl -w net.ipv4.conf.default.arp_ignore=1
sysctl -w net.ipv4.conf.all.arp_announce=2
sysctl -w net.ipv4.conf.default.arp_announce=2

# ===============================
# Disable IPv6 (if not needed)
# ===============================
echo "Disabling IPv6 (if applicable)..."
if ! grep -q "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf; then
  echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
fi

if ! grep -q "net.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf; then
  echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
fi

sysctl -p

# ===============================
# Display Concluding Message
# ===============================
echo "ANSSI Network Hardening measures applied successfully."
