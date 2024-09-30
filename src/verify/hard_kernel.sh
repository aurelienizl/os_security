#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Checking kernel hardening compliance..."

# ===============================
# Backup Kernel Configuration
# ===============================
# Check if a backup of the kernel configuration exists
kernel_config_backup="/boot/config-$(uname -r).bak"
if [ -f "$kernel_config_backup" ]; then
  echo "Kernel configuration backup exists."
else
  echo "Kernel configuration backup does not exist."
fi

# ===============================
# Address Space Layout Randomization (ASLR)
# ===============================
# Check ASLR settings
aslr_value=$(sysctl kernel.randomize_va_space | awk '{print $3}')
if [ "$aslr_value" -eq 2 ]; then
  echo "Address Space Layout Randomization (ASLR) is enabled."
else
  echo "ASLR is not enabled. Current value: $aslr_value"
fi

# ===============================
# ExecShield Check
# ===============================
# ExecShield is typically relevant on older kernels
exec_shield_value=$(sysctl kernel.exec-shield 2>/dev/null | awk '{print $3}')
if [ -n "$exec_shield_value" ] && [ "$exec_shield_value" -eq 1 ]; then
  echo "ExecShield is enabled."
elif [ -z "$exec_shield_value" ]; then
  echo "ExecShield is not applicable on this system (might be a modern kernel)."
else
  echo "ExecShield is not enabled. Current value: $exec_shield_value"
fi

# ===============================
# Kernel Module Signing
# ===============================
# Check if kernel module signing is enforced
modprobe_conf="/etc/modprobe.d/modules.conf"
if [ -f "$modprobe_conf" ]; then
  if grep -q "modules.sig_enforce=1" "$modprobe_conf"; then
    echo "Kernel module signing enforcement is enabled."
  else
    echo "Kernel module signing enforcement is not enabled."
  fi
else
  echo "$modprobe_conf does not exist."
fi

# ===============================
# Strict File Permissions on Kernel Modules
# ===============================
# Check permissions on the modprobe configuration files
if [ -f "$modprobe_conf" ]; then
  perms=$(stat -c "%a" "$modprobe_conf")
  if [ "$perms" -eq 600 ]; then
    echo "Strict permissions on kernel module configurations are set."
  else
    echo "Permissions on $modprobe_conf are not correct. Current permissions: $perms"
  fi
else
  echo "$modprobe_conf does not exist."
fi

# ===============================
# Ptrace Security
# ===============================
# Check ptrace security settings
ptrace_scope_value=$(sysctl kernel.yama.ptrace_scope | awk '{print $3}')
if [ "$ptrace_scope_value" -eq 3 ]; then
  echo "Ptrace scope is set to the highest security level."
else
  echo "Ptrace scope is not set correctly. Current value: $ptrace_scope_value"
fi

# ===============================
# Secure Core Dumps
# ===============================
# Check if core dumps are restricted
suid_dumpable_value=$(sysctl fs.suid_dumpable | awk '{print $3}')
if [ "$suid_dumpable_value" -eq 0 ]; then
  echo "Core dumps are restricted."
else
  echo "Core dumps are not restricted. Current value: $suid_dumpable_value"
fi

# ===============================
# Kernel Log Permissions
# ===============================
# Check permissions on kernel logs
check_log_permissions() {
  log_file=$1
  if [ -f "$log_file" ]; then
    perms=$(stat -c "%a" "$log_file")
    if [ "$perms" -eq 600 ]; then
      echo "$log_file has correct permissions."
    else
      echo "$log_file does not have correct permissions. Current permissions: $perms"
    fi
  else
    echo "$log_file does not exist."
  fi
}

check_log_permissions "/var/log/dmesg"
check_log_permissions "/var/log/kern.log"

# ===============================
# Kernel Module Restrictions
# ===============================
# Check if unnecessary kernel modules are disabled (by modprobe)
check_module_disabled() {
  module=$1
  conf_file="/etc/modprobe.d/disable-$module.conf"
  if grep -q "install $module /bin/true" "$conf_file" 2>/dev/null; then
    echo "$module module is disabled."
  else
    echo "$module module is not disabled."
  fi
}

check_module_disabled "usb-storage"
check_module_disabled "cramfs"
check_module_disabled "freevxfs"
check_module_disabled "jffs2"
check_module_disabled "hfs"
check_module_disabled "hfsplus"

# ===============================
# File System Support Check
# ===============================
# Check if support for unnecessary file systems is disabled in the kernel config
kernel_config="/boot/config-$(uname -r)"
check_kernel_config() {
  option=$1
  expected_value=$2
  if grep -q "$option=$expected_value" "$kernel_config"; then
    echo "$option is correctly set to $expected_value."
  else
    echo "$option is not correctly set. Check $kernel_config for $option."
  fi
}

check_kernel_config "CONFIG_SQUASHFS" "n"
check_kernel_config "CONFIG_UDF_FS" "n"
check_kernel_config "CONFIG_VFAT_FS" "n"
check_kernel_config "CONFIG_X86_16BIT" "y"

# ===============================
# Final Message
# ===============================
echo "Kernel hardening compliance check completed."
