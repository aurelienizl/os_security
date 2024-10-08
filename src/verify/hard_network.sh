#!/bin/bash
source ./log.sh

# ===============================
# Check if unused network services are disabled
# ===============================
log "INFO" "Checking for disabled unused network services..."

check_service_status() {
  service=$1
  if systemctl is-enabled "$service" &>/dev/null; then
    log "WARNING" "$service is enabled, if this service is not required, consider disabling it."
  else
    log "INFO" "$service is disabled."
  fi
}

# List of services to check
services=("avahi-daemon" "cups" "nfs" "rpcbind" "postfix" "bluetooth" "apache2" "ssh")

for service in "${services[@]}"; do
  check_service_status "$service"
done

# ===============================
# Check firewall rules (iptables)
# ===============================
log "INFO" "Checking firewall rules..."

# Check default INPUT policy
default_input_policy=$(iptables -L INPUT --line-numbers | grep "Chain INPUT (policy" | awk '{print $4}')
if [ "$default_input_policy" = "DROP" ]; then
  log "INFO" "Default INPUT policy is DROP."
else
  log "WARNING" "Default INPUT policy is not DROP (current policy: $default_input_policy)."
fi

# Check if SSH is allowed
if iptables -L INPUT -v -n | grep -q "dpt:22"; then
  log "INFO" "SSH is allowed."
else
  log "WARNING" "SSH is not allowed."
fi

# Check if related/established connections are allowed
if iptables -L INPUT -v -n | grep -q "RELATED,ESTABLISHED"; then
  log "INFO" "Related and established connections are allowed."
else
  log "WARNING" "Related and established connections are not allowed."
fi

# ===============================
# Check kernel parameters (sysctl settings)
# ===============================
log "INFO" "Checking kernel parameters..."

check_sysctl_setting() {
  param=$1
  expected_value=$2
  actual_value=$(sysctl -n "$param")
  if [ "$actual_value" -eq "$expected_value" ]; then
    log "INFO" "$param is correctly set to $expected_value."
  else
    log "WARNING" "$param is not set correctly. Current value: $actual_value (should be $expected_value)."
  fi
}

# SYN flood protection
check_sysctl_setting "net.ipv4.tcp_syncookies" 1

# IP forwarding
check_sysctl_setting "net.ipv4.ip_forward" 0

# ICMP redirects
check_sysctl_setting "net.ipv4.conf.all.send_redirects" 0
check_sysctl_setting "net.ipv4.conf.default.send_redirects" 0

# Source routing
check_sysctl_setting "net.ipv4.conf.all.accept_source_route" 0
check_sysctl_setting "net.ipv4.conf.default.accept_source_route" 0

# ARP protection
check_sysctl_setting "net.ipv4.conf.all.arp_ignore" 1
check_sysctl_setting "net.ipv4.conf.default.arp_ignore" 1
check_sysctl_setting "net.ipv4.conf.all.arp_announce" 2
check_sysctl_setting "net.ipv4.conf.default.arp_announce" 2

# ===============================
# Check if IPv6 is disabled
# ===============================
log "INFO" "Checking if IPv6 is disabled..."

ipv6_all_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)
ipv6_default_disabled=$(sysctl -n net.ipv6.conf.default.disable_ipv6)

if [ "$ipv6_all_disabled" -eq 1 ] && [ "$ipv6_default_disabled" -eq 1 ]; then
  log "INFO" "IPv6 is disabled."
else
  log "WARNING" "IPv6 is not disabled. Current values: all=$ipv6_all_disabled, default=$ipv6_default_disabled."
fi

# ===============================
# Final Message
# ===============================
log "INFO" "Network hardening compliance check completed."
