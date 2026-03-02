# hjamty

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backend API host

The app supports overriding the backend host with a Dart define:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

- Android emulator default: `http://10.0.2.2:3000`
- Android real device mode (`REAL_DEVICE=true`): `http://127.0.0.1:3000` (with `adb reverse`)
- Physical phone (Wi-Fi): use your computer LAN IP (`192.168.x.x`) and ensure backend listens on `0.0.0.0:3000`.

### Optimized options for real devices

1. **USB debugging mode (recommended for Android real device)**

```bash
cd flutter_application_1
./scripts/run_phone.sh --real-device --port 3000
# or
./scripts/run_phone.sh --usb-only --port 3000
```

This runs USB only (`adb reverse`) with `REAL_DEVICE=true`. If no USB device is detected, the script exits with an error (no Wi‑Fi fallback).

2. **Wi-Fi mode (same network)**

```bash
cd flutter_application_1
./scripts/run_phone.sh --port 3000
```

This auto-detects your LAN IP and runs Flutter with `API_BASE_URL=http://<LAN_IP>:3000`.

3. **Run on a phone over Wi-Fi (without keeping USB plugged)**

```bash
cd flutter_application_1
./scripts/run_phone.sh --wifi-connect 192.168.1.35:38899 --port 3000
```

- `--wifi-connect` runs `adb connect` first, then targets that phone directly.
- If your port is omitted, it defaults to `5555` (example: `--wifi-connect 192.168.1.35`).
- If already connected from Android Wireless Debugging, you can still use:

```bash
./scripts/run_phone.sh --wifi-device --port 3000
```

Or force an exact target:

```bash
./scripts/run_phone.sh --device-id 192.168.1.35:38899 --port 3000
```

### Troubleshooting (USB mode)

If you see errors like `Connection refused` to `http://127.0.0.1:3000`:

1. Start backend on your computer first (port `3000`).
2. Check USB device is visible: `adb devices`.
3. Check reverse is active: `adb reverse --list` (should include `tcp:3000 tcp:3000`).
4. Re-run: `./scripts/run_phone.sh --usb-only --port 3000`.

If your phone is **not** connected by USB reverse, do **not** use `REAL_DEVICE=true` / `--real-device`; use Wi-Fi mode so the app targets your PC LAN IP instead:

```bash
./scripts/run_phone.sh --port 3000
```


# 7jemty
