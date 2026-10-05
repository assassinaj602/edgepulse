/// Represents the operating thermal condition of an edge device.
enum ThermalState {
  /// Normal thermal operation, no throttling.
  nominal,

  /// Elevated temperature, minimal system throttling may occur.
  fair,

  /// High temperature, significant CPU/GPU throttling in effect.
  serious,

  /// Critical temperature, severe thermal throttling or shutdown risk.
  critical,

  /// Thermal state unavailable or unsupported on this platform.
  unknown;

  /// Whether the thermal state is degraded (serious or critical).
  bool get isDegraded =>
      this == ThermalState.serious || this == ThermalState.critical;

  /// Parses a string representation into a [ThermalState].
  static ThermalState fromString(String value) {
    return ThermalState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ThermalState.unknown,
    );
  }
}
