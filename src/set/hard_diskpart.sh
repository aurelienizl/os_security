#!/bin/bash

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# ===============================
# Backup /etc/fstab if not already backed up
# ===============================
backup_fstab() {
  if [ ! -f /etc/fstab.bak ]; then
    cp /etc/fstab /etc/fstab.bak
    echo "/etc/fstab backed up."
  else
    echo "/etc/fstab backup already exists."
  fi
}

# ===============================
# Set noexec, nosuid, and nodev for /tmp and persist in fstab
# ===============================
secure_tmp() {
  echo "Securing /tmp with noexec, nosuid, nodev options..."

  # Check if /tmp is already secured in /etc/fstab
  if ! grep -q "/tmp" /etc/fstab; then
    echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
    mount -o remount,noexec,nosuid,nodev /tmp
    echo "/tmp options set and persisted in /etc/fstab."
  else
    echo "/tmp is already secured in /etc/fstab."
  fi
}

# ===============================
# Set appropriate permissions for /var/tmp
# ===============================
secure_var_tmp() {
  echo "Securing /var/tmp permissions..."
  chmod 1777 /var/tmp
  echo "Permissions for /var/tmp set to 1777."
}

# ===============================
# Disable unnecessary mounts (e.g., /run/shm)
# ===============================
secure_run_shm() {
  echo "Securing /run/shm with noexec, nosuid, nodev options..."

  # Check if /run/shm is already secured in /etc/fstab
  if ! grep -q "/run/shm" /etc/fstab; then
    echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
    mount -o remount,noexec,nosuid,nodev /run/shm
    echo "/run/shm options set and persisted in /etc/fstab."
  else
    echo "/run/shm is already secured in /etc/fstab."
  fi
}

# ===============================
# Secure other key directories (/home, /dev/shm)
# ===============================
secure_additional_directories() {
  echo "Securing /home and /dev/shm..."

  # Secure /home with nodev (to prevent device files)
  if ! grep -q "/home" /etc/fstab; then
    echo "Adding nodev to /home in /etc/fstab."
    echo "/dev/sdaX /home ext4 defaults,nodev 0 2" >> /etc/fstab # Adjust /dev/sdaX based on actual partition
    mount -o remount,nodev /home
    echo "/home secured with nodev."
  else
    echo "/home is already secured in /etc/fstab."
  fi

  # Secure /dev/shm with noexec, nosuid, nodev
  if ! grep -q "/dev/shm" /etc/fstab; then
    echo "tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
    mount -o remount,noexec,nosuid,nodev /dev/shm
    echo "/dev/shm options set and persisted in /etc/fstab."
  else
    echo "/dev/shm is already secured in /etc/fstab."
  fi
}

# ===============================
# Main function to apply all security measures
# ===============================
main() {
  backup_fstab
  secure_tmp
  secure_var_tmp
  secure_run_shm
  secure_additional_directories
  echo "ANSSI Disk Partition Hardening measures applied successfully. Reboot the system to activate changes."
}

# Run the main function
main
