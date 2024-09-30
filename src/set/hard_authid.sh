#!/bin/bash

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Starting authentication and identification hardening process..."

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
# Set Password Policies
# ===============================
echo "Configuring password policies..."
if ! grep -q "pam_pwquality.so" /etc/pam.d/common-password; then
  echo "password requisite pam_pwquality.so retry=3 minlen=12 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1" >> /etc/pam.d/common-password
  echo "Password policy configured."
else
  echo "Password policy already configured."
fi

# ===============================
# Enforce Password Complexity
# ===============================
echo "Enforcing password complexity..."
if dpkg -l | grep -q libpam-cracklib; then
  echo "libpam-cracklib is already installed."
else
  apt-get install -y libpam-cracklib
fi

if ! grep -q "pam_cracklib.so" /etc/pam.d/common-password; then
  echo "password requisite pam_cracklib.so retry=3 minlen=12 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=3" >> /etc/pam.d/common-password
  echo "Password complexity enforced."
else
  echo "Password complexity already enforced."
fi

# ===============================
# Set Account Lockout Policy (using pam_faillock if available)
# ===============================
if grep -q "pam_faillock.so" /etc/pam.d/common-auth; then
  echo "Account lockout policy already configured with pam_faillock."
else
  if dpkg -l | grep -q pam_faillock; then
    echo "Configuring account lockout policy with pam_faillock..."
    echo "auth required pam_faillock.so preauth silent deny=5 unlock_time=1800" >> /etc/pam.d/common-auth
    echo "auth required pam_faillock.so authfail deny=5 unlock_time=1800" >> /etc/pam.d/common-auth
  else
    echo "Configuring account lockout policy with pam_tally2..."
    echo "auth required pam_tally2.so deny=5 unlock_time=1800" >> /etc/pam.d/common-auth
  fi
  echo "Account lockout policy configured."
fi

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

