# Changelog

## 0.2.0 — 2026-10-06

### Added

- `PlatformMetricCollector` — reads real device metrics via Flutter MethodChannel
- Android Kotlin native plugin (`EdgePulsePlugin.kt`):
  - `captureMemory`: Debug.getPss() for accurate process memory in MB
  - `captureThermal`: PowerManager.currentThermalStatus (API 29+)
  - `captureBattery`: BatteryManager.CURRENT_NOW in milliamps
  - `captureCpu`: /proc/stat utilisation ratio
  - `getDeviceInfo`: Build.MODEL, MANUFACTURER, VERSION.RELEASE, SDK_INT
- iOS Swift native plugin (`EdgePulsePlugin.swift`):
  - `captureMemory`: mach_task_basic_info resident_size
  - `captureThermal`: ProcessInfo.thermalState (iOS 11+)
  - `captureBattery`: UIDevice.batteryLevel (level fraction 0.0–1.0)
  - `captureCpu`: host_statistics HOST_CPU_LOAD_INFO
  - `getDeviceInfo`: UIDevice model and systemVersion
- `edgepulse.dart` re-exports all of `edgepulse_core` + `PlatformMetricCollector`
- Example Flutter app demonstrating 5-run trace on a real device

### Notes

- iOS battery returns level fraction (0.0–1.0), not milliamps.
  See docs/ios-battery-note.md for handling both platforms.
- Minimum Android API: 21. Thermal state requires API 29.
- Minimum iOS: 12.0. Swift 5.0.
