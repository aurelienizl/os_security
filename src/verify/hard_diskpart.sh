#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Checking disk partition hardening compliance..."

# ===============================
# Check if /tmp is on a separate partition
# ===============================
echo "Checking if /tmp is on a separate partition..."
tmp_partition=$(findmnt -n /tmp | awk '{print $1}')
if [ "$tmp_partition" != "tmpfs" ]; then
  echo "/tmp is on a separate partition: $tmp_partition"
else
  echo "/tmp is not on a separate partition."
fi

# ===============================
# Check mount options for /tmp
# ===============================
echo "Checking mount options for /tmp..."
if mount | grep -q 'on /tmp type' && mount | grep -q '/tmp.*noexec.*nosuid.*nodev'; then
  echo "/tmp has the noexec, nosuid, and nodev options."
else
  echo "/tmp does not have the correct mount options."
  echo "Current mount options: $(mount | grep 'on /tmp type')"
fi

# ===============================
# Check permissions for /var/tmp
# ===============================
echo "Checking permissions for /var/tmp..."
var_tmp_perms=$(stat -c "%a" /var/tmp)
if [ "$var_tmp_perms" -eq 1777 ]; then
  echo "/var/tmp has correct permissions (1777)."
else
  echo "/var/tmp does not have correct permissions. Current permissions: $var_tmp_perms"
fi

# ===============================
# Check if /home, /var, and /usr are on separate partitions
# ===============================
echo "Checking if /home, /var, and /usr are on separate partitions..."

check_partition() {
  partition=$1
  mount_point=$2
  partition_status=$(findmnt -n "$mount_point" | awk '{print $1}')
  if [ "$partition_status" != "$mount_point" ] && [ -n "$partition_status" ]; then
    echo "$mount_point is on a separate partition: $partition_status"
  else
    echo "$mount_point is not on a separate partition."
  fi
}

check_partition "/home_partition" "/home"
check_partition "/var_partition" "/var"
check_partition "/usr_partition" "/usr"

# ===============================
# Check if unnecessary mounts are disabled
# ===============================
echo "Checking if unnecessary mounts are disabled..."

if grep -q "tmpfs /run/shm" /etc/fstab && grep -q "noexec,nosuid,nodev" /etc/fstab; then
  echo "Unnecessary mounts are properly disabled in /run/shm."
else
  echo "Unnecessary mounts are not properly disabled in /run/shm."
fi

# ===============================
# Final Message
# ===============================
echo "Disk partition hardening compliance check completed."
