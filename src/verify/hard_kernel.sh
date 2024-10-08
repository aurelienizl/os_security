#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Starting kernel hardening compliance check..."

# ===============================
# Check if kernel configuration backup exists
# ===============================
echo "Checking kernel configuration backup..."
kernel_config="/boot/config-$(uname -r)"
if [ -f "$kernel_config.bak" ]; then
  echo "Kernel configuration backup found: $kernel_config.bak"
else
  echo "WARNING: Kernel configuration backup not found."
fi

# ===============================
# Check if ASLR is enabled
# ===============================
echo "Checking Address Space Layout Randomization (ASLR)..."
if sysctl kernel.randomize_va_space | grep -q "2"; then
  echo "ASLR is enabled."
else
  echo "WARNING: ASLR is not enabled."
fi

# ===============================
# Check if stricter ptrace security is enabled
# ===============================
echo "Checking ptrace security..."
if sysctl kernel.yama.ptrace_scope | grep -q "3"; then
  echo "Ptrace security is enabled."
else
  echo "WARNING: Ptrace security is not enabled."
fi

# ===============================
# Check if core dumps are restricted
# ===============================
echo "Checking core dump restrictions..."
if sysctl fs.suid_dumpable | grep -q "0"; then
  echo "Core dumps are restricted."
else
  echo "WARNING: Core dump restrictions are not applied."
fi

# ===============================
# Check if access to kernel logs is restricted
# ===============================
echo "Checking kernel log access restrictions..."
if [ -f /var/log/dmesg ] && [ "$(stat -c "%a" /var/log/dmesg)" -eq 600 ]; then
  echo "/var/log/dmesg access is restricted."
else
  echo "WARNING: /var/log/dmesg access is not restricted."
fi

if [ -f /var/log/kern.log ] && [ "$(stat -c "%a" /var/log/kern.log)" -eq 600 ]; then
  echo "/var/log/kern.log access is restricted."
else
  echo "WARNING: /var/log/kern.log access is not restricted."
fi

# ===============================
# Finalizing compliance check
# ===============================
echo "Kernel hardening compliance check completed."

