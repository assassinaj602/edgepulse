import 'package:flutter/services.dart';
import 'package:edgepulse_core/edgepulse_core.dart';

/// A [MetricCollector] that reads real device metrics from the native
/// platform (Android or iOS) via a Flutter MethodChannel.
///
/// Use this inside a Flutter app. For CLI or test environments,
/// use [MockMetricCollector] from edgepulse_core instead.
class PlatformMetricCollector implements MetricCollector {
  static const _channel = MethodChannel('io.github.edgepulse/metrics');
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
      _isInitialized = true;
    } on PlatformException catch (e) {
      throw StateError(
        'EdgePulse native plugin not available. '
        'Make sure you are running on a real device or emulator. '
        'Error: ${e.message}',
      );
    }
  }

  @override
  Future<MemorySnapshot> captureMemory() async {
    final result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('captureMemory');
    if (result == null) {
      return MemorySnapshot(
        rssMb: 0,
        heapMb: 0,
        nativeMb: 0,
        timestamp: DateTime.now(),
      );
    }
    final rssMb = (result['rss_mb'] as num?)?.toDouble() ?? 0.0;
    final heapMb = (result['heap_mb'] as num?)?.toDouble() ?? (rssMb * 0.4);
    final nativeMb = (result['native_mb'] as num?)?.toDouble() ?? (rssMb * 0.6);

    return MemorySnapshot(
      rssMb: rssMb,
      heapMb: heapMb,
      nativeMb: nativeMb,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<ThermalState> captureThermalState() async {
    final result =
        await _channel.invokeMethod<String>('captureThermal');
    return ThermalState.fromString(result ?? 'unknown');
  }

  @override
  Future<double?> captureBatteryDrainMah() async {
    return await _channel.invokeMethod<double>('captureBattery');
  }

  @override
  Future<double?> captureCpuUsagePercent() async {
    return await _channel.invokeMethod<double>('captureCpu');
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }

  /// Returns device model and OS version from the native layer.
  /// Use this to populate [InferenceTrace.deviceModel] and
  /// [InferenceTrace.osVersion].
  Future<Map<String, String>> getDeviceInfo() async {
    final result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
    if (result == null) return {};
    return result.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
  }
}
