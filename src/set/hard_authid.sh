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
# Set Account Lockout Policy
# ===============================
echo "Setting account lockout policy..."
sudo cp config/common-auth /etc/pam.d/common-auth

# ===============================
# Enforce SSH
# ===============================
sudo cp config/sshd_config /etc/ssh/sshd_config
sudo apt install fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# ===============================
# Limit Access to the su Command
# ===============================
sudo cp config/su /etc/pam.d/su

# If the group wheel does not exist, create it
if ! grep -q "^wheel:" /etc/group; then
  groupadd wheel
fi

# ===============================
# Configure Session Timeout
# ===============================]

echo "Configuring session timeout..."

# Check if TMOUT is already set in /etc/profile
if ! grep -q "TMOUT=600" /etc/profile; then
  echo "TMOUT=600" >>/etc/profile
  echo "readonly TMOUT" >>/etc/profile
  echo "export TMOUT" >>/etc/profile
  echo "Session timeout configured."
else
  echo "Session timeout is already configured."
fi

# ===============================
# Concluding Message
# ===============================
echo "Authentication and Identification Hardening measures applied successfully."
echo "Please restart services or reboot the system to activate changes."
