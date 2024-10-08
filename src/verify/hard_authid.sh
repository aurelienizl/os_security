#!/bin/bash
source ./log.sh

echo "Starting verification of authentication and identification hardening..."

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# ===============================
# Check Installed Packages
# ===============================
check_package() {
  package=$1
  if dpkg -l | grep -q "$package"; then
    echo "$package is installed."
  else
    echo "$package is NOT installed."
  fi
}

check_package "libpam-pwquality"
check_package "fail2ban"

# ===============================
# Check for Backups of Critical Configuration Files
# ===============================
check_backup() {
  file=$1
  if [ -f "$file.bak" ]; then
    echo "Backup for $file exists."
  else
    echo "No backup for $file found."
  fi
}

check_backup "/etc/pam.d/common-password"
check_backup "/etc/pam.d/common-auth"
check_backup "/etc/ssh/sshd_config"
check_backup "/etc/pam.d/su"

# ===============================
# Verify Password Policies
# ===============================
echo "Verifying password policies..."
if cmp -s config/common-password /etc/pam.d/common-password; then
  echo "Password policy configuration matches expected settings."
else
  echo "Password policy configuration does not match!"
fi

# ===============================
# Verify Account Lockout Policy
# ===============================
echo "Verifying account lockout policy..."
if cmp -s config/common-auth /etc/pam.d/common-auth; then
  echo "Account lockout policy matches expected settings."
else
  echo "Account lockout policy does not match!"
fi

# ===============================
# Verify SSH Configuration
# ===============================
echo "Verifying SSH configuration..."
if cmp -s config/sshd_config /etc/ssh/sshd_config; then
  echo "SSH configuration matches expected settings."
else
  echo "SSH configuration does not match!"
fi

# ===============================
# Verify su Command Limitation
# ===============================
echo "Verifying su command limitation..."
if cmp -s config/su /etc/pam.d/su; then
  echo "su command limitation matches expected settings."
else
  echo "su command limitation does not match!"
fi

# ===============================
# Check for Wheel Group
# ===============================
if grep -q "^wheel:" /etc/group; then
  echo "wheel group exists."
else
  echo "wheel group does not exist!"
fi

# ===============================
# Verify Session Timeout
# ===============================
echo "Verifying session timeout configuration..."
if grep -q "TMOUT=600" /etc/profile; then
  echo "Session timeout is configured correctly."
else
  echo "Session timeout is NOT configured!"
fi

# ===============================
# Concluding Message
# ===============================
echo "Verification of authentication and identification hardening completed."
