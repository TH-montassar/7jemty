#!/usr/bin/env bash
set -euo pipefail

PORT=3000
REAL_DEVICE=false
WIFI_DEVICE=false
DEVICE_ID=""
WIFI_CONNECT=""

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
  USB_ADB_DEVICE=""

  if command -v adb >/dev/null 2>&1; then
    USB_ADB_DEVICE="$(adb devices | awk '/^[^[:space:]]+[[:space:]]+device$/ && $1 !~ /:/ {print $1; exit}')"
  else
    echo "Warning: adb not found; install Android platform-tools for USB reverse." >&2
  fi

  if [[ -n "${USB_ADB_DEVICE}" ]]; then
    if [[ -z "${DEVICE_ID}" ]]; then
      DEVICE_ID="${USB_ADB_DEVICE}"
    fi

    echo "USB device detected (${DEVICE_ID}). Setting adb reverse tcp:${PORT} -> tcp:${PORT}"
    adb reverse "tcp:${PORT}" "tcp:${PORT}" || true

    FLUTTER_CMD=(flutter run --dart-define="REAL_DEVICE=true")
    if [[ -n "${DEVICE_ID}" ]]; then
      FLUTTER_CMD+=(-d "${DEVICE_ID}")
    fi
    FLUTTER_CMD+=("$@")

    echo "Running in REAL_DEVICE mode with localhost via adb reverse"
    "${FLUTTER_CMD[@]}"
    exit 0
  fi

  echo "Error: no USB adb device found. Connect your phone with USB debugging enabled, then retry." >&2
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

# Wi-Fi mode: detect the best LAN IPv4 and pass API_BASE_URL.
# Prefer IP from default route (usually the same subnet as phone), then fallback.
HOST_IP="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1; i<=NF; i++) if ($i=="src") {print $(i+1); exit}}')"
if [[ -z "${HOST_IP}" ]]; then
  HOST_IP="$(hostname -I 2>/dev/null | tr ' ' '\n' | awk '/^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ {print; exit}')"
fi
if [[ -z "${HOST_IP}" ]]; then
  HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

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
