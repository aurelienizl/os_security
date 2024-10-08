#!/bin/bash

# Logging function
log() {
  local log_level=$1
  local message=$2
  local log_file="/var/log/hardening_script.log"

  # Get current timestamp
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  # Format message with timestamp and log level
  formatted_message="$timestamp [$log_level] $message"

  # Print to console
  echo "$formatted_message"

  # Append to log file
  echo "$formatted_message" >> "$log_file"
}
