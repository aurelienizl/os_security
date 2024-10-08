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
  if iptables -L INPUT -v -n | grep -q "$rule"; then
    log "INFO" "$message"
  else
    log "WARNING" "$rule is not present in iptables rules."
  fi
}

# ===============================
# Helper function to check nftables rules
# ===============================
check_nftables_rule() {
  rule=$1
  message=$2
  if nft list ruleset | grep -q "$rule"; then
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

# Check if iptables or nftables is being used
if command -v iptables &>/dev/null; then
  log "INFO" "Using iptables for firewall checks..."

  # Check default INPUT policy
  default_input_policy=$(iptables -L INPUT --line-numbers | grep "Chain INPUT (policy" | awk '{print $4}')
  if [ "$default_input_policy" = "DROP" ]; then
    log "INFO" "Default INPUT policy is DROP."
  else
    log "WARNING" "Default INPUT policy is not DROP (current policy: $default_input_policy)."
  fi

  check_iptables_rule "dpt:22" "SSH is allowed."
  check_iptables_rule "RELATED,ESTABLISHED" "Related and established connections are allowed."

elif command -v nft &>/dev/null; then
  log "INFO" "Using nftables for firewall checks..."

  # Example of checking rules with nftables
  default_input_policy=$(nft list ruleset | grep "type filter hook input priority 0" | grep -oP '(?<=policy )\w+')
  if [ "$default_input_policy" = "drop" ]; then
    log "INFO" "Default INPUT policy is DROP."
  else
    log "WARNING" "Default INPUT policy is not DROP (current policy: $default_input_policy)."
  fi

  check_nftables_rule "dport 22" "SSH is allowed."
  check_nftables_rule "ct state established,related accept" "Related and established connections are allowed."

else
  log "ERROR" "Neither iptables nor nftables is installed. Unable to check firewall rules."
fi

# ===============================
# Final Message
# ===============================
log "INFO" "Network hardening compliance check completed."
