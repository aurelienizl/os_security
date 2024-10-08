#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Starting hardware hardening compliance check..."

# ===============================
# Kernel Module Checks
# ===============================

# Check if USB storage is blacklisted
echo "Checking kernel modules..."
if grep -q "blacklist usb-storage" /etc/modprobe.d/*.conf; then
  echo "USB storage is blacklisted."
else
  echo "WARNING: USB storage is not blacklisted."
fi

# Check if Firewire modules are blacklisted
if grep -q "blacklist firewire-core" /etc/modprobe.d/*.conf; then
  echo "Firewire modules are blacklisted."
else
  echo "WARNING: Firewire modules are not blacklisted."
fi

# ===============================
# Device and Port Permissions
# ===============================

# Check permissions of serial ports
echo "Checking device and port permissions..."
serial_ports=$(ls /dev/ttyS* 2>/dev/null)
if [ -n "$serial_ports" ]; then
  for port in $serial_ports; do
    if [ "$(stat -c "%a" "$port")" -eq 700 ]; then
      echo "$port has correct permissions."
    else
      echo "WARNING: $port does not have correct permissions. Current permissions: $(stat -c "%a" "$port")"
    fi
  done
else
  echo "No serial ports found."
fi

# ===============================
# Console and Boot Settings
# ===============================

# Check if physical console access is restricted
echo "Checking console and boot settings..."
if [ -f "/etc/securetty" ] && grep -q "console" /etc/securetty; then
  echo "Physical console access is restricted."
else
  echo "WARNING: Physical console access is not restricted."
fi

# Check if booting from external media is disabled (GRUB recovery mode)
grub_file="/etc/default/grub"
if [ -f "$grub_file" ] && grep -q 'GRUB_DISABLE_RECOVERY="true"' "$grub_file"; then
  echo "Boot from external media is disabled."
else
  echo "WARNING: Boot from external media is not disabled."
fi

# ===============================
# GRUB and Password Policy
# ===============================

# Check if GRUB password is set
echo "Checking GRUB and password policies..."
if grep -q "GRUB_PASSWORD" "$grub_file"; then
  echo "GRUB password is set."
else
  echo "WARNING: GRUB password is not set."
fi

# Check if the root account is locked
if passwd -S root | grep -q "L"; then
  echo "Root account is locked."
else
  echo "WARNING: Root account is not locked."
fi

# Check password policy in /etc/login.defs
password_policy_check() {
  local setting=$1
  local expected_value=$2
  local actual_value=$(grep "^$setting" /etc/login.defs | awk '{print $2}')
  if [ "$actual_value" -eq "$expected_value" ]; then
    echo "$setting is correctly set to $expected_value."
  else
    echo "WARNING: $setting is not correctly set. Current value: $actual_value."
  fi
}

password_policy_check "PASS_MAX_DAYS" 90
password_policy_check "PASS_MIN_DAYS" 7
password_policy_check "PASS_WARN_AGE" 14

# ===============================
# Concluding Message
# ===============================

echo "Hardware hardening compliance check completed."
