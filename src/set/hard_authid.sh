#!/bin/bash

echo "Starting authentication and identification hardening process..."

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Function to install packages if they are not already installed
install_if_missing() {
  package=$1
  if ! dpkg -l | grep -q "$package"; then
    echo "Installing $package..."
    sudo apt-get update && sudo apt-get install -y "$package"
  else
    echo "$package is already installed."
  fi
}

# Install necessary packages
install_if_missing "libpam-pwquality"
install_if_missing "fail2ban"

# ===============================
# Backup Critical Configuration Files
# ===============================
backup_file() {
  local file="$1"
  if [ -f "$file" ] && [ ! -f "$file.bak" ]; then
    cp "$file" "$file.bak"
    echo "Backup of $file created."
  else
    echo "Backup for $file already exists or the file does not exist."
  fi
}

backup_file "/etc/pam.d/common-password"
backup_file "/etc/pam.d/common-auth"
backup_file "/etc/ssh/sshd_config"
backup_file "/etc/pam.d/su"

# ===============================
# Set Password Policies and configurations
# ===============================
echo "Setting password policies..."
if [ -f "config/common-password" ]; then
  sudo cp config/common-password /etc/pam.d/common-password
else
  echo "common-password configuration file not found!"
fi

# ===============================
# Set Account Lockout Policy
# ===============================
echo "Setting account lockout policy..."
if [ -f "config/common-auth" ]; then
  sudo cp config/common-auth /etc/pam.d/common-auth
else
  echo "common-auth configuration file not found!"
fi

# ===============================
# Enforce SSH Security
# ===============================
echo "Enforcing SSH security..."
if [ -f "config/sshd_config" ]; then
  sudo cp config/sshd_config /etc/ssh/sshd_config

  # Check if the sshd service is enabled
  if systemctl is-enabled --quiet sshd; then
    # If enabled, check if it's active and reload if necessary
    if systemctl is-active --quiet sshd; then
      sudo systemctl reload sshd
      echo "SSH configuration reloaded as the service is active."
    else
      echo "SSH service is enabled but not running. Configuration updated, no reload necessary."
    fi
  else
    echo "SSH service is disabled. Configuration updated without reloading the service."
  fi
else
  echo "sshd_config configuration file not found!"
fi


# Configure fail2ban
echo "Configuring fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# ===============================
# Limit Access to the su Command
# ===============================
echo "Limiting access to the su command..."
if [ -f "config/su" ]; then
  sudo cp config/su /etc/pam.d/su
else
  echo "su configuration file not found!"
fi

# Ensure 'wheel' group exists
if ! grep -q "^wheel:" /etc/group; then
  sudo groupadd wheel
  echo "wheel group created."
else
  echo "wheel group already exists."
fi

# ===============================
# Configure Session Timeout
# ===============================
echo "Configuring session timeout..."

# Check if TMOUT is already set in /etc/profile
if ! grep -q "TMOUT=600" /etc/profile; then
  {
    echo "TMOUT=600"
    echo "readonly TMOUT"
    echo "export TMOUT"
  } >> /etc/profile
  echo "Session timeout configured."
else
  echo "Session timeout is already configured."
fi

# ===============================
# Concluding Message
# ===============================
echo "Authentication and Identification Hardening measures applied successfully."
echo "Please restart services or reboot the system to activate changes."
