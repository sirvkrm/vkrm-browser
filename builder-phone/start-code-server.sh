#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/env.sh"

builder_phone_mkdirs

if ! command -v code-server >/dev/null 2>&1; then
  echo "code-server is not installed in PATH." >&2
  exit 1
fi

if [[ ! -f "$BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE" ]]; then
  echo "Missing $BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE. Run ./setup.sh first." >&2
  exit 1
fi

if builder_phone_pid_is_running "$BUILDER_PHONE_CODE_SERVER_PID_FILE"; then
  echo "code-server is already running with PID $(cat "$BUILDER_PHONE_CODE_SERVER_PID_FILE")."
  exit 0
fi

export PASSWORD
PASSWORD="$(cat "$BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE")"

setsid -f code-server \
  --config "$BUILDER_PHONE_CODE_SERVER_CONFIG_FILE" \
  --user-data-dir "$BUILDER_PHONE_CODE_SERVER_DATA_DIR" \
  --extensions-dir "$BUILDER_PHONE_CODE_SERVER_EXTENSIONS_DIR" \
  "$BUILDER_PHONE_WORKSPACE_FILE" \
  </dev/null \
  >"$BUILDER_PHONE_LOG_DIR/code-server.log" 2>&1

echo 0 >"$BUILDER_PHONE_CODE_SERVER_PID_FILE"
sleep 2
code_server_pid="$(builder_phone_pid_listening_on_port "$BUILDER_PHONE_CODE_SERVER_PORT" || true)"
if [[ -n "${code_server_pid:-}" ]]; then
  echo "$code_server_pid" >"$BUILDER_PHONE_CODE_SERVER_PID_FILE"
fi

echo "code-server started on port $BUILDER_PHONE_CODE_SERVER_PORT"
echo "Password: $(cat "$BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE")"
if [[ -n "${BUILDER_PHONE_WEB_HOST:-}" ]]; then
  echo "Proxy URL: https://${BUILDER_PHONE_WEB_HOST}/vscode/"
fi
