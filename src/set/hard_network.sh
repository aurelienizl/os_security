#!/bin/bash

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Starting network hardening process..."

# ===============================
# Function to disable unused network services
# ===============================
disable_service() {
  local service=$1
  if systemctl is-enabled "$service" &>/dev/null; then
    systemctl disable "$service"
    echo "$service disabled."
  else
    echo "$service is already disabled."
  fi
}

# ===============================
# Disable Unused Network Services
# ===============================
disable_unused_services() {
  echo "Disabling unused network services..."
  local services=("avahi-daemon" "cups" "nfs" "rpcbind" "postfix" "bluetooth" "apache2")
  for service in "${services[@]}"; do
    disable_service "$service"
  done
}

# ===============================
# Configure Firewall Rules (iptables)
# ===============================
configure_firewall() {
  echo "Configuring firewall rules..."

  # Set default INPUT policy to DROP
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
}

# ===============================
# Configure sysctl settings
# ===============================
configure_sysctl() {
  local param=$1
  local value=$2
  local config_file="/etc/sysctl.conf"

  if ! grep -q "^$param = $value" "$config_file"; then
    echo "$param = $value" >> "$config_file"
    sysctl -w "$param=$value"
  else
    echo "$param is already set to $value."
  fi
}

# ===============================
# Apply Network Protection Measures
# ===============================
apply_network_protection() {
  echo "Applying network protection measures..."

  # Enable SYN flood protection
  echo "Enabling SYN flood protection..."
  configure_sysctl "net.ipv4.tcp_syncookies" 1

  # Disable IP forwarding
  echo "Disabling IP forwarding..."
  configure_sysctl "net.ipv4.ip_forward" 0

  # Disable ICMP redirects
  echo "Disabling ICMP redirects..."
  configure_sysctl "net.ipv4.conf.all.send_redirects" 0
  configure_sysctl "net.ipv4.conf.default.send_redirects" 0

  # Disable source routing
  echo "Disabling source routing..."
  configure_sysctl "net.ipv4.conf.all.accept_source_route" 0
  configure_sysctl "net.ipv4.conf.default.accept_source_route" 0

  # Enable ARP protection
  echo "Enabling ARP protection..."
  configure_sysctl "net.ipv4.conf.all.arp_ignore" 1
  configure_sysctl "net.ipv4.conf.default.arp_ignore" 1
  configure_sysctl "net.ipv4.conf.all.arp_announce" 2
  configure_sysctl "net.ipv4.conf.default.arp_announce" 2
}

# ===============================
# Disable IPv6 (if not needed)
# ===============================
disable_ipv6() {
  echo "Disabling IPv6 (if applicable)..."
  configure_sysctl "net.ipv6.conf.all.disable_ipv6" 1
  configure_sysctl "net.ipv6.conf.default.disable_ipv6" 1
}

# ===============================
# Main Function to Run All Steps
# ===============================
main() {
  disable_unused_services
  configure_firewall
  apply_network_protection
  disable_ipv6
  sysctl -p
  echo "ANSSI Network Hardening measures applied successfully."
}

# Run the main function
main
