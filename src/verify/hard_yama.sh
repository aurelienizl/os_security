# ANSSI SECTION R11

#!/bin/bash
source ./log.sh

log "INFO" "Checking if LSM Yama is enabled and kernel.yama.ptrace_scope is correctly configured..."

# Check if 'security=yama' is passed as a kernel boot parameter
grub_config="/etc/default/grub"
if grep -q "security=yama" "$grub_config"; then
  log "INFO" "Kernel boot parameter 'security=yama' is correctly set in GRUB configuration."
else
  log "WARNING" "'security=yama' kernel boot parameter is not set in GRUB configuration."
fi

# Check if kernel.yama.ptrace_scope is set to at least 1
ptrace_scope=$(sudo sysctl -n kernel.yama.ptrace_scope 2>/dev/null)

if [ "$ptrace_scope" -ge 1 ]; then
  log "INFO" "kernel.yama.ptrace_scope is correctly set to $ptrace_scope."
else
  if [ -z "$ptrace_scope" ]; then
    log "WARNING" "kernel.yama.ptrace_scope is not found in the sysctl configuration."
  else
    log "WARNING" "kernel.yama.ptrace_scope is set to $ptrace_scope, but it should be at least 1."
  fi
fi

log "INFO" "LSM Yama configuration check completed."
