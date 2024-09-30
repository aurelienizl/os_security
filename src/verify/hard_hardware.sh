#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# ===============================
# Kernel Module Checks
# ===============================

# Check if USB storage is blacklisted
echo "Checking kernel modules..."
if grep -q "blacklist usb-storage" /etc/modprobe.d/*.conf; then
  echo "USB storage is blacklisted."
else
  echo "USB storage is not blacklisted."
fi

# Check if Firewire modules are blacklisted
if grep -q "blacklist firewire-core" /etc/modprobe.d/*.conf && grep -q "blacklist firewire-ohci" /etc/modprobe.d/*.conf; then
  echo "Firewire modules are blacklisted."
else
  echo "Firewire modules are not blacklisted."
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
      echo "$port does not have correct permissions."
      echo "Permissions are: $(stat -c "%a" "$port")"
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
if [ -f "/etc/securetty" ]; then
  if grep -q "console" /etc/securetty; then
    echo "Physical console access is restricted."
  else
    echo "Physical console access is not restricted."
  fi
else
  echo "The service is not configured."
fi

# Check if booting from external media is disabled (GRUB recovery mode)
grub_file="/etc/default/grub"
if [ -f "$grub_file" ] && grep -q 'GRUB_DISABLE_RECOVERY="true"' "$grub_file"; then
  echo "Boot from external media is disabled."
else
  echo "Boot from external media is not disabled."
fi

# ===============================
# UEFI and Secure Boot
# ===============================

# Check if the system is using UEFI
echo "Checking UEFI and Secure Boot..."
if [ -d /sys/firmware/efi ]; then
  echo "UEFI is detected."
else
  echo "UEFI is not detected."
fi

# Check if Secure Boot is enabled
if command -v mokutil &> /dev/null; then
  if mokutil --sb-state | grep -q "SecureBoot enabled"; then
    echo "Secure Boot is enabled."
  else
    echo "Secure Boot is not enabled."
  fi
else
  echo "mokutil is not installed. Cannot check Secure Boot status."
fi

# ===============================
# GRUB and Password Policy
# ===============================

# Check if GRUB password is set
echo "Checking GRUB and password policies..."
if grep -q "GRUB_PASSWORD" "$grub_file"; then
  echo "GRUB password is set."
else
  echo "GRUB password is not set."
fi

# Check if the root account is locked
if passwd -S root | grep -q "L"; then
  echo "Root account is locked."
else
  echo "Root account is not locked."
fi

# Check password policy in /etc/login.defs
max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
min_days=$(grep "^PASS_MIN_DAYS" /etc/login.defs | awk '{print $2}')
warn_age=$(grep "^PASS_WARN_AGE" /etc/login.defs | awk '{print $2}')

if [ "$max_days" -eq 90 ] && [ "$min_days" -eq 7 ] && [ "$warn_age" -eq 14 ]; then
  echo "Password policy is correctly set."
else
  echo "Password policy is not correctly set."
fi

# ===============================
# Concluding Message
# ===============================

# Display a concluding message
echo "Hardware hardening compliance check completed."
