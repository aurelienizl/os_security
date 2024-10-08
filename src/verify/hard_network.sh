#!/bin/bash
source ./log.sh

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR" "Please run this script as root."
  exit 1
fi

log "INFO" "Starting network and sysctl configuration compliance check..."

# ===============================
# Helper function to check if a service is disabled
# ===============================
check_service_status() {
  service=$1
  if systemctl is-enabled "$service" &>/dev/null; then
    log "WARNING" "$service is enabled, if this service is not required, consider disabling it."
  else
    log "INFO" "$service is disabled."
  fi
}

# ===============================
# Helper function to check iptables rules
# ===============================
check_iptables_rule() {
  rule=$1
  message=$2
  if sudo iptables -L INPUT -v -n | grep -q "$rule"; then
    log "INFO" "$message"
  else
    log "WARNING" "$rule is not present in iptables rules."
  fi
}

# Helper function to check nftables rules
check_nftables_rule() {
  rule=$1
  message=$2
  if sudo nft list ruleset | grep -q "$rule"; then
    log "INFO" "$message"
  else
    log "WARNING" "$rule is not present in nftables rules."
  fi
}

# ===============================
# Check if unused network services are disabled
# ===============================
log "INFO" "Checking for disabled unused network services..."
services=("avahi-daemon" "cups" "nfs" "rpcbind" "postfix" "bluetooth" "apache2" "ssh")

for service in "${services[@]}"; do
  check_service_status "$service"
done

# ===============================
# Check firewall rules (iptables/nftables)
# ===============================
log "INFO" "Checking firewall rules..."

if command -v iptables &>/dev/null; then
  log "INFO" "Using iptables for firewall checks..."

  # Check default INPUT policy
  default_input_policy=$(sudo iptables -L INPUT -n | grep -oP '(?<=policy\s)\w+')

  if [ "$default_input_policy" = "DROP" ]; then
    log "INFO" "Default INPUT policy is DROP."
  else
    log "WARNING" "Default INPUT policy is not DROP (current policy: $default_input_policy)."
  fi

  # Check for SSH rule
  check_iptables_rule "dpt:22" "SSH is allowed."

  # Check for established connections rule
  check_iptables_rule "RELATED,ESTABLISHED" "Related and established connections are allowed."

  # Check for HTTP and HTTPS rule
  check_iptables_rule "dpt:80" "HTTP is allowed."
  check_iptables_rule "dpt:443" "HTTPS is allowed."

  # Check for DNS rule (UDP and TCP port 53)
  if sudo iptables -L INPUT -v -n | grep -q "53"; then
    log "INFO" "DNS (port 53) is allowed."
  else
    log "WARNING" "DNS (port 53) is not present in iptables rules."
  fi

elif sudo command -v nft &>/dev/null; then
  log "INFO" "Using nftables for firewall checks..."

  # Check default INPUT policy (nftables)
  default_input_policy=$(sudo nft list ruleset | grep -oP '(?<=policy\s)\w+')

  if [ "$default_input_policy" = "drop" ]; then
    log "INFO" "Default INPUT policy is DROP."
  else
    log "WARNING" "Default INPUT policy is not DROP (current policy: $default_input_policy)."
  fi

  # Check for SSH rule
  check_nftables_rule "dport 22" "SSH is allowed."

  # Check for established connections rule
  check_nftables_rule "ct state established,related accept" "Related and established connections are allowed."

  # Check for HTTP and HTTPS rule
  check_nftables_rule "dport 80" "HTTP is allowed."
  check_nftables_rule "dport 443" "HTTPS is allowed."

  # Check for DNS rule (UDP and TCP port 53)
  if sudo nft list ruleset | grep -q "53"; then
    log "INFO" "DNS (port 53) is allowed."
  else
    log "WARNING" "DNS (port 53) is not present in nftables rules."
  fi

else
  log "ERROR" "Neither iptables nor nftables is installed. Firewall checks cannot be performed."
fi

# ===============================
# Final Message
# ===============================
log "INFO" "Network hardening compliance check completed."
