#!/usr/bin/env bash
set -euo pipefail

PORT=3000
REAL_DEVICE=false
WIFI_DEVICE=false
DEVICE_ID=""
WIFI_CONNECT=""
SKIP_BACKEND_CHECK=false

check_local_backend() {
  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsS --max-time 2 "http://127.0.0.1:${PORT}/" >/dev/null; then
      echo "Warning: backend does not seem reachable at http://127.0.0.1:${PORT}." >&2
      echo "Start backend before running the app to avoid 'Connection refused'." >&2
      return 1
    fi
  fi

  return 0
}

detect_lan_ip() {
  local ip=""

  # Try Linux-style first
  ip="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1; i<=NF; i++) if ($i=="src") {print $(i+1); exit}}')"
  if [[ -n "${ip}" ]]; then echo "${ip}"; return; fi

  ip="$(hostname -I 2>/dev/null | tr ' ' '\n' | awk '/^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ {print; exit}')"
  if [[ -n "${ip}" ]]; then echo "${ip}"; return; fi

  # Windows fallback (Git Bash / MSYS2): parse ipconfig output
  # Pick the IPv4 address that shares the same /24 subnet as the ADB Wi-Fi device if known
  if command -v ipconfig >/dev/null 2>&1; then
    ip="$(ipconfig 2>/dev/null | awk '/IPv4/{gsub(/\r/,""); match($0,/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,a); if (a[1] ~ /^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/) {print a[1]; exit}}')"
    if [[ -n "${ip}" ]]; then echo "${ip}"; return; fi
  fi

  echo ""
}

show_help() {
  cat <<'EOT'
Usage: ./scripts/run_phone.sh [options] [-- flutter_run_args]

Options:
  --real-device         Run on a USB Android device using adb reverse (no Wi-Fi fallback).
  --usb-only            Alias of --real-device.
  --wifi-device         Prefer an Android device connected with wireless debugging (adb over Wi-Fi).
  --wifi-connect <ip[:port]>
                        Run adb connect before flutter run (default port: 5555 if omitted).
  --device-id <id>      Explicit Flutter device id to run on.
  --port <port>         Backend API port (default: 3000).
  --skip-backend-check  Skip local backend reachability check before flutter run.
  --help                Show this message.
EOT
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --real-device)
      REAL_DEVICE=true
      shift
      ;;
    --usb-only)
      REAL_DEVICE=true
      shift
      ;;
    --wifi-device)
      WIFI_DEVICE=true
      shift
      ;;
    --wifi-connect)
      WIFI_CONNECT="${2:-}"
      if [[ -z "${WIFI_CONNECT}" ]]; then
        echo "Error: --wifi-connect requires an IP (optionally with :port)." >&2
        exit 1
      fi
      shift 2
      ;;
    --device-id)
      DEVICE_ID="${2:-}"
      if [[ -z "${DEVICE_ID}" ]]; then
        echo "Error: --device-id requires a value." >&2
        exit 1
      fi
      shift 2
      ;;
    --port)
      PORT="${2:-3000}"
      shift 2
      ;;
    --skip-backend-check)
      SKIP_BACKEND_CHECK=true
      shift
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter is not installed or not in PATH." >&2
  exit 1
fi

if [[ "${REAL_DEVICE}" == "true" ]]; then
  ADB_DEVICE=""

  if command -v adb >/dev/null 2>&1; then
    # First try USB device
    ADB_DEVICE="$(adb devices | awk '/^[^[:space:]]+[[:space:]]+device$/ && $1 !~ /:/ {print $1; exit}')"

    # Fallback: try WiFi ADB device (ip:port format)
    if [[ -z "${ADB_DEVICE}" ]]; then
      ADB_DEVICE="$(adb devices | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+[[:space:]]+device$/ {print $1; exit}')"
      if [[ -n "${ADB_DEVICE}" ]]; then
        echo "No USB device found, using Wi-Fi ADB device: ${ADB_DEVICE}"
      fi
    fi
  else
    echo "Warning: adb not found; install Android platform-tools for USB reverse." >&2
  fi

  if [[ -n "${ADB_DEVICE}" ]]; then
    if [[ -z "${DEVICE_ID}" ]]; then
      DEVICE_ID="${ADB_DEVICE}"
    fi

    echo "Device detected (${DEVICE_ID}). Setting adb reverse tcp:${PORT} -> tcp:${PORT}"
    if ! adb -s "${DEVICE_ID}" reverse "tcp:${PORT}" "tcp:${PORT}"; then
      echo "Error: failed to set adb reverse for port ${PORT}." >&2
      exit 1
    fi

    if [[ "${SKIP_BACKEND_CHECK}" != "true" ]]; then
      if ! check_local_backend; then
        echo "Error: REAL_DEVICE mode needs a running local backend on port ${PORT}." >&2
        echo "Hint: if your phone reaches backend over Wi-Fi/LAN, run without --real-device." >&2
        exit 1
      fi
    fi

    FLUTTER_CMD=(
      flutter run
      --dart-define="REAL_DEVICE=true"
      --dart-define="REAL_DEVICE_API_BASE_URL=http://127.0.0.1:${PORT}"
    )
    if [[ -n "${DEVICE_ID}" ]]; then
      FLUTTER_CMD+=(-d "${DEVICE_ID}")
    fi
    FLUTTER_CMD+=("$@")

    echo "Running in REAL_DEVICE mode with localhost via adb reverse"
    "${FLUTTER_CMD[@]}"
    exit 0
  fi

  echo "Error: no ADB device found (USB or Wi-Fi). Make sure your phone is connected and debugging is enabled." >&2
  exit 1
fi

if [[ -n "${WIFI_CONNECT}" ]]; then
  if ! command -v adb >/dev/null 2>&1; then
    echo "Error: adb is required for --wifi-connect." >&2
    exit 1
  fi

  if [[ "${WIFI_CONNECT}" != *:* ]]; then
    WIFI_CONNECT="${WIFI_CONNECT}:5555"
  fi

  echo "Trying adb connect ${WIFI_CONNECT}"
  adb connect "${WIFI_CONNECT}" || true

  if [[ -z "${DEVICE_ID}" ]]; then
    DEVICE_ID="${WIFI_CONNECT}"
  fi

  WIFI_DEVICE=true
fi

if [[ "${WIFI_DEVICE}" == "true" && -z "${DEVICE_ID}" ]]; then
  if command -v adb >/dev/null 2>&1; then
    WIFI_ADB_DEVICE="$(adb devices | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+[[:space:]]+device$/ {print $1; exit}')"
    if [[ -n "${WIFI_ADB_DEVICE}" ]]; then
      DEVICE_ID="${WIFI_ADB_DEVICE}"
      echo "Using Wi-Fi device from adb: ${DEVICE_ID}"
    else
      echo "Warning: no adb Wi-Fi device found. If needed, run with --wifi-connect <phone_ip[:port]>." >&2
    fi
  else
    echo "Warning: adb not found; cannot auto-select Wi-Fi Android device." >&2
  fi
fi

# Wi-Fi mode: detect the best LAN IPv4 (Linux + Windows compatible)
HOST_IP="$(detect_lan_ip)"

if [[ -z "${HOST_IP}" ]]; then
  echo "Error: could not auto-detect LAN IP. Run manually with:" >&2
  echo "  flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:${PORT}" >&2
  exit 1
fi

API_BASE_URL="http://${HOST_IP}:${PORT}"
echo "Using API_BASE_URL=${API_BASE_URL}"
echo "Tip: for Wi-Fi mode your backend must listen on 0.0.0.0:${PORT} (not only localhost)."

FLUTTER_CMD=(flutter run --dart-define="API_BASE_URL=${API_BASE_URL}")
if [[ -n "${DEVICE_ID}" ]]; then
  FLUTTER_CMD+=(-d "${DEVICE_ID}")
fi
FLUTTER_CMD+=("$@")

"${FLUTTER_CMD[@]}"
