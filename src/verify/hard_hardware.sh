#!/bin/bash
source ./log.sh

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR" "Please run this script as root."
  exit 1
fi

log "INFO" "Starting hardware hardening compliance check..."

# ===============================
# Kernel Module Checks
# ===============================
log "INFO" "Checking kernel modules..."

# Check if USB storage is blacklisted
if grep -q "blacklist usb-storage" /etc/modprobe.d/*.conf; then
  log "INFO" "USB storage is blacklisted."
else
  log "WARNING" "USB storage is not blacklisted."
fi

# Check if Firewire modules are blacklisted
if grep -q "blacklist firewire-core" /etc/modprobe.d/*.conf; then
  log "INFO" "Firewire modules are blacklisted."
else
  log "WARNING" "Firewire modules are not blacklisted."
fi

# ===============================
# Device and Port Permissions
# ===============================
log "INFO" "Checking device and port permissions..."

serial_ports=$(ls /dev/ttyS* 2>/dev/null)
if [ -n "$serial_ports" ]; then
  for port in $serial_ports; do
    if [ "$(stat -c "%a" "$port")" -eq 700 ]; then
      log "INFO" "$port has correct permissions."
    else
      log "WARNING" "$port does not have correct permissions. Current permissions: $(stat -c "%a" "$port")"
    fi
  done
else
  log "INFO" "No serial ports found."
fi

# ===============================
# Console and Boot Settings
# ===============================
log "INFO" "Checking console and boot settings..."

# Check if physical console access is restricted
if [ -f "/etc/securetty" ] && grep -q "console" /etc/securetty; then
  log "INFO" "Physical console access is restricted."
else
  log "WARNING" "Physical console access is not restricted."
fi

# Check if booting from external media is disabled (GRUB recovery mode)
grub_file="/etc/default/grub"
if [ -f "$grub_file" ] && grep -q 'GRUB_DISABLE_RECOVERY="true"' "$grub_file"; then
  log "INFO" "Boot from external media is disabled."
else
  log "WARNING" "Boot from external media is not disabled."
fi

# ===============================
# GRUB and Password Policy
# ===============================
log "INFO" "Checking GRUB and password policies..."

# Check if GRUB password is set
if grep -q "GRUB_PASSWORD" "$grub_file"; then
  log "INFO" "GRUB password is set."
else
  log "WARNING" "GRUB password is not set."
fi

# Check if the root account is locked
if passwd -S root | grep -q "L"; then
  log "INFO" "Root account is locked."
else
  log "WARNING" "Root account is not locked."
fi

# Check password policy in /etc/login.defs
password_policy_check() {
  local setting=$1
  local expected_value=$2
  local actual_value
  actual_value=$(grep "^$setting" /etc/login.defs | awk '{print $2}')
  if [ "$actual_value" -eq "$expected_value" ]; then
    log "INFO" "$setting is correctly set to $expected_value."
  else
    log "WARNING" "$setting is not correctly set. Current value: $actual_value."
  fi
}

password_policy_check "PASS_MAX_DAYS" 90
password_policy_check "PASS_MIN_DAYS" 7
password_policy_check "PASS_WARN_AGE" 14

# ===============================
# Concluding Message
# ===============================
log "INFO" "Hardware hardening compliance check completed."
