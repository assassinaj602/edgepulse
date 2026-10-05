import Flutter
import UIKit
import Darwin

/// EdgePulse native metric collection plugin for iOS.
///
/// Implements the same MethodChannel interface as the Android plugin so
/// PlatformMetricCollector works identically on both platforms.
///
/// Channel: io.github.edgepulse/metrics
/// Methods: captureMemory, captureThermal, captureBattery,
///          captureCpu, getDeviceInfo
public class EdgePulsePlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "io.github.edgepulse/metrics",
      binaryMessenger: registrar.messenger()
    )
    let instance = EdgePulsePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "captureMemory":
      captureMemory(result: result)
    case "captureThermal":
      captureThermal(result: result)
    case "captureBattery":
      captureBattery(result: result)
    case "captureCpu":
      captureCpu(result: result)
    case "getDeviceInfo":
      getDeviceInfo(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Memory — mach_task_basic_info
  //
  // resident_size is the most accurate per-process memory figure
  // available to third-party apps on iOS. Virtual size is also
  // returned for completeness.
  // ──────────────────────────────────────────────────────────────
  private func captureMemory(result: FlutterResult) {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(
      MemoryLayout<mach_task_basic_info>.size /
      MemoryLayout<integer_t>.size
    )

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(
        to: integer_t.self,
        capacity: Int(count)
      ) {
        task_info(
          mach_task_self_,
          task_flavor_t(MACH_TASK_BASIC_INFO),
          $0,
          &count
        )
      }
    }

    guard kerr == KERN_SUCCESS else {
      result(FlutterError(
        code: "MEMORY_ERROR",
        message: "task_info returned \(kerr)",
        details: nil
      ))
      return
    }

    let rssMb     = Double(info.resident_size) / 1_048_576.0
    let virtualMb = Double(info.virtual_size)  / 1_048_576.0

    result([
      "rss_mb":     rssMb,
      "virtual_mb": virtualMb,
    ] as [String: Any])
  }

  // ──────────────────────────────────────────────────────────────
  // Thermal — NSProcessInfo.thermalState
  //
  // Available from iOS 11. Returns the same string values as the
  // Android plugin so ThermalState.fromString() works identically.
  // ──────────────────────────────────────────────────────────────
  private func captureThermal(result: FlutterResult) {
    if #available(iOS 11.0, *) {
      let state: String
      switch ProcessInfo.processInfo.thermalState {
      case .nominal:  state = "nominal"
      case .fair:     state = "fair"
      case .serious:  state = "serious"
      case .critical: state = "critical"
      @unknown default: state = "unknown"
      }
      result(state)
    } else {
      // iOS < 11 — thermal state not available
      result("unknown")
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Battery — UIDevice.batteryLevel
  //
  // iOS does NOT expose raw current draw (microamps) to third-party
  // apps. We return batteryLevel (0.0–1.0).
  //
  // This differs from Android (which returns milliamps). The
  // difference is documented in docs/ios-battery-note.md and
  // reflected in trace metadata: battery_unit = "level_fraction".
  //
  // Returns null on simulator (batteryLevel == -1.0).
  // ──────────────────────────────────────────────────────────────
  private func captureBattery(result: FlutterResult) {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    UIDevice.current.isBatteryMonitoringEnabled = false

    if level < 0 {
      // Unavailable (simulator or monitoring not supported)
      result(nil)
    } else {
      result(Double(level))
    }
  }

  // ──────────────────────────────────────────────────────────────
  // CPU — host_statistics64 HOST_CPU_LOAD_INFO
  //
  // Returns overall system CPU utilisation as a percentage (0–100).
  // This is a snapshot of all ticks since boot — for delta-based
  // measurement call twice and compute the difference.
  // ──────────────────────────────────────────────────────────────
  private func captureCpu(result: FlutterResult) {
    var cpuInfo = host_cpu_load_info()
    var count = mach_msg_type_number_t(
      MemoryLayout<host_cpu_load_info_data_t>.size /
      MemoryLayout<integer_t>.size
    )

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &cpuInfo) {
      $0.withMemoryRebound(
        to: integer_t.self,
        capacity: Int(count)
      ) {
        host_statistics(
          mach_host_self(),
          HOST_CPU_LOAD_INFO,
          $0,
          &count
        )
      }
    }

    guard kerr == KERN_SUCCESS else {
      result(nil)
      return
    }

    let user   = Double(cpuInfo.cpu_ticks.0)
    let system = Double(cpuInfo.cpu_ticks.1)
    let idle   = Double(cpuInfo.cpu_ticks.2)
    let nice   = Double(cpuInfo.cpu_ticks.3)

    let total  = user + system + idle + nice
    let used   = user + system + nice

    let cpuPercent = total > 0 ? (used / total) * 100.0 : 0.0
    result(cpuPercent)
  }

  // ──────────────────────────────────────────────────────────────
  // Device info — UIDevice
  //
  // Used by PlatformMetricCollector.initialize() to verify the
  // plugin is loaded. Also populates InferenceTrace device fields.
  // ──────────────────────────────────────────────────────────────
  private func getDeviceInfo(result: FlutterResult) {
    result([
      "model":        UIDevice.current.model,
      "manufacturer": "Apple",
      "os_version":   UIDevice.current.systemVersion,
      "sdk_int":      "ios",
      "brand":        "Apple",
    ] as [String: Any])
  }
}
