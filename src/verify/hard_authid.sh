#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Checking authentication and identification hardening compliance..."

# ===============================
# Check if libpam-pwquality or libpam-cracklib is installed
# ===============================
echo "Checking if libpam-pwquality or libpam-cracklib is installed..."
if dpkg -l | grep -q "libpam-pwquality" || dpkg -l | grep -q "libpam-cracklib"; then
    echo "libpam-pwquality or libpam-cracklib is installed."
else
    echo "libpam-pwquality or libpam-cracklib is not installed. Please install it with: sudo apt-get install libpam-pwquality"
fi

# ===============================
# Check password policies in PAM
# ===============================
echo "Checking password policies..."
if grep -q "pam_pwquality.so" /etc/pam.d/common-password && grep -q "retry=3" /etc/pam.d/common-password && \
   grep -q "minlen=12" /etc/pam.d/common-password && grep -q "ucredit=-1" /etc/pam.d/common-password && \
   grep -q "lcredit=-1" /etc/pam.d/common-password && grep -q "dcredit=-1" /etc/pam.d/common-password && \
   grep -q "ocredit=-1" /etc/pam.d/common-password; then
  echo "Password policy for complexity and retries is correctly set."
else
  echo "Password policy for complexity and retries is not correctly set."
fi

# ===============================
# Check account lockout policy
# ===============================
echo "Checking account lockout policy..."
if grep -q "pam_tally2.so" /etc/pam.d/common-auth && grep -q "deny=5" /etc/pam.d/common-auth && \
   grep -q "unlock_time=1800" /etc/pam.d/common-auth; then
  echo "Account lockout policy is correctly set."
else
  echo "Account lockout policy is not correctly set."
fi

# ===============================
# Check if root login is disabled
# ===============================
echo "Checking if root login is disabled..."
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
  echo "Root login is disabled."
else
  echo "Root login is not disabled."
fi

# ===============================
# Check su command restrictions
# ===============================
echo "Checking su command restrictions..."
if grep -q "auth required pam_wheel.so" /etc/pam.d/su && grep -q "^wheel:x:10:" /etc/group; then
  echo "su command restrictions are correctly set."
else
  echo "su command restrictions are not correctly set."
fi

# ===============================
# Check login banner configuration
# ===============================
echo "Checking login banner configuration..."
if grep -q "Authorized access only. All activity may be monitored and reported." /etc/issue.net && \
   grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config; then
  echo "Login banner is correctly configured."
else
  echo "Login banner is not correctly configured."
fi

# ===============================
# Check session timeout configuration
# ===============================
echo "Checking session timeout configuration..."
if grep -q "TMOUT=600" /etc/profile && grep -q "readonly TMOUT" /etc/profile && grep -q "export TMOUT" /etc/profile; then
  echo "Session timeout is correctly set."
else
  echo "Session timeout is not correctly set."
fi

# ===============================
# Final Message
# ===============================
echo "Authentication and identification hardening compliance check completed."
