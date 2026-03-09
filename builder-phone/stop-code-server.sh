#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/env.sh"

pid=""
if builder_phone_pid_is_running "$BUILDER_PHONE_CODE_SERVER_PID_FILE"; then
  pid="$(cat "$BUILDER_PHONE_CODE_SERVER_PID_FILE")"
else
  pid="$(builder_phone_pid_listening_on_port "$BUILDER_PHONE_CODE_SERVER_PORT" || true)"
fi

if [[ -n "$pid" ]]; then
  kill "$pid" 2>/dev/null || true
  sleep 1
  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true
  fi
fi

rm -f "$BUILDER_PHONE_CODE_SERVER_PID_FILE"
echo "code-server stopped."
