#!/bin/bash
source ./log.sh

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR" "Please run this script as root."
  exit 1
fi

log "INFO" "Starting kernel hardening compliance check..."

# ===============================
# Check if kernel configuration backup exists
# ===============================
log "INFO" "Checking kernel configuration backup..."
kernel_config="/boot/config-$(uname -r)"
if [ -f "$kernel_config.bak" ]; then
  log "INFO" "Kernel configuration backup found: $kernel_config.bak"
else
  log "WARNING" "Kernel configuration backup not found."
fi

# ===============================
# Check if ASLR is enabled
# ===============================
log "INFO" "Checking Address Space Layout Randomization (ASLR)..."
if sysctl kernel.randomize_va_space | grep -q "2"; then
  log "INFO" "ASLR is enabled."
else
  log "WARNING" "ASLR is not enabled."
fi

# ===============================
# Check if stricter ptrace security is enabled
# ===============================
log "INFO" "Checking ptrace security..."
if sysctl kernel.yama.ptrace_scope | grep -q "3"; then
  log "INFO" "Ptrace security is enabled."
else
  log "WARNING" "Ptrace security is not enabled."
fi

# ===============================
# Check if core dumps are restricted
# ===============================
log "INFO" "Checking core dump restrictions..."
if sysctl fs.suid_dumpable | grep -q "0"; then
  log "INFO" "Core dumps are restricted."
else
  log "WARNING" "Core dump restrictions are not applied."
fi

# ===============================
# Check if access to kernel logs is restricted
# ===============================
log "INFO" "Checking kernel log access restrictions..."
if [ -f /var/log/dmesg ] && [ "$(stat -c "%a" /var/log/dmesg)" -eq 600 ]; then
  log "INFO" "/var/log/dmesg access is restricted."
else
  log "WARNING" "/var/log/dmesg access is not restricted."
fi

if [ -f /var/log/kern.log ] && [ "$(stat -c "%a" /var/log/kern.log)" -eq 600 ]; then
  log "INFO" "/var/log/kern.log access is restricted."
else
  log "WARNING" "/var/log/kern.log access is not restricted."
fi

# ===============================
# Finalizing compliance check
# ===============================
log "INFO" "Kernel hardening compliance check completed."
