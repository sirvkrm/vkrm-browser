#!/usr/bin/env bash

set -euo pipefail

BUILDER_PHONE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export BUILDER_PHONE_DIR
export BUILDER_PHONE_DOWNLOADS_DIR="${BUILDER_PHONE_DOWNLOADS_DIR:-$BUILDER_PHONE_DIR/.downloads}"
export BUILDER_PHONE_LOG_DIR="${BUILDER_PHONE_LOG_DIR:-$BUILDER_PHONE_DIR/logs}"
export BUILDER_PHONE_RUN_DIR="${BUILDER_PHONE_RUN_DIR:-$BUILDER_PHONE_DIR/run}"
export BUILDER_PHONE_SECRETS_DIR="${BUILDER_PHONE_SECRETS_DIR:-$BUILDER_PHONE_DIR/secrets}"
export BUILDER_PHONE_CERT_DIR="${BUILDER_PHONE_CERT_DIR:-$BUILDER_PHONE_DIR/certs}"
export BUILDER_PHONE_ACME_DIR="${BUILDER_PHONE_ACME_DIR:-$BUILDER_PHONE_DIR/acme-webroot}"
export BUILDER_PHONE_SETTINGS_FILE="${BUILDER_PHONE_SETTINGS_FILE:-$BUILDER_PHONE_DIR/builder-phone.conf}"

export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$BUILDER_PHONE_DIR/android-sdk}"
export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$BUILDER_PHONE_DIR/avd-home}"
export ANDROID_EMULATOR_HOME="${ANDROID_EMULATOR_HOME:-$BUILDER_PHONE_DIR/emulator-home}"

export BUILDER_PHONE_CODE_SERVER_DATA_DIR="${BUILDER_PHONE_CODE_SERVER_DATA_DIR:-$BUILDER_PHONE_DIR/code-server-data}"
export BUILDER_PHONE_CODE_SERVER_EXTENSIONS_DIR="${BUILDER_PHONE_CODE_SERVER_EXTENSIONS_DIR:-$BUILDER_PHONE_DIR/code-server-extensions}"
export BUILDER_PHONE_CODE_SERVER_CONFIG_FILE="${BUILDER_PHONE_CODE_SERVER_CONFIG_FILE:-$BUILDER_PHONE_DIR/code-server-config.yaml}"
export BUILDER_PHONE_WORKSPACE_FILE="${BUILDER_PHONE_WORKSPACE_FILE:-$BUILDER_PHONE_DIR/builder-phone.code-workspace}"

export BUILDER_PHONE_CODE_SERVER_PORT="${BUILDER_PHONE_CODE_SERVER_PORT:-18080}"
export BUILDER_PHONE_NOVNC_PORT="${BUILDER_PHONE_NOVNC_PORT:-16080}"
export BUILDER_PHONE_VNC_PORT="${BUILDER_PHONE_VNC_PORT:-15900}"
export BUILDER_PHONE_DISPLAY="${BUILDER_PHONE_DISPLAY:-:99}"
export BUILDER_PHONE_SCREEN="${BUILDER_PHONE_SCREEN:-1080x2200x24}"
export BUILDER_PHONE_EMULATOR_GPU_MODE="${BUILDER_PHONE_EMULATOR_GPU_MODE:-off}"
export BUILDER_PHONE_HTTP_PORT="${BUILDER_PHONE_HTTP_PORT:-80}"
export BUILDER_PHONE_HTTPS_PORT="${BUILDER_PHONE_HTTPS_PORT:-443}"
export BUILDER_PHONE_NGINX_CONFIG_FILE="${BUILDER_PHONE_NGINX_CONFIG_FILE:-/etc/nginx/conf.d/builder-phone.conf}"

export BUILDER_PHONE_AVD_NAME="${BUILDER_PHONE_AVD_NAME:-vkrm-phone}"
export BUILDER_PHONE_AVD_DEVICE="${BUILDER_PHONE_AVD_DEVICE:-medium_phone}"
export BUILDER_PHONE_AVD_PACKAGE="${BUILDER_PHONE_AVD_PACKAGE:-system-images;android-29;default;x86_64}"
export BUILDER_PHONE_ANDROID_PLATFORM="${BUILDER_PHONE_ANDROID_PLATFORM:-platforms;android-29}"
export BUILDER_PHONE_AVD_RAM_MB="${BUILDER_PHONE_AVD_RAM_MB:-8192}"
export BUILDER_PHONE_AVD_CORES="${BUILDER_PHONE_AVD_CORES:-8}"
export BUILDER_PHONE_AVD_VM_HEAP_MB="${BUILDER_PHONE_AVD_VM_HEAP_MB:-512}"
export BUILDER_PHONE_AVD_DATA_PARTITION_SIZE="${BUILDER_PHONE_AVD_DATA_PARTITION_SIZE:-50G}"
export BUILDER_PHONE_AVD_SDCARD_SIZE="${BUILDER_PHONE_AVD_SDCARD_SIZE:-2048M}"

export BUILDER_PHONE_WEB_HOST="${BUILDER_PHONE_WEB_HOST:-}"
export BUILDER_PHONE_CERT_MODE="${BUILDER_PHONE_CERT_MODE:-self-signed}"
export BUILDER_PHONE_CERT_CRT_FILE="${BUILDER_PHONE_CERT_CRT_FILE:-$BUILDER_PHONE_CERT_DIR/server.crt}"
export BUILDER_PHONE_CERT_KEY_FILE="${BUILDER_PHONE_CERT_KEY_FILE:-$BUILDER_PHONE_CERT_DIR/server.key}"
export BUILDER_PHONE_ACME_CHALLENGE_DIR="${BUILDER_PHONE_ACME_CHALLENGE_DIR:-$BUILDER_PHONE_ACME_DIR/.well-known/acme-challenge}"

_builder_phone_web_host_override="${BUILDER_PHONE_WEB_HOST}"
_builder_phone_cert_mode_override="${BUILDER_PHONE_CERT_MODE}"
_builder_phone_cert_crt_override="${BUILDER_PHONE_CERT_CRT_FILE}"
_builder_phone_cert_key_override="${BUILDER_PHONE_CERT_KEY_FILE}"

if [[ -f "$BUILDER_PHONE_SETTINGS_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$BUILDER_PHONE_SETTINGS_FILE"
fi

if [[ -n "${_builder_phone_web_host_override:-}" ]]; then
  BUILDER_PHONE_WEB_HOST="${_builder_phone_web_host_override}"
fi
if [[ -n "${_builder_phone_cert_mode_override:-}" ]]; then
  BUILDER_PHONE_CERT_MODE="${_builder_phone_cert_mode_override}"
fi
if [[ -n "${_builder_phone_cert_crt_override:-}" ]]; then
  BUILDER_PHONE_CERT_CRT_FILE="${_builder_phone_cert_crt_override}"
fi
if [[ -n "${_builder_phone_cert_key_override:-}" ]]; then
  BUILDER_PHONE_CERT_KEY_FILE="${_builder_phone_cert_key_override}"
fi

unset _builder_phone_web_host_override
unset _builder_phone_cert_mode_override
unset _builder_phone_cert_crt_override
unset _builder_phone_cert_key_override

export BUILDER_PHONE_XVFB_PID_FILE="$BUILDER_PHONE_RUN_DIR/xvfb.pid"
export BUILDER_PHONE_X11VNC_PID_FILE="$BUILDER_PHONE_RUN_DIR/x11vnc.pid"
export BUILDER_PHONE_NOVNC_PID_FILE="$BUILDER_PHONE_RUN_DIR/novnc.pid"
export BUILDER_PHONE_EMULATOR_PID_FILE="$BUILDER_PHONE_RUN_DIR/emulator.pid"
export BUILDER_PHONE_CODE_SERVER_PID_FILE="$BUILDER_PHONE_RUN_DIR/code-server.pid"

export BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE="$BUILDER_PHONE_SECRETS_DIR/code-server-password.txt"
export BUILDER_PHONE_VNC_PASSWORD_FILE="$BUILDER_PHONE_SECRETS_DIR/vnc-password.txt"
export BUILDER_PHONE_VNC_PASSWD_FILE="$BUILDER_PHONE_SECRETS_DIR/x11vnc.pass"

export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"

builder_phone_mkdirs() {
  mkdir -p \
    "$BUILDER_PHONE_DOWNLOADS_DIR" \
    "$BUILDER_PHONE_LOG_DIR" \
    "$BUILDER_PHONE_RUN_DIR" \
    "$BUILDER_PHONE_SECRETS_DIR" \
    "$BUILDER_PHONE_CERT_DIR" \
    "$BUILDER_PHONE_ACME_CHALLENGE_DIR" \
    "$ANDROID_SDK_ROOT" \
    "$ANDROID_AVD_HOME" \
    "$ANDROID_EMULATOR_HOME" \
    "$BUILDER_PHONE_CODE_SERVER_DATA_DIR" \
    "$BUILDER_PHONE_CODE_SERVER_EXTENSIONS_DIR"
}

builder_phone_has_kvm() {
  [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]
}

builder_phone_emulator_accel_flag() {
  if builder_phone_has_kvm; then
    printf '%s\n' "-accel on"
  else
    printf '%s\n' "-accel off"
  fi
}

builder_phone_pid_is_running() {
  local pid_file="$1"
  [[ -f "$pid_file" ]] || return 1
  local pid
  pid="$(cat "$pid_file")"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

builder_phone_wait_for_display() {
  local tries="${1:-20}"
  local i
  for i in $(seq 1 "$tries"); do
    if DISPLAY="$BUILDER_PHONE_DISPLAY" xdpyinfo >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

builder_phone_is_ip() {
  local value="${1:-}"
  [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

builder_phone_detect_public_ip() {
  local ip
  ip="$(curl -4fsSL https://api.ipify.org 2>/dev/null || true)"
  if [[ -z "$ip" ]]; then
    ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  fi
  printf '%s\n' "$ip"
}

builder_phone_wait_for_boot() {
  local serial="${1:-emulator-5554}"
  local tries="${2:-120}"
  local i boot anim release pm_path
  for i in $(seq 1 "$tries"); do
    boot="$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" || true
    anim="$(adb -s "$serial" shell getprop init.svc.bootanim 2>/dev/null | tr -d '\r')" || true
    release="$(adb -s "$serial" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')" || true
    pm_path="$(adb -s "$serial" shell pm path android 2>/dev/null | tr -d '\r')" || true
    if [[ "$boot" == "1" ]]; then
      return 0
    fi
    if [[ "$anim" == "stopped" && -n "$release" ]]; then
      return 0
    fi
    if [[ -n "$release" && "$pm_path" == package:* ]]; then
      return 0
    fi
    sleep 5
  done
  return 1
}

builder_phone_pid_listening_on_port() {
  local port="$1"
  ss -ltnp 2>/dev/null | awk -v port=":${port}" '
    $4 ~ port"$" {
      if (match($0, /pid=[0-9]+/)) {
        print substr($0, RSTART + 4, RLENGTH - 4)
        exit
      }
    }
  '
}

builder_phone_process_listening_on_port() {
  local port="$1"
  ss -ltnp 2>/dev/null | awk -v port=":${port}" '$4 ~ port"$" { print; exit }' \
    | sed -n 's/.*users:(("\([^"]*\)".*/\1/p'
}
