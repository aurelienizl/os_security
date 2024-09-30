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

# ===============================
# Ensure /tmp is on a separate partition
# ===============================
echo "Creating and mounting a separate partition for /tmp..."
tmp_partition="/tmp_partition"
if ! mount | grep -q "on /tmp "; then
  dd if=/dev/zero of=$tmp_partition bs=1M count=512
  mkfs.ext4 $tmp_partition
  mount -o loop $tmp_partition /tmp
  echo "$tmp_partition /tmp ext4 loop,noexec,nosuid,nodev 0 0" >> /etc/fstab
  echo "Separate /tmp partition created and mounted."
else
  echo "/tmp is already on a separate partition."
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
# Create separate partitions for /home, /var, and /usr
# ===============================
create_partition() {
  partition=$1
  mount_point=$2
  size_mb=$3

  if ! mount | grep -q "on $mount_point "; then
    echo "Creating a separate partition for $mount_point..."
    dd if=/dev/zero of=$partition bs=1M count=$size_mb
    mkfs.ext4 $partition
    mount -o loop $partition $mount_point
    echo "$partition $mount_point ext4 loop 0 0" >> /etc/fstab
    echo "$mount_point partition created and mounted."
  else
    echo "$mount_point is already on a separate partition."
  fi
}

# Adjust partition sizes as needed
create_partition "/home_partition" "/home" 10240
create_partition "/var_partition" "/var" 20480
create_partition "/usr_partition" "/usr" 40960

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
