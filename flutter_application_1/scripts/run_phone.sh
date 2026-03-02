#!/usr/bin/env bash
set -euo pipefail

PORT=3000
REAL_DEVICE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --real-device)
      REAL_DEVICE=true
      shift
      ;;
    --port)
      PORT="${2:-3000}"
      shift 2
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
flutter run --dart-define="API_BASE_URL=${API_BASE_URL}" "$@"
