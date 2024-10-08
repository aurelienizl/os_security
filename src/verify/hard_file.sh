#!/bin/bash
source ./log.sh

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR" "Please run this script as root."
  exit 1
fi

log "INFO" "Starting essential file protection hardening compliance check..."

# ===============================
# Check restrictive permissions on sensitive files
# ===============================
log "INFO" "Checking permissions on sensitive files..."

check_permissions() {
  file=$1
  expected_perms=$2
  actual_perms=$(stat -c "%a" "$file" 2>/dev/null)
  if [ "$actual_perms" == "$expected_perms" ]; then
    log "INFO" "$file has correct permissions: $expected_perms."
  else
    log "WARNING" "$file does not have correct permissions. Current permissions: $actual_perms."
  fi
}

check_permissions "/etc/shadow" "600"
check_permissions "/etc/passwd" "644"
check_permissions "/etc/ssh/sshd_config" "644"
check_permissions "/etc/sudoers" "600"

# ===============================
# Check ownership for critical files
# ===============================
log "INFO" "Checking ownership of critical files..."

check_ownership() {
  file=$1
  expected_owner=$2
  expected_group=$3
  actual_owner=$(stat -c "%U" "$file" 2>/dev/null)
  actual_group=$(stat -c "%G" "$file" 2>/dev/null)
  if [ "$actual_owner" == "$expected_owner" ] && [ "$actual_group" == "$expected_group" ]; then
    log "INFO" "$file ownership is correct: $expected_owner:$expected_group."
  else
    log "WARNING" "$file ownership is not correct. Current ownership: $actual_owner:$actual_group."
  fi
}

check_ownership "/etc/passwd" "root" "root"
check_ownership "/etc/shadow" "root" "shadow"
check_ownership "/etc/ssh/sshd_config" "root" "root"
check_ownership "/etc/sudoers" "root" "root"

# ===============================
# Check immutable attribute on critical files
# ===============================
log "INFO" "Checking immutable attribute on critical files..."

check_immutable() {
  file=$1
  if lsattr "$file" | grep -q "\-i\-\-\-\-\-\-\-\-\-"; then
    log "INFO" "$file has the immutable attribute set."
  else
    log "WARNING" "$file does not have the immutable attribute set."
  fi
}

check_immutable "/etc/passwd"
check_immutable "/etc/shadow"
check_immutable "/etc/ssh/sshd_config"
check_immutable "/etc/sudoers"

# ===============================
# Check permissions for sensitive directories
# ===============================
log "INFO" "Checking permissions for sensitive directories..."

check_permissions "/root" "700"
check_permissions "/var/log" "750"

# ===============================
# Check for world-writable permissions (excluding pseudo-filesystems)
# ===============================
log "INFO" "Checking for world-writable permissions on files and directories..."

# Define excluded filesystems that should not be searched (e.g., /proc, /sys, /dev, /run)
excluded_fs="proc|sys|dev|run"

# Find world-writable files excluding specific pseudo-filesystems
world_writable_files=$(find / -type f -perm -002 2>/dev/null | grep -Ev "^/($excluded_fs)")

# Report results
if [ -z "$world_writable_files" ]; then
  log "INFO" "No insecure world-writable files found."
else
  log "WARNING" "World-writable files found: $world_writable_files"
fi

# ===============================
# Final Message
# ===============================
log "INFO" "Essential file protection hardening compliance check completed."
