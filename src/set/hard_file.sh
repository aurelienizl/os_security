#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Checking file protection hardening compliance..."

# ===============================
# Check restrictive permissions on sensitive files and directories
# ===============================
echo "Checking permissions on sensitive files..."

check_permissions() {
  file=$1
  expected_perms=$2
  if [ ! -f "$file" ]; then
    echo "$file does not exist."
    return
  fi
  actual_perms=$(stat -c "%a" "$file" 2>/dev/null)
  if [ "$actual_perms" == "$expected_perms" ]; then
    echo "$file has correct permissions: $expected_perms."
  else
    echo "$file does not have correct permissions. Current permissions: $actual_perms."
    echo "Setting correct permissions..."
    chmod "$expected_perms" "$file"
  fi
}

check_permissions "/etc/shadow" "600"
check_permissions "/etc/passwd" "644"
check_permissions "/etc/group" "640"
check_permissions "/etc/hosts.allow" "644"
check_permissions "/etc/hosts.deny" "644"
check_permissions "/etc/ssh/sshd_config" "644"
check_permissions "/etc/sudoers" "600"

# ===============================
# Check access restrictions to system logs
# ===============================
echo "Checking access restrictions on system logs..."
check_permissions "/var/log/auth.log" "640"
check_permissions "/var/log/syslog" "640"
check_permissions "/var/log/messages" "640"

# ===============================
# Check ownership for critical files
# ===============================
echo "Checking ownership of critical files..."

check_ownership() {
  file=$1
  if [ ! -f "$file" ]; then
    echo "$file does not exist."
    return
  fi
  expected_owner=$2
  expected_group=$3
  actual_owner=$(stat -c "%U" "$file" 2>/dev/null)
  actual_group=$(stat -c "%G" "$file" 2>/dev/null)
  if [ "$actual_owner" == "$expected_owner" ] && [ "$actual_group" == "$expected_group" ]; then
    echo "$file ownership is correct: $expected_owner:$expected_group."
  else
    echo "$file ownership is not correct. Current ownership: $actual_owner:$actual_group."
    echo "Setting correct ownership..."
    chown "$expected_owner:$expected_group" "$file"
  fi
}

check_ownership "/etc/passwd" "root" "root"
check_ownership "/etc/shadow" "root" "shadow"
check_ownership "/etc/group" "root" "root"
check_ownership "/etc/hosts.allow" "root" "root"
check_ownership "/etc/hosts.deny" "root" "root"
check_ownership "/etc/ssh/sshd_config" "root" "root"
check_ownership "/etc/sudoers" "root" "root"

# ===============================
# Check immutable attribute on critical files
# ===============================
echo "Checking immutable attribute on critical files..."

check_immutable() {
  file=$1
  if [ ! -f "$file" ]; then
    echo "$file does not exist."
    return
  fi
  if lsattr "$file" | grep -q "\-i\-\-\-\-\-\-\-\-\-"; then
    echo "$file has the immutable attribute set."
  else
    echo "$file does not have the immutable attribute set."
    echo "Setting immutable attribute..."
    chattr +i "$file"
  fi
}

check_immutable "/etc/passwd"
check_immutable "/etc/shadow"
check_immutable "/etc/group"
check_immutable "/etc/hosts.allow"
check_immutable "/etc/hosts.deny"
check_immutable "/etc/ssh/sshd_config"
check_immutable "/etc/sudoers"


# ===============================
# Check for world-writable permissions (excluding sticky-bit directories)
# ===============================
echo "Checking for world-writable permissions on files and directories (excluding sticky-bit directories)..."

# Define excluded filesystems that should not be searched (e.g., /proc, /sys, /dev, /run)
excluded_fs="proc|sys|dev|run"

# Find world-writable files excluding specific pseudo-filesystems
world_writable_files=$(find / -type f -perm -002 2>/dev/null | grep -Ev "^/($excluded_fs)")

# Find world-writable directories excluding sticky bit and specific pseudo-filesystems
world_writable_dirs=$(find / -type d -perm -002 ! -perm -1000 2>/dev/null | grep -Ev "^/($excluded_fs)")

# Report results
if [ -z "$world_writable_files" ] && [ -z "$world_writable_dirs" ]; then
  echo "No insecure world-writable files or directories found."
else
  # World-writable files found, report them
  if [ -n "$world_writable_files" ]; then
    echo "World-writable files found:"
    echo "$world_writable_files"
  fi

  # World-writable directories found (excluding those with sticky bit), report them
  if [ -n "$world_writable_dirs" ]; then
    echo "World-writable directories without sticky bit found:"
    echo "$world_writable_dirs"
  fi
fi



# ===============================
# Check SGID bit on critical directories
# ===============================
echo "Checking SGID bit on critical directories..."

check_sgid() {
  dir=$1
  if [ "$(stat -c "%A" "$dir" 2>/dev/null | cut -c 5)" == "s" ]; then
    echo "SGID bit is set on $dir."
  else
    echo "SGID bit is not set on $dir."
    echo "Setting SGID bit..."
    chmod g+s "$dir"
  fi
}

check_sgid "/usr/bin"
check_sgid "/usr/sbin"
check_sgid "/bin"
check_sgid "/sbin"

# ===============================
# Final Message
# ===============================d
echo "File protection hardening compliance check completed."
