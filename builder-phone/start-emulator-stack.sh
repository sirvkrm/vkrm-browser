#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/env.sh"

builder_phone_mkdirs

if builder_phone_has_kvm; then
  emu_accel=( -accel on )
else
  emu_accel=( -accel off )
fi

if [[ ! -f "$BUILDER_PHONE_VNC_PASSWD_FILE" ]]; then
  echo "Missing $BUILDER_PHONE_VNC_PASSWD_FILE. Run ./setup.sh first." >&2
  exit 1
fi

if [[ ! -x "$ANDROID_SDK_ROOT/emulator/emulator" ]]; then
  echo "Missing Android emulator at $ANDROID_SDK_ROOT/emulator/emulator. Run ./setup.sh first." >&2
  exit 1
fi

if builder_phone_pid_is_running "$BUILDER_PHONE_EMULATOR_PID_FILE"; then
  echo "Emulator stack is already running with PID $(cat "$BUILDER_PHONE_EMULATOR_PID_FILE")."
  exit 0
fi

setsid Xvfb "$BUILDER_PHONE_DISPLAY" -screen 0 "$BUILDER_PHONE_SCREEN" -nolisten tcp \
  >"$BUILDER_PHONE_LOG_DIR/xvfb.log" 2>&1 < /dev/null &
echo $! >"$BUILDER_PHONE_XVFB_PID_FILE"

if ! builder_phone_wait_for_display 20; then
  echo "Xvfb did not become ready." >&2
  exit 1
fi

setsid x11vnc \
  -display "$BUILDER_PHONE_DISPLAY" \
  -rfbauth "$BUILDER_PHONE_VNC_PASSWD_FILE" \
  -rfbport "$BUILDER_PHONE_VNC_PORT" \
  -localhost \
  -forever \
  -shared \
  -noxdamage \
  -no6 \
  >"$BUILDER_PHONE_LOG_DIR/x11vnc.log" 2>&1 < /dev/null &
echo $! >"$BUILDER_PHONE_X11VNC_PID_FILE"

setsid /usr/share/novnc/utils/novnc_proxy \
  --listen "$BUILDER_PHONE_NOVNC_PORT" \
  --vnc "127.0.0.1:${BUILDER_PHONE_VNC_PORT}" \
  --web /usr/share/novnc \
  >"$BUILDER_PHONE_LOG_DIR/novnc.log" 2>&1 < /dev/null &
echo $! >"$BUILDER_PHONE_NOVNC_PID_FILE"

export DISPLAY="$BUILDER_PHONE_DISPLAY"
setsid "$ANDROID_SDK_ROOT/emulator/emulator" "@${BUILDER_PHONE_AVD_NAME}" \
  -port 5554 \
  -no-metrics \
  -no-snapshot \
  -no-audio \
  -no-boot-anim \
  -gpu "$BUILDER_PHONE_EMULATOR_GPU_MODE" \
  "${emu_accel[@]}" \
  -memory "$BUILDER_PHONE_AVD_RAM_MB" \
  -cores "$BUILDER_PHONE_AVD_CORES" \
  -camera-back none \
  -camera-front none \
  >"$BUILDER_PHONE_LOG_DIR/emulator.log" 2>&1 < /dev/null &
echo $! >"$BUILDER_PHONE_EMULATOR_PID_FILE"

adb start-server >/dev/null
if builder_phone_wait_for_boot emulator-5554 90; then
  echo "Emulator boot completed."
else
  echo "Emulator launched, but Android did not finish booting within the wait window." >&2
fi

echo "noVNC URL: http://<server-ip>:${BUILDER_PHONE_NOVNC_PORT}/vnc.html"
echo "VNC password: $(cat "$BUILDER_PHONE_VNC_PASSWORD_FILE")"
