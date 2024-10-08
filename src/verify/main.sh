#!/bin/bash
source ./log.sh

log "INFO" "Starting the complete hardening process..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR" "Please run this script as root."
  exit 1
fi

# ===============================
# Run each hardening script
# ===============================
run_script() {
  script_name=$1
  if [ -f "$script_name" ]; then
    log "INFO" "Running $script_name..."
    bash "$script_name"
    if [ $? -eq 0 ]; then
      log "INFO" "$script_name completed successfully."
    else
      log "ERROR" "$script_name encountered an error."
    fi
  else
    log "ERROR" "$script_name not found!"
  fi
}

# Run each script in the correct order
run_script "./hard_kernel.sh"
run_script "./hard_network.sh"
run_script "./hard_file.sh"
run_script "./hard_diskpart.sh"
run_script "./hard_authid.sh"
run_script "./hard_hardware.sh"

# ===============================
# Final Message
# ===============================
log "INFO" "Complete hardening process finished."
