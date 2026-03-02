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
```

This will try `adb reverse tcp:3000 tcp:3000` and run with `REAL_DEVICE=true`.

2. **Wi-Fi mode (same network)**

```bash
cd flutter_application_1
./scripts/run_phone.sh --port 3000
```

This auto-detects your LAN IP and runs Flutter with `API_BASE_URL=http://<LAN_IP>:3000`.

# 7jemty
