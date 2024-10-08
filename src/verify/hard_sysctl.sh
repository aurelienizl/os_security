# ANSSI SECTION R9
# ANSSI SECTION R10
# ANSSI SECTION R12

#!/bin/bash
source ./log.sh

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR" "Please run this script as root."
  exit 1
fi

log "INFO" "Starting sysctl configuration compliance check..."

# Path to the sysctl configuration file
sysctl_config="/etc/sysctl.conf"

# Check if the sysctl configuration file exists
if [ ! -f "$sysctl_config" ]; then
  log "ERROR" "sysctl configuration file not found."
  exit 1
fi

# List of sysctl parameters to check with their expected values
declare -A sysctl_params=(
  ["kernel.dmesg_restrict"]="1"
  ["kernel.kptr_restrict"]="2"
  ["kernel.pid_max"]="65536"
  ["kernel.perf_cpu_time_max_percent"]="1"
  ["kernel.perf_event_max_sample_rate"]="1"
  ["kernel.perf_event_paranoid"]="2"
  ["kernel.randomize_va_space"]="2"
  ["kernel.sysrq"]="0"
  ["kernel.unprivileged_bpf_disabled"]="1"
  ["kernel.panic_on_oops"]="1"
  ["kernel.modules_disabled"]="1"
  ["kernel.yama.ptrace_scope"]="1"
  ["net.core.bpf_jit_harden"]="2"
  ["net.ipv4.ip_forward"]="0"
  ["net.ipv4.conf.all.accept_local"]="0"
  ["net.ipv4.conf.all.accept_redirects"]="0"
  ["net.ipv4.conf.default.accept_redirects"]="0"
  ["net.ipv4.conf.all.secure_redirects"]="0"
  ["net.ipv4.conf.default.secure_redirects"]="0"
  ["net.ipv4.conf.all.shared_media"]="0"
  ["net.ipv4.conf.default.shared_media"]="0"
  ["net.ipv4.conf.all.accept_source_route"]="0"
  ["net.ipv4.conf.default.accept_source_route"]="0"
  ["net.ipv4.conf.all.arp_filter"]="1"
  ["net.ipv4.conf.all.arp_ignore"]="2"
  ["net.ipv4.conf.all.route_localnet"]="0"
  ["net.ipv4.conf.all.drop_gratuitous_arp"]="1"
  ["net.ipv4.conf.default.rp_filter"]="1"
  ["net.ipv4.conf.all.rp_filter"]="1"
  ["net.ipv4.conf.default.send_redirects"]="0"
  ["net.ipv4.conf.all.send_redirects"]="0"
  ["net.ipv4.icmp_ignore_bogus_error_responses"]="1"
  ["net.ipv4.ip_local_port_range"]="32768 65535"
  ["net.ipv4.tcp_rfc1337"]="1"
  ["net.ipv4.tcp_syncookies"]="1"
  ["net.ipv6.conf.default.disable_ipv6"]="1"
  ["net.ipv6.conf.all.disable_ipv6"]="1"
  ["fs.suid_dumpable"]="0"
  ["fs.protected_fifos"]="2"
  ["fs.protected_regular"]="2"
  ["fs.protected_symlinks"]="1"
  ["fs.protected_hardlinks"]="1"
)

# Function to check if the parameter exists and has the correct value
check_sysctl_param() {
  param=$1
  expected_value=$2
  actual_value=$(sudo sysctl -n "$param" 2>/dev/null)

  if [ "$actual_value" == "$expected_value" ]; then
    log "INFO" "$param is correctly set to $expected_value."
  else
    if [ -z "$actual_value" ]; then
      log "WARNING" "$param is not found in the configuration."
    else
      log "WARNING" "$param is set to $actual_value but should be $expected_value."
    fi
  fi
}

# Loop through each parameter and check its presence and value
for param in "${!sysctl_params[@]}"; do
  check_sysctl_param "$param" "${sysctl_params[$param]}"
done

log "INFO" "Sysctl configuration compliance check completed."
