#!/bin/bash
source ./log.sh

log "INFO" "Starting verification of authentication and identification hardening..."

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR" "Please run this script as root."
  exit 1
fi

# ===============================
# Check Installed Packages
# ===============================
check_package() {
  package=$1
  if dpkg -l | grep -q "$package"; then
    log "INFO" "$package is installed."
  else
    log "WARNING" "$package is NOT installed."
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
    log "INFO" "Backup for $file exists."
  else
    log "WARNING" "No backup for $file found."
  fi
}

check_backup "/etc/pam.d/common-password"
check_backup "/etc/pam.d/common-auth"
check_backup "/etc/ssh/sshd_config"
check_backup "/etc/pam.d/su"

# ===============================
# Verify Password Policies
# ===============================
log "INFO" "Verifying password policies..."
if cmp -s config/common-password /etc/pam.d/common-password; then
  log "INFO" "Password policy configuration matches expected settings."
else
  log "WARNING" "Password policy configuration does not match!"
fi

# ===============================
# Verify Account Lockout Policy
# ===============================
log "INFO" "Verifying account lockout policy..."
if cmp -s config/common-auth /etc/pam.d/common-auth; then
  log "INFO" "Account lockout policy matches expected settings."
else
  log "WARNING" "Account lockout policy does not match!"
fi

# ===============================
# Verify SSH Configuration
# ===============================
log "INFO" "Verifying SSH configuration..."
if cmp -s config/sshd_config /etc/ssh/sshd_config; then
  log "INFO" "SSH configuration matches expected settings."
else
  log "WARNING" "SSH configuration does not match!"
fi

# ===============================
# Verify su Command Limitation
# ===============================
log "INFO" "Verifying su command limitation..."
if cmp -s config/su /etc/pam.d/su; then
  log "INFO" "su command limitation matches expected settings."
else
  log "WARNING" "su command limitation does not match!"
fi

# ===============================
# Check for Wheel Group
# ===============================
if grep -q "^wheel:" /etc/group; then
  log "INFO" "wheel group exists."
else
  log "WARNING" "wheel group does not exist!"
fi

# ===============================
# Verify Session Timeout
# ===============================
log "INFO" "Verifying session timeout configuration..."
if grep -q "TMOUT=600" /etc/profile; then
  log "INFO" "Session timeout is configured correctly."
else
  log "WARNING" "Session timeout is NOT configured!"
fi

# ===============================
# Concluding Message
# ===============================
log "INFO" "Verification of authentication and identification hardening completed."
