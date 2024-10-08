#!/bin/bash
source ./log.sh

log "INFO" "Starting partition options verification according to ANSSI Hardening measures..."

# Function to check if mount options are set correctly
check_mount_options() {
  local mount_point=$1
  local expected_options=$2

  mount_output=$(findmnt -n -o OPTIONS "$mount_point")
  if [[ "$mount_output" == *"$expected_options"* ]]; then
    log "INFO" "$mount_point is correctly configured with options: $expected_options"
  else
    log "WARNING" "$mount_point does not have the expected options: $expected_options"
  fi
}

# Function to check if a filesystem is blacklisted in modprobe
check_blacklisted_filesystem() {
  local fs=$1
  local blacklist_file="/etc/modprobe.d/blacklist.conf"

  if grep -q "^blacklist $fs" "$blacklist_file"; then
    log "INFO" "Filesystem $fs is correctly blacklisted in $blacklist_file."
  else
    log "WARNING" "Filesystem $fs is not blacklisted in $blacklist_file."
  fi
}

# ===============================
# Check mount options for each partition
# ===============================

# Root partition (/)
check_mount_options "/" ""

# /boot partition
check_mount_options "/boot" "nosuid,nodev,noexec"

# /opt partition
check_mount_options "/opt" "nosuid,nodev"

# /tmp partition
check_mount_options "/tmp" "nosuid,nodev,noexec"

# /srv partition
check_mount_options "/srv" "nosuid,nodev"

# /home partition
check_mount_options "/home" "nosuid,nodev,noexec"

# /proc partition
check_mount_options "/proc" "hidepid=2"

# /usr partition
check_mount_options "/usr" "nodev"

# /var partition
check_mount_options "/var" "nosuid,nodev,noexec"

# /var/log partition
check_mount_options "/var/log" "nosuid,nodev,noexec"

# /var/tmp partition
check_mount_options "/var/tmp" "nosuid,nodev,noexec"

# ===============================
log "INFO" "Checking if risky filesystems are blacklisted..."

# Add the filesystems considered risky
risky_filesystems=("cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "squashfs" "udf" "vfat")

for fs in "${risky_filesystems[@]}"; do
  check_blacklisted_filesystem "$fs"
done

# ===============================
# Concluding Message
# ===============================
log "INFO" "Partition options and risky filesystem verification completed."
