#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Starting modern kernel hardening process..."

# ===============================
# Backup existing kernel configuration (if available)
# ===============================
echo "Backing up existing kernel configuration..."
kernel_config="/boot/config-$(uname -r)"
if [ -f "$kernel_config" ]; then
  cp "$kernel_config" "$kernel_config.bak"
  echo "Kernel configuration backed up to $kernel_config.bak"
else
  echo "Kernel configuration file not found: $kernel_config"
fi

# ===============================
# Enable Address Space Layout Randomization (ASLR)
# ===============================
echo "Enabling Address Space Layout Randomization (ASLR)..."
sysctl_file="/etc/sysctl.conf"
if ! grep -q "kernel.randomize_va_space" "$sysctl_file"; then
  echo "kernel.randomize_va_space = 2" >> "$sysctl_file"
  sysctl -p
  echo "ASLR enabled."
else
  echo "ASLR is already enabled."
fi

# ===============================
# Disable unnecessary kernel modules
# ===============================
echo "Disabling unnecessary kernel modules..."
unnecessary_modules=("cramfs" "freevxfs" "jffs2" "hfs" "hfsplus")
for mod in "${unnecessary_modules[@]}"; do
  if [ ! -f /etc/modprobe.d/disable-$mod.conf ]; then
    echo "install $mod /bin/true" > "/etc/modprobe.d/disable-$mod.conf"
    echo "$mod module disabled."
  else
    echo "$mod module is already disabled."
  fi
done

# ===============================
# Enable stricter ptrace security
# ===============================
echo "Enabling stricter ptrace security..."
if ! grep -q "kernel.yama.ptrace_scope" "$sysctl_file"; then
  echo "kernel.yama.ptrace_scope = 3" >> "$sysctl_file"
  sysctl -p
  echo "Stricter ptrace security enabled."
else
  echo "Ptrace security is already enabled."
fi

# ===============================
# Set core dumps to a secure location
# ===============================
echo "Setting core dumps to a secure location..."
if ! grep -q "fs.suid_dumpable" "$sysctl_file"; then
  echo "fs.suid_dumpable = 0" >> "$sysctl_file"
  sysctl -p
  echo "Core dumps restricted."
else
  echo "Core dump restrictions are already applied."
fi

# ===============================
# Restrict access to kernel logs
# ===============================
echo "Restricting access to kernel logs..."
if [ -f /var/log/dmesg ]; then
  chmod 600 /var/log/dmesg
  echo "/var/log/dmesg access restricted."
fi
if [ -f /var/log/kern.log ]; then
  chmod 600 /var/log/kern.log
  echo "/var/log/kern.log access restricted."
fi

# ===============================
# Enable kernel module signing enforcement (Optional)
# ===============================
echo "Enforcing kernel module signing..."
if [ ! -f /etc/modprobe.d/modules.conf ]; then
  echo "options module.sig_enforce=1" > /etc/modprobe.d/modules.conf
  chmod 600 /etc/modprobe.d/modules.conf
  echo "Kernel module signing enforcement enabled."
else
  echo "Kernel module signing enforcement is already configured."
fi

# ===============================
# Disable uncommon/legacy filesystems (Optional)
# ===============================
echo "Disabling uncommon filesystems..."
legacy_filesystems=("squashfs" "udf" "vfat")
for fs in "${legacy_filesystems[@]}"; do
  if ! grep -q "$fs" /etc/modprobe.d/disable-$fs.conf; then
    echo "install $fs /bin/true" > /etc/modprobe.d/disable-$fs.conf
    echo "$fs filesystem support disabled."
  else
    echo "$fs filesystem support is already disabled."
  fi
done

# ===============================
# Finalizing kernel hardening
# ===============================
echo "Kernel hardening process completed successfully."
echo "Please review any output and reboot the system to apply all changes."
