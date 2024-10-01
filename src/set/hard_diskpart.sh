#!/bin/bash

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Backup /etc/fstab
if [ ! -f /etc/fstab.bak ]; then
  cp /etc/fstab /etc/fstab.bak
  echo "/etc/fstab backed up."
else
  echo "/etc/fstab backup already exists."
fi

# Set noexec, nosuid, and nodev options for /tmp
echo "Setting noexec, nosuid, and nodev options for /tmp..."
mount -o remount,noexec,nosuid,nodev /tmp
echo "/tmp options set to noexec, nosuid, nodev."

# ===============================
# Set appropriate permissions for /var/tmp
# ===============================
echo "Setting appropriate permissions for /var/tmp..."
chmod 1777 /var/tmp
echo "Permissions for /var/tmp set to 1777."

# ===============================
# Disable unnecessary mounts
# ===============================
echo "Disabling unnecessary mounts..."
if ! grep -q "tmpfs /run/shm" /etc/fstab; then
  echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
  mount -o remount,noexec,nosuid,nodev /run/shm
  echo "/run/shm mount options set to noexec, nosuid, nodev."
else
  echo "/run/shm already has noexec, nosuid, nodev options."
fi

# ===============================
# Concluding message
# ===============================
echo "ANSSI Disk Partition Hardening measures applied successfully. Reboot the system to activate changes."
