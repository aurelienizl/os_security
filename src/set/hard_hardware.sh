#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# ===============================
# Disable USB Ports
# ===============================
echo "Disabling USB ports by blacklisting the usb-storage module..."
echo "blacklist usb-storage" > /etc/modprobe.d/disable-usb-storage.conf

# Remove the usb-storage module if it is currently loaded
if lsmod | grep -q "usb_storage"; then
    modprobe -r usb-storage
    echo "USB storage module removed."
else
    echo "USB storage module is not loaded."
fi

# ===============================
# Restrict Access to Serial Ports
# ===============================
echo "Restricting access to serial ports..."
if ls /dev/ttyS* 1>/dev/null 2>&1; then
    chmod 700 /dev/ttyS*
    echo "Serial ports access restricted."
else
    echo "No serial ports found."
fi

# ===============================
# Disable Firewire Modules
# ===============================
echo "Disabling Firewire modules..."
if lsmod | grep -q "firewire"; then
    echo "install firewire-core /bin/true" > /etc/modprobe.d/disable-firewire.conf
    echo "install firewire-ohci /bin/true" >> /etc/modprobe.d/disable-firewire.conf
    echo "Firewire modules disabled."
else
    echo "No Firewire modules loaded."
fi

# ===============================
# Restrict Physical Console Access
# ===============================
echo "Restricting physical console access..."
if ! grep -q "^console$" /etc/securetty; then
    echo "console" >> /etc/securetty
    echo "Physical console access restricted."
else
    echo "Console access already restricted."
fi

# ===============================
# Set BIOS/UEFI Password (manual step)
# ===============================
echo "Please set a BIOS/UEFI password manually through your system BIOS."

# ===============================
# Disable Booting from External Media
# ===============================
echo "Disabling booting from external media..."

# Backup GRUB configuration if not already backed up
if [ ! -f /etc/default/grub.bak ]; then
    cp /etc/default/grub /etc/default/grub.bak
    echo "GRUB configuration backed up."
else
    echo "GRUB backup already exists."
fi

# Disable recovery mode booting in GRUB
if grep -q 'GRUB_DISABLE_RECOVERY="false"' /etc/default/grub; then
    sed -i 's/GRUB_DISABLE_RECOVERY="false"/GRUB_DISABLE_RECOVERY="true"/' /etc/default/grub
    echo "Recovery mode disabled in GRUB."
else
    echo "GRUB recovery mode is already disabled."
fi

# Update GRUB
update-grub
echo "GRUB configuration updated."

# ===============================
# Check for UEFI and Secure Boot
# ===============================
echo "Checking UEFI and Secure Boot status..."
if [ -d /sys/firmware/efi ]; then
    echo "UEFI is detected."

    # Check Secure Boot status
    if mokutil --sb-state | grep -q "SecureBoot enabled"; then
        echo "Secure Boot is already enabled."
    else
        echo "Secure Boot is not enabled."
    fi
else
    echo "UEFI is not detected, Secure Boot is not applicable."
fi

# ===============================
# Set a GRUB Bootloader Password
# ===============================
echo "Setting GRUB bootloader password..."
if [ ! -f /etc/default/grub.bak ]; then
    cp /etc/default/grub /etc/default/grub.bak
    echo "GRUB configuration backed up."
fi

echo "Enter the desired GRUB password:"
read -s grub_password
encrypted_password=$(echo -e "$grub_password\n$grub_password" | grub-mkpasswd-pbkdf2 | grep "grub.pbkdf2.*" | awk '{print $NF}')

# Update GRUB with the password
sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ quiet splash\"/" /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "GRUB_PASSWORD=$encrypted_password" >> /etc/default/grub

# Update GRUB configuration
update-grub
echo "GRUB password has been set. GRUB configuration updated."

# ===============================
# Lock the Root Account
# ===============================
echo "Locking the root account..."
if passwd -S root | grep -q "L"; then
    echo "Root account is already locked."
else
    passwd -l root
    echo "Root account locked."
fi

# ===============================
# Set Strong Password Policy
# ===============================
echo "Setting strong password policy..."
sed -i 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t90/' /etc/login.defs
sed -i 's/PASS_MIN_DAYS\t0/PASS_MIN_DAYS\t7/' /etc/login.defs
sed -i 's/PASS_WARN_AGE\t7/PASS_WARN_AGE\t14/' /etc/login.defs
echo "Password policy updated."

# ===============================
# Concluding Message
# ===============================
echo "ANSSI Hardware Hardening measures applied successfully."
