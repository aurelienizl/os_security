#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Starting kernel hardening process..."

# ===============================
# Backup existing kernel configuration
# ===============================
echo "Backing up existing kernel configuration..."
kernel_config="/boot/config-$(uname -r)"
if [ -f "$kernel_config" ]; then
  cp "$kernel_config" "$kernel_config.bak"
  echo "Kernel configuration backed up to $kernel_config.bak"
else
  echo "Kernel configuration file not found: $kernel_config"
  exit 1
fi

# ===============================
# Enable Address Space Layout Randomization (ASLR)
# ===============================
echo "Enabling Address Space Layout Randomization (ASLR)..."
if ! grep -q "CONFIG_RANDOMIZE_BASE=y" /usr/src/linux/.config; then
  echo "CONFIG_RANDOMIZE_BASE=y" >> /usr/src/linux/.config
fi
if ! grep -q "CONFIG_RANDOMIZE_MODULE_REGION_FULL=y" /usr/src/linux/.config; then
  echo "CONFIG_RANDOMIZE_MODULE_REGION_FULL=y" >> /usr/src/linux/.config
fi

# ===============================
# Set a maximum address space for mmap
# ===============================
echo "Setting maximum address space for mmap..."
if ! grep -q "CONFIG_DEFAULT_MMAP_MIN_ADDR=65536" /usr/src/linux/.config; then
  echo "CONFIG_DEFAULT_MMAP_MIN_ADDR=65536" >> /usr/src/linux/.config
fi

# ===============================
# Disable support for unnecessary file systems
# ===============================
echo "Disabling support for unnecessary file systems..."
unnecessary_filesystems=("CONFIG_SQUASHFS=n" "CONFIG_UDF_FS=n" "CONFIG_VFAT_FS=n")
for fs in "${unnecessary_filesystems[@]}"; do
  if ! grep -q "$fs" /usr/src/linux/.config; then
    echo "$fs" >> /usr/src/linux/.config
  fi
done

# ===============================
# Compile kernel with the new configuration
# ===============================
echo "Compiling kernel with the new configuration..."
make oldconfig && make && make modules_install && make install

# ===============================
# Restrict access to kernel logs
# ===============================
echo "Restricting access to kernel logs..."
chmod 600 /var/log/dmesg
chmod 600 /var/log/kern.log

# ===============================
# Enable process execution prevention
# ===============================
echo "Enabling process execution prevention..."
if ! grep -q "kernel.exec-shield = 1" /etc/sysctl.conf; then
  echo "kernel.exec-shield = 1" >> /etc/sysctl.conf
fi
if ! grep -q "kernel.randomize_va_space = 2" /etc/sysctl.conf; then
  echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf
fi
sysctl -p

# ===============================
# Restrict kernel module loading
# ===============================
echo "Restricting kernel module loading..."
restricted_modules=("cramfs" "freevxfs" "jffs2" "hfs" "hfsplus")
for mod in "${restricted_modules[@]}"; do
  echo "install $mod /bin/true" > /etc/modprobe.d/disable-$mod.conf
done

# ===============================
# Disable support for legacy 16-bit x86 code
# ===============================
echo "Disabling support for legacy 16-bit x86 code..."
if ! grep -q "CONFIG_X86_16BIT=y" /usr/src/linux/.config; then
  echo "CONFIG_X86_16BIT=y" >> /usr/src/linux/.config
fi

# ===============================
# Enable kernel module signing
# ===============================
echo "Enabling kernel module signing..."
echo "options modprobe modules.sig_enforce=1" > /etc/modprobe.d/modules.conf
chmod 0600 /etc/modprobe.d/modules.conf

# ===============================
# Enable stricter ptrace security
# ===============================
echo "Enabling stricter ptrace security..."
if ! grep -q "kernel.yama.ptrace_scope=3" /etc/sysctl.conf; then
  echo "kernel.yama.ptrace_scope=3" >> /etc/sysctl.conf
fi
sysctl -p

# ===============================
# Set core dumps to a secure location
# ===============================
echo "Setting core dumps to a secure location..."
if ! grep -q "fs.suid_dumpable = 0" /etc/sysctl.conf; then
  echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
fi
sysctl -p

# ===============================
# Restrict kernel logs
# ===============================
echo "Restricting access to kernel logs..."
chmod o-rwx /var/log/dmesg
chmod o-rwx /var/log/kern.log
echo "Kernel logs are now restricted."

# ===============================
# Finalizing kernel hardening
# ===============================
echo "Kernel hardening process completed."

# ===============================
# Compile and install the new kernel
# ===============================
echo "Compiling and installing the new kernel..."
make && make modules_install && make install
if [ $? -eq 0 ]; then
  echo "Kernel compilation and installation successful."
else
  echo "Kernel compilation or installation failed."
  exit 1
fi

# ===============================
# Display concluding message
# ===============================
echo "ANSSI Kernel Configuration Hardening applied successfully."
echo "Please reboot the system to apply the changes."


