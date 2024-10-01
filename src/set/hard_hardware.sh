#!/bin/bash

# ===============================
# Check for root privileges
# ===============================
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# ===============================
# Disable USB Ports
# ===============================
disable_usb_ports() {
    echo "Disabling USB ports by blacklisting the usb-storage module..."
    echo "blacklist usb-storage" >/etc/modprobe.d/disable-usb-storage.conf
    echo "USB storage ports disabled."
}

# ===============================
# Restrict Access to Serial Ports
# ===============================
restrict_serial_ports() {
    echo "Restricting access to serial ports..."
    if ls /dev/ttyS* 1>/dev/null 2>&1; then
        chmod 700 /dev/ttyS*
        echo "Serial ports access restricted."
    else
        echo "No serial ports found."
    fi
}

# ===============================
# Disable Firewire Modules
# ===============================
disable_firewire() {
    echo "Disabling Firewire modules..."
    echo "blacklist firewire-core" >/etc/modprobe.d/disable-firewire.conf
    echo "blacklist firewire-ohci" >>/etc/modprobe.d/disable-firewire.conf
    echo "Firewire modules disabled."
}

# ===============================
# Restrict Physical Console Access
# ===============================
restrict_console_access() {
    echo "Restricting physical console access..."
    if ! grep -q "^console$" /etc/securetty; then
        echo "console" >>/etc/securetty
        echo "Physical console access restricted."
    else
        echo "Console access already restricted."
    fi
}

# ===============================
# Disable Booting from External Media
# ===============================
disable_external_boot() {
    echo "Disabling booting from external media..."

    # Backup GRUB configuration
    if [ ! -f /etc/default/grub.bak ]; then
        cp /etc/default/grub /etc/default/grub.bak
        echo "GRUB configuration backed up."
    else
        echo "GRUB backup already exists."
    fi

    # Disable recovery mode in GRUB
    if grep -q 'GRUB_DISABLE_RECOVERY="false"' /etc/default/grub; then
        sed -i 's/GRUB_DISABLE_RECOVERY="false"/GRUB_DISABLE_RECOVERY="true"/' /etc/default/grub
        echo "Recovery mode disabled in GRUB."
    else
        echo "GRUB recovery mode is already disabled."
    fi

    # Update GRUB
    update-grub
    echo "GRUB configuration updated."
}

# ===============================
# Check UEFI and Secure Boot Status
# ===============================
check_uefi_secure_boot() {
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
}

# ===============================
# Set GRUB Bootloader Password
# ===============================
set_grub_password() {
    echo "Setting GRUB bootloader password..."

    # Backup GRUB configuration if not already done
    if [ ! -f /etc/default/grub.bak ]; then
        cp /etc/default/grub /etc/default/grub.bak
        echo "GRUB configuration backed up."
    fi

    # Check if GRUB password is already set
    if grep -q "GRUB_PASSWORD" /etc/default/grub; then
        echo "GRUB password is already set."
        return
    fi

    # Ask for password
    echo "Enter the desired GRUB password:"
    read -s grub_password
    encrypted_password=$(echo -e "$grub_password\n$grub_password" | grub-mkpasswd-pbkdf2 | grep "grub.pbkdf2.*" | awk '{print $NF}')

    # Update GRUB with password
    sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ quiet splash\"/" /etc/default/grub
    echo "GRUB_ENABLE_CRYPTODISK=y" >>/etc/default/grub
    echo "GRUB_PASSWORD=$encrypted_password" >>/etc/default/grub

    # Update GRUB configuration
    update-grub
    echo "GRUB password has been set. GRUB configuration updated."
}

# ===============================
# Lock the Root Account
# ===============================
lock_root_account() {
    echo "Locking the root account..."
    if passwd -S root | grep -q "L"; then
        echo "Root account is already locked."
    else
        passwd -l root
        echo "Root account locked."
    fi
}

# ===============================
# Set Strong Password Policy
# ===============================
set_password_policy() {
    echo "Setting strong password policy..."

    # Check if password policy is already set
    if grep -q "PASS_MAX_DAYS" /etc/login.defs; then
        echo "Password policy is already set."
        return
    fi

    sed -i 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t90/' /etc/login.defs
    sed -i 's/PASS_MIN_DAYS\t0/PASS_MIN_DAYS\t7/' /etc/login.defs
    sed -i 's/PASS_WARN_AGE\t7/PASS_WARN_AGE\t14/' /etc/login.defs
    echo "Password policy updated."
}

# ===============================
# Run all functions
# ===============================
disable_usb_ports
restrict_serial_ports
disable_firewire
restrict_console_access
disable_external_boot
check_uefi_secure_boot
set_grub_password
lock_root_account
set_password_policy

# ===============================
# Concluding Message
# ===============================
echo "ANSSI Hardware Hardening measures applied successfully."
