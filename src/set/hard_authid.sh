#!/bin/bash

echo "Starting authentication and identification hardening process..."

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Install necessary packages
sudo apt install libpam-pwquality

# ===============================
# Backup Critical Configuration Files
# ===============================
backup_file() {
  file=$1
  if [ -f "$file" ] && [ ! -f "$file.bak" ]; then
    cp "$file" "$file.bak"
    echo "Backup of $file created."
  fi
}

backup_file "/etc/pam.d/common-password"
backup_file "/etc/pam.d/common-auth"
backup_file "/etc/ssh/sshd_config"

# ===============================
# Set Password Policies and configurations
# ===============================
echo "Setting password policies..."
sudo cp config/common-password /etc/pam.d/common-password

# ===============================
# Set Account Lockout Policy (using pam_faillock if available)
# ===============================
echo "Setting account lockout policy..."
sudo cp config/common-auth /etc/pam.d/common-auth

# ===============================
# Disable Root Login (SSH)
# ===============================
echo "Disabling root login for SSH..."
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
  sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  echo "Root login disabled."
else
  echo "Root login is already disabled."
fi

# ===============================
# Limit Access to the su Command
# ===============================
echo "Limiting access to the su command..."
if ! grep -q "auth required pam_wheel.so" /etc/pam.d/su; then
  echo "auth required pam_wheel.so" >> /etc/pam.d/su
  echo "Access to the su command restricted."
else
  echo "Access to the su command is already restricted."
fi

if ! grep -q "^wheel:x:10" /etc/group; then
  echo "wheel:x:10:username" >> /etc/group
  echo "Wheel group added."
else
  echo "Wheel group already exists."
fi

# ===============================
# Enable Login Banner
# ===============================
echo "Enabling login banner..."
banner_text="Authorized access only. All activity may be monitored and reported."
if ! grep -q "$banner_text" /etc/issue.net; then
  echo "$banner_text" > /etc/issue.net
  if ! grep -q "^Banner /etc/issue.net" /etc/ssh/sshd_config; then
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
  fi
  echo "Login banner enabled."
else
  echo "Login banner is already enabled."
fi

# ===============================
# Configure Session Timeout
# ===============================
echo "Configuring session timeout..."
if ! grep -q "TMOUT=600" /etc/profile; then
  echo "TMOUT=600" >> /etc/profile
  echo "readonly TMOUT" >> /etc/profile
  echo "export TMOUT" >> /etc/profile
  echo "Session timeout configured."
else
  echo "Session timeout is already configured."
fi

# ===============================
# Concluding Message
# ===============================
echo "ANSSI Authentication and Identification Hardening measures applied successfully."
echo "Please restart services or reboot the system to activate changes."

