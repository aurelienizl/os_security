#!/bin/bash
source ./log.sh

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR" "Please run this script as root."
  exit 1
fi

log "INFO" "Starting memory configuration compliance check according to the recommendations..."

# Path to the GRUB configuration file
grub_config="/etc/default/grub"

# Check if the GRUB configuration file exists
if [ ! -f "$grub_config" ]; then
  log "ERROR" "GRUB configuration file not found."
  exit 1
fi

# Kernel parameters to check
kernel_params="l1tf=full,force page_poison=on pti=on slab_nomerge=yes slub_debug=FZP \
spec_store_bypass_disable=seccomp spectre_v2=on mds=full,nosmt mce=0 \
page_alloc.shuffle=1 rng_core.default_quality=500"

# Function to check if each parameter is present
check_param() {
  param=$1
  if grep -q "$param" "$grub_config"; then
    log "INFO" "Kernel parameter $param is present."
  else
    log "WARNING" "Kernel parameter $param is missing."
  fi
}

# Loop through each parameter and check its presence
for param in $kernel_params; do
  check_param "$param"
done

log "INFO" "Memory configuration compliance check completed."
