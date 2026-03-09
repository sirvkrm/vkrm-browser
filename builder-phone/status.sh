#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/env.sh"

show_status() {
  local name="$1"
  local pid_file="$2"
  if builder_phone_pid_is_running "$pid_file"; then
    echo "$name: running (PID $(cat "$pid_file"))"
  else
    echo "$name: stopped"
  fi
}

if builder_phone_pid_is_running "$BUILDER_PHONE_CODE_SERVER_PID_FILE"; then
  echo "code-server: running (PID $(cat "$BUILDER_PHONE_CODE_SERVER_PID_FILE"))"
else
  code_server_pid="$(builder_phone_pid_listening_on_port "$BUILDER_PHONE_CODE_SERVER_PORT" || true)"
  if [[ -n "${code_server_pid:-}" ]]; then
    echo "$code_server_pid" >"$BUILDER_PHONE_CODE_SERVER_PID_FILE"
    echo "code-server: running (PID $code_server_pid)"
  else
    echo "code-server: stopped"
  fi
fi

show_status "Xvfb" "$BUILDER_PHONE_XVFB_PID_FILE"
show_status "x11vnc" "$BUILDER_PHONE_X11VNC_PID_FILE"
show_status "noVNC" "$BUILDER_PHONE_NOVNC_PID_FILE"
show_status "emulator" "$BUILDER_PHONE_EMULATOR_PID_FILE"
nginx_process="$(builder_phone_process_listening_on_port "$BUILDER_PHONE_HTTP_PORT" || true)"
if [[ "$nginx_process" == "nginx" ]]; then
  echo "nginx: running"
else
  echo "nginx: stopped"
fi

echo
echo "Workspace: $BUILDER_PHONE_WORKSPACE_FILE"
echo "code-server URL: http://<server-ip>:${BUILDER_PHONE_CODE_SERVER_PORT}/"
echo "noVNC URL: http://<server-ip>:${BUILDER_PHONE_NOVNC_PORT}/vnc.html"
if [[ -n "${BUILDER_PHONE_WEB_HOST:-}" ]]; then
  echo "proxied code-server URL: https://${BUILDER_PHONE_WEB_HOST}/vscode/"
  echo "proxied phone URL: https://${BUILDER_PHONE_WEB_HOST}/phone/"
fi
echo "code-server password file: $BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE"
echo "VNC password file: $BUILDER_PHONE_VNC_PASSWORD_FILE"
