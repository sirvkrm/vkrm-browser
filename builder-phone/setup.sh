#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/env.sh"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

write_code_server_config() {
  cat >"$BUILDER_PHONE_CODE_SERVER_CONFIG_FILE" <<EOF
bind-addr: 0.0.0.0:${BUILDER_PHONE_CODE_SERVER_PORT}
auth: password
cert: false
disable-telemetry: true
disable-update-check: true
abs-proxy-base-path: /vscode
EOF
}

upsert_ini() {
  local file="$1"
  local key="$2"
  local value="$3"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  sed -i "/^${key}=.*/d" "$file"
  printf '%s=%s\n' "$key" "$value" >>"$file"
}

write_settings_file() {
  cat >"$BUILDER_PHONE_SETTINGS_FILE" <<EOF
BUILDER_PHONE_WEB_HOST=$(printf '%q' "$BUILDER_PHONE_WEB_HOST")
BUILDER_PHONE_CERT_MODE=$(printf '%q' "$BUILDER_PHONE_CERT_MODE")
BUILDER_PHONE_CERT_CRT_FILE=$(printf '%q' "$BUILDER_PHONE_CERT_CRT_FILE")
BUILDER_PHONE_CERT_KEY_FILE=$(printf '%q' "$BUILDER_PHONE_CERT_KEY_FILE")
EOF
}

ensure_passwords() {
  if [[ ! -f "$BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE" ]]; then
    openssl rand -hex 16 >"$BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE"
    chmod 600 "$BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE"
  fi

  if [[ ! -f "$BUILDER_PHONE_VNC_PASSWORD_FILE" ]]; then
    openssl rand -hex 4 >"$BUILDER_PHONE_VNC_PASSWORD_FILE"
    chmod 600 "$BUILDER_PHONE_VNC_PASSWORD_FILE"
  fi

  if [[ ! -f "$BUILDER_PHONE_VNC_PASSWD_FILE" ]]; then
    x11vnc -storepasswd "$(cat "$BUILDER_PHONE_VNC_PASSWORD_FILE")" "$BUILDER_PHONE_VNC_PASSWD_FILE" >/dev/null
    chmod 600 "$BUILDER_PHONE_VNC_PASSWD_FILE"
  fi
}

install_system_packages() {
  local packages=(
    ca-certificates
    curl
    jq
    nginx
    novnc
    unzip
    websockify
    x11vnc
    xvfb
  )

  if [[ "$(id -u)" -ne 0 ]]; then
    echo "setup.sh requires root so it can apt-install the required packages." >&2
    exit 1
  fi

  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends "${packages[@]}"
}

prepare_nginx_runtime_dirs() {
  mkdir -p /var/log/nginx
  touch /var/log/nginx/access.log /var/log/nginx/error.log
}

install_cmdline_tools() {
  local repo_xml="$BUILDER_PHONE_DOWNLOADS_DIR/repository2-1.xml"
  local zip_name
  local zip_url

  curl -fsSL https://dl.google.com/android/repository/repository2-1.xml -o "$repo_xml"
  zip_name="$(
    python3 - "$repo_xml" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

repo_xml = sys.argv[1]
root = ET.parse(repo_xml).getroot()
best = None
best_name = None
for pkg in root.findall("remotePackage"):
    path = pkg.attrib.get("path", "")
    m = re.fullmatch(r"cmdline-tools;(\d+\.\d+)", path)
    if not m:
        continue
    version = tuple(int(x) for x in m.group(1).split("."))
    chosen_url = None
    for archive in pkg.findall("./archives/archive"):
        host = archive.findtext("host-os")
        url = archive.findtext("./complete/url")
        if host == "linux" and url:
            chosen_url = url
            break
    if chosen_url and (best is None or version > best):
        best = version
        best_name = chosen_url
if not best_name:
    raise SystemExit("Unable to resolve latest command-line tools URL")
print(best_name)
PY
  )"
  zip_url="https://dl.google.com/android/repository/${zip_name}"

  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  if [[ ! -f "$BUILDER_PHONE_DOWNLOADS_DIR/$zip_name" ]]; then
    curl -fL -o "$BUILDER_PHONE_DOWNLOADS_DIR/$zip_name" "$zip_url"
  fi

  rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest.tmp"
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools/latest.tmp"
  unzip -q -o "$BUILDER_PHONE_DOWNLOADS_DIR/$zip_name" -d "$ANDROID_SDK_ROOT/cmdline-tools/latest.tmp"
  rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  mv "$ANDROID_SDK_ROOT/cmdline-tools/latest.tmp/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  rmdir "$ANDROID_SDK_ROOT/cmdline-tools/latest.tmp"
}

install_android_packages() {
  set +o pipefail
  yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null || true
  set -o pipefail

  sdkmanager --sdk_root="$ANDROID_SDK_ROOT" \
    "platform-tools" \
    "emulator" \
    "$BUILDER_PHONE_ANDROID_PLATFORM" \
    "$BUILDER_PHONE_AVD_PACKAGE"
}

create_avd() {
  if [[ ! -d "$ANDROID_AVD_HOME/${BUILDER_PHONE_AVD_NAME}.avd" ]]; then
    printf 'no\n' | avdmanager create avd \
      --name "$BUILDER_PHONE_AVD_NAME" \
      --device "$BUILDER_PHONE_AVD_DEVICE" \
      --package "$BUILDER_PHONE_AVD_PACKAGE"
  fi

  local ini="$ANDROID_AVD_HOME/${BUILDER_PHONE_AVD_NAME}.avd/config.ini"
  upsert_ini "$ini" "hw.gpu.enabled" "yes"
  upsert_ini "$ini" "hw.gpu.mode" "swiftshader_indirect"
  upsert_ini "$ini" "hw.keyboard" "yes"
  upsert_ini "$ini" "hw.cpu.ncore" "$BUILDER_PHONE_AVD_CORES"
  upsert_ini "$ini" "hw.ramSize" "$BUILDER_PHONE_AVD_RAM_MB"
  upsert_ini "$ini" "vm.heapSize" "$BUILDER_PHONE_AVD_VM_HEAP_MB"
  upsert_ini "$ini" "disk.dataPartition.size" "$BUILDER_PHONE_AVD_DATA_PARTITION_SIZE"
  upsert_ini "$ini" "sdcard.size" "$BUILDER_PHONE_AVD_SDCARD_SIZE"
  upsert_ini "$ini" "showDeviceFrame" "no"
  upsert_ini "$ini" "skin.dynamic" "yes"
  upsert_ini "$ini" "fastboot.forceColdBoot" "yes"
}

install_code_server_extensions() {
  if ! command -v code-server >/dev/null 2>&1; then
    echo "code-server is not installed in PATH; skipping extension install." >&2
    return 0
  fi

  code-server \
    --user-data-dir "$BUILDER_PHONE_CODE_SERVER_DATA_DIR" \
    --extensions-dir "$BUILDER_PHONE_CODE_SERVER_EXTENSIONS_DIR" \
    --install-extension DiemasMichiels.emulate \
    --install-extension toroxx.vscode-avdmanager \
    --install-extension adelphes.android-dev-ext
}

resolve_web_host() {
  local detected_ip prompt_default user_input

  detected_ip="$(builder_phone_detect_public_ip)"
  if [[ -z "$detected_ip" && -z "${BUILDER_PHONE_WEB_HOST:-}" ]]; then
    echo "Unable to detect a public IP automatically." >&2
    exit 1
  fi

  prompt_default="${BUILDER_PHONE_WEB_HOST:-$detected_ip}"
  if [[ -t 0 ]]; then
    read -r -p "Domain for builder-phone [${prompt_default}] (leave blank to use the shown value): " user_input
    BUILDER_PHONE_WEB_HOST="${user_input:-$prompt_default}"
  elif [[ -z "${BUILDER_PHONE_WEB_HOST:-}" ]]; then
    BUILDER_PHONE_WEB_HOST="$prompt_default"
  fi

  export BUILDER_PHONE_WEB_HOST
}

stop_default_lighttpd_if_needed() {
  local process80 http_head

  process80="$(builder_phone_process_listening_on_port "$BUILDER_PHONE_HTTP_PORT" || true)"
  if [[ -z "$process80" || "$process80" == "nginx" ]]; then
    return 0
  fi

  if [[ "$process80" != "lighttpd" ]]; then
    echo "Port ${BUILDER_PHONE_HTTP_PORT} is already occupied by ${process80}. Refusing to replace it automatically." >&2
    exit 1
  fi

  http_head="$(curl -sSI --max-time 5 http://127.0.0.1/ 2>/dev/null | tr -d '\r' || true)"
  if ! grep -q '^HTTP/1.1 403' <<<"$http_head" || ! grep -q '^Server: lighttpd/' <<<"$http_head"; then
    echo "Port ${BUILDER_PHONE_HTTP_PORT} is served by lighttpd, but it does not look like the default placeholder site. Refusing to replace it automatically." >&2
    exit 1
  fi

  systemctl disable --now lighttpd
}

ensure_https_port_available() {
  local process443

  process443="$(builder_phone_process_listening_on_port "$BUILDER_PHONE_HTTPS_PORT" || true)"
  if [[ -n "$process443" && "$process443" != "nginx" ]]; then
    echo "Port ${BUILDER_PHONE_HTTPS_PORT} is already occupied by ${process443}. Refusing to replace it automatically." >&2
    exit 1
  fi
}

write_nginx_locations() {
  cat <<EOF
  location = / {
    return 302 /vscode/;
  }

  location = /vscode {
    return 301 /vscode/;
  }

  location /vscode/ {
    proxy_pass http://127.0.0.1:${BUILDER_PHONE_CODE_SERVER_PORT}/;
    proxy_http_version 1.1;
    proxy_set_header Host \$http_host;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$builder_phone_connection_upgrade;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Prefix /vscode;
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;
    proxy_buffering off;
  }

  location = /phone {
    return 302 /phone/vnc.html?autoconnect=1&resize=remote&reconnect=1&path=phone/websockify;
  }

  location = /phone/ {
    return 302 /phone/vnc.html?autoconnect=1&resize=remote&reconnect=1&path=phone/websockify;
  }

  location /phone/ {
    proxy_pass http://127.0.0.1:${BUILDER_PHONE_NOVNC_PORT}/;
    proxy_http_version 1.1;
    proxy_set_header Host \$http_host;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$builder_phone_connection_upgrade;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;
    proxy_buffering off;
  }

  location /websockify {
    proxy_pass http://127.0.0.1:${BUILDER_PHONE_NOVNC_PORT};
    proxy_http_version 1.1;
    proxy_set_header Host \$http_host;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$builder_phone_connection_upgrade;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;
    proxy_buffering off;
  }
EOF
}

write_nginx_config() {
  local mode="${1:-https}"

  mkdir -p "$(dirname "$BUILDER_PHONE_NGINX_CONFIG_FILE")"
  cat >"$BUILDER_PHONE_NGINX_CONFIG_FILE" <<EOF
map \$http_upgrade \$builder_phone_connection_upgrade {
  default upgrade;
  '' close;
}

server {
  listen ${BUILDER_PHONE_HTTP_PORT};
  listen [::]:${BUILDER_PHONE_HTTP_PORT};
  server_name ${BUILDER_PHONE_WEB_HOST} _;
  client_max_body_size 0;

  location ^~ /.well-known/acme-challenge/ {
    alias ${BUILDER_PHONE_ACME_CHALLENGE_DIR}/;
    default_type text/plain;
    try_files \$uri =404;
  }
EOF

  if [[ "$mode" == "https" ]]; then
    cat >>"$BUILDER_PHONE_NGINX_CONFIG_FILE" <<'EOF'
  location / {
    return 301 https://$host$request_uri;
  }
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
EOF
    cat >>"$BUILDER_PHONE_NGINX_CONFIG_FILE" <<EOF
  server_name ${BUILDER_PHONE_WEB_HOST} _;
  client_max_body_size 0;
  ssl_certificate ${BUILDER_PHONE_CERT_CRT_FILE};
  ssl_certificate_key ${BUILDER_PHONE_CERT_KEY_FILE};
  ssl_session_cache shared:builder_phone_ssl:10m;
  ssl_session_timeout 1d;
  ssl_protocols TLSv1.2 TLSv1.3;
EOF
    write_nginx_locations >>"$BUILDER_PHONE_NGINX_CONFIG_FILE"
    cat >>"$BUILDER_PHONE_NGINX_CONFIG_FILE" <<'EOF'
}
EOF
  else
    write_nginx_locations >>"$BUILDER_PHONE_NGINX_CONFIG_FILE"
    cat >>"$BUILDER_PHONE_NGINX_CONFIG_FILE" <<'EOF'
}
EOF
  fi
}

create_self_signed_certificate() {
  local san_entry

  mkdir -p "$BUILDER_PHONE_CERT_DIR"
  if builder_phone_is_ip "$BUILDER_PHONE_WEB_HOST"; then
    san_entry="IP:${BUILDER_PHONE_WEB_HOST}"
  else
    san_entry="DNS:${BUILDER_PHONE_WEB_HOST}"
  fi

  openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 825 \
    -keyout "$BUILDER_PHONE_CERT_KEY_FILE" \
    -out "$BUILDER_PHONE_CERT_CRT_FILE" \
    -subj "/CN=${BUILDER_PHONE_WEB_HOST}" \
    -addext "subjectAltName = ${san_entry}" >/dev/null 2>&1

  chmod 600 "$BUILDER_PHONE_CERT_KEY_FILE"
  chmod 644 "$BUILDER_PHONE_CERT_CRT_FILE"
  BUILDER_PHONE_CERT_MODE="self-signed"
}

try_obtain_letsencrypt_certificate() {
  if builder_phone_is_ip "$BUILDER_PHONE_WEB_HOST"; then
    return 1
  fi

  if ! command -v certbot >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y --no-install-recommends certbot
  fi

  write_nginx_config http
  nginx -t
  systemctl enable nginx
  systemctl restart nginx

  if certbot certonly \
    --non-interactive \
    --agree-tos \
    --register-unsafely-without-email \
    --keep-until-expiring \
    --webroot \
    -w "$BUILDER_PHONE_ACME_DIR" \
    -d "$BUILDER_PHONE_WEB_HOST"; then
    BUILDER_PHONE_CERT_MODE="letsencrypt"
    BUILDER_PHONE_CERT_CRT_FILE="/etc/letsencrypt/live/${BUILDER_PHONE_WEB_HOST}/fullchain.pem"
    BUILDER_PHONE_CERT_KEY_FILE="/etc/letsencrypt/live/${BUILDER_PHONE_WEB_HOST}/privkey.pem"
    return 0
  fi

  return 1
}

configure_nginx_proxy() {
  stop_default_lighttpd_if_needed
  ensure_https_port_available
  prepare_nginx_runtime_dirs

  if ! try_obtain_letsencrypt_certificate; then
    create_self_signed_certificate
  fi

  write_settings_file
  write_nginx_config https
  nginx -t
  systemctl enable nginx
  systemctl restart nginx
}

builder_phone_mkdirs
require_cmd openssl
require_cmd python3
require_cmd rg
require_cmd systemctl

install_system_packages
resolve_web_host
install_cmdline_tools
install_android_packages
create_avd
write_code_server_config
ensure_passwords
install_code_server_extensions
configure_nginx_proxy
write_settings_file

echo "builder-phone setup complete"
echo "web host: $BUILDER_PHONE_WEB_HOST"
echo "certificate mode: $BUILDER_PHONE_CERT_MODE"
echo "code-server password file: $BUILDER_PHONE_CODE_SERVER_PASSWORD_FILE"
echo "VNC password file: $BUILDER_PHONE_VNC_PASSWORD_FILE"
