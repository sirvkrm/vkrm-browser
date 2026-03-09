#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/env.sh"

stop_from_pid_file() {
  local pid_file="$1"
  if builder_phone_pid_is_running "$pid_file"; then
    kill "$(cat "$pid_file")" 2>/dev/null || true
    sleep 1
    if builder_phone_pid_is_running "$pid_file"; then
      kill -9 "$(cat "$pid_file")" 2>/dev/null || true
    fi
  fi
  rm -f "$pid_file"
}

adb -s emulator-5554 emu kill >/dev/null 2>&1 || true

stop_from_pid_file "$BUILDER_PHONE_EMULATOR_PID_FILE"
stop_from_pid_file "$BUILDER_PHONE_NOVNC_PID_FILE"
stop_from_pid_file "$BUILDER_PHONE_X11VNC_PID_FILE"
stop_from_pid_file "$BUILDER_PHONE_XVFB_PID_FILE"

echo "Emulator stack stopped."
