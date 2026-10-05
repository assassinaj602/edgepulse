# iOS Battery Measurement

## The Difference From Android

Android exposes raw current draw via `BatteryManager.BATTERY_PROPERTY_CURRENT_NOW`.
EdgePulse reads this and returns milliamps (mA) in `InferenceTrace.batteryDrainMah`.

iOS does **not** expose raw current draw to third-party apps. Apple restricts
this for privacy and hardware protection reasons.

EdgePulse on iOS returns `UIDevice.current.batteryLevel` instead — a fraction
from 0.0 (empty) to 1.0 (full). This is stored in `batteryDrainMah` but
represents a different quantity.

## How to Handle This in Your Code

```dart
final deviceInfo = await (pulse.collector as PlatformMetricCollector)
    .getDeviceInfo();

final isIOS = deviceInfo['sdk_int'] == 'ios';

if (isIOS) {
  print('Battery level: ${(trace.batteryDrainMah! * 100).toStringAsFixed(1)}%');
} else {
  print('Battery draw: ${trace.batteryDrainMah?.toStringAsFixed(2)} mA');
}
```

## In Research Data

When analysing the CSV output, filter by platform before comparing
battery columns. Android rows have milliamps; iOS rows have level fraction.
The `research/experiment/analyse.py` script handles this automatically.

## Minimum iOS Version

Battery monitoring (`UIDevice.isBatteryMonitoringEnabled`) requires iOS 3.0+.
Thermal state (`ProcessInfo.thermalState`) requires iOS 11.0+.
EdgePulse sets minimum iOS to 12.0 in the podspec.
