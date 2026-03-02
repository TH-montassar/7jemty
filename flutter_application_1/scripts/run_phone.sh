#!/usr/bin/env bash
set -euo pipefail

PORT=3000
REAL_DEVICE=false
WIFI_DEVICE=false
DEVICE_ID=""

show_help() {
  cat <<'EOF'
Usage: ./scripts/run_phone.sh [options] [-- flutter_run_args]

Options:
  --real-device      Run with REAL_DEVICE=true and try adb reverse.
  --wifi-device      Prefer an Android device connected with wireless debugging (adb over Wi-Fi).
  --device-id <id>   Explicit Flutter device id to run on.
  --port <port>      Backend API port (default: 3000).
  --help             Show this message.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --real-device)
      REAL_DEVICE=true
      shift
      ;;
    --wifi-device)
      WIFI_DEVICE=true
      shift
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
  if command -v adb >/dev/null 2>&1; then
    echo "Setting adb reverse tcp:${PORT} -> tcp:${PORT}"
    adb reverse "tcp:${PORT}" "tcp:${PORT}" || true
  else
    echo "Warning: adb not found; install Android platform-tools for auto reverse." >&2
  fi

  echo "Running in REAL_DEVICE mode with localhost via adb reverse"
  flutter run --dart-define="REAL_DEVICE=true" "$@"
  exit 0
fi

if [[ "${WIFI_DEVICE}" == "true" && -z "${DEVICE_ID}" ]]; then
  if command -v adb >/dev/null 2>&1; then
    WIFI_ADB_DEVICE="$(adb devices | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+[[:space:]]+device$/ {print $1; exit}')"
    if [[ -n "${WIFI_ADB_DEVICE}" ]]; then
      DEVICE_ID="${WIFI_ADB_DEVICE}"
      echo "Using Wi-Fi device from adb: ${DEVICE_ID}"
    else
      echo "Warning: no adb Wi-Fi device found. Falling back to default Flutter device." >&2
    fi
  else
    echo "Warning: adb not found; cannot auto-select Wi-Fi Android device." >&2
  fi
fi

# Wi-Fi mode: auto-detect primary LAN IPv4 and pass API_BASE_URL.
HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [[ -z "${HOST_IP}" ]]; then
  HOST_IP="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1; i<=NF; i++) if ($i=="src") {print $(i+1); exit}}')"
fi

if [[ -z "${HOST_IP}" ]]; then
  echo "Error: could not auto-detect LAN IP. Run manually with:" >&2
  echo "  flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:${PORT}" >&2
  exit 1
fi

API_BASE_URL="http://${HOST_IP}:${PORT}"
echo "Using API_BASE_URL=${API_BASE_URL}"

FLUTTER_CMD=(flutter run --dart-define="API_BASE_URL=${API_BASE_URL}")
if [[ -n "${DEVICE_ID}" ]]; then
  FLUTTER_CMD+=( -d "${DEVICE_ID}" )
fi
FLUTTER_CMD+=("$@")

"${FLUTTER_CMD[@]}"
