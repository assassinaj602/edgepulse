package io.github.edgepulse

import android.app.ActivityManager
import android.content.Context
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** EdgePulsePlugin — native metric collection for EdgePulse. */
class EdgePulsePlugin : FlutterPlugin, MethodCallHandler {

  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private lateinit var activityManager: ActivityManager
  private lateinit var batteryManager: BatteryManager
  private lateinit var powerManager: PowerManager

  override fun onAttachedToEngine(
    binding: FlutterPlugin.FlutterPluginBinding
  ) {
    context = binding.applicationContext
    channel = MethodChannel(
      binding.binaryMessenger,
      "io.github.edgepulse/metrics"
    )
    channel.setMethodCallHandler(this)

    activityManager =
      context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    batteryManager =
      context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    powerManager =
      context.getSystemService(Context.POWER_SERVICE) as PowerManager
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "captureMemory"  -> captureMemory(result)
      "captureThermal" -> captureThermal(result)
      "captureBattery" -> captureBattery(result)
      "captureCpu"     -> captureCpu(result)
      "getDeviceInfo"  -> getDeviceInfo(result)
      else             -> result.notImplemented()
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Memory
  // Returns PSS (Proportional Set Size) — the most accurate per-
  // process memory figure on Android, accounting for shared pages.
  // ──────────────────────────────────────────────────────────────
  private fun captureMemory(result: Result) {
    val memInfo = ActivityManager.MemoryInfo()
    activityManager.getMemoryInfo(memInfo)

    // PSS in KB → MB
    val pssMb = Debug.getPss() / 1024.0

    result.success(
      mapOf(
        "rss_mb"       to pssMb,
        "available_mb" to (memInfo.availMem  / 1024.0 / 1024.0),
        "total_mb"     to (memInfo.totalMem  / 1024.0 / 1024.0),
        "low_memory"   to memInfo.lowMemory,
      )
    )
  }

  // ──────────────────────────────────────────────────────────────
  // Thermal state
  // PowerManager.getCurrentThermalStatus() requires API 29 (Android 10).
  // Returns "unknown" on older devices.
  // ──────────────────────────────────────────────────────────────
  private fun captureThermal(result: Result) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val state = when (powerManager.currentThermalStatus) {
        PowerManager.THERMAL_STATUS_NONE      -> "nominal"
        PowerManager.THERMAL_STATUS_LIGHT     -> "fair"
        PowerManager.THERMAL_STATUS_MODERATE  -> "fair"
        PowerManager.THERMAL_STATUS_SEVERE    -> "serious"
        PowerManager.THERMAL_STATUS_CRITICAL  -> "critical"
        PowerManager.THERMAL_STATUS_EMERGENCY -> "critical"
        PowerManager.THERMAL_STATUS_SHUTDOWN  -> "critical"
        else                                  -> "unknown"
      }
      result.success(state)
    } else {
      // API < 29 — thermal status not available
      result.success("unknown")
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Battery
  // BATTERY_PROPERTY_CURRENT_NOW returns microamps (μA).
  // We convert to milliamps (mA) and return the absolute value
  // (sign indicates charging direction, not relevant here).
  // Returns null if the hardware does not support this property.
  // ──────────────────────────────────────────────────────────────
  private fun captureBattery(result: Result) {
    try {
      val microAmps = batteryManager.getLongProperty(
        BatteryManager.BATTERY_PROPERTY_CURRENT_NOW
      )
      if (microAmps == Long.MIN_VALUE) {
        // Property not supported on this device
        result.success(null)
      } else {
        val milliAmps = Math.abs(microAmps) / 1000.0
        result.success(milliAmps)
      }
    } catch (e: Exception) {
      result.success(null)
    }
  }

  // ──────────────────────────────────────────────────────────────
  // CPU utilisation
  // Reads /proc/stat for overall system CPU usage.
  // This is a single snapshot — for delta-based measurement,
  // call twice and compute the difference.
  // ──────────────────────────────────────────────────────────────
  private fun captureCpu(result: Result) {
    try {
      val statFile  = java.io.File("/proc/stat")
      val firstLine = statFile.readLines().firstOrNull()
        ?: return result.success(null)

      // Format: "cpu  user nice system idle iowait irq softirq ..."
      val parts = firstLine.trim().split("\\s+".toRegex()).drop(1)
      if (parts.size < 4) return result.success(null)

      val user   = parts[0].toLong()
      val nice   = parts[1].toLong()
      val system = parts[2].toLong()
      val idle   = parts[3].toLong()
      val total  = user + nice + system + idle
      val used   = total - idle

      val cpuPercent = if (total > 0) (used.toDouble() / total) * 100.0
                       else 0.0
      result.success(cpuPercent)
    } catch (e: Exception) {
      result.success(null)
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Device info
  // Used by PlatformMetricCollector.initialize() to verify the
  // plugin is loaded, and to populate InferenceTrace device fields.
  // ──────────────────────────────────────────────────────────────
  private fun getDeviceInfo(result: Result) {
    result.success(
      mapOf(
        "model"        to Build.MODEL,
        "manufacturer" to Build.MANUFACTURER,
        "os_version"   to Build.VERSION.RELEASE,
        "sdk_int"      to Build.VERSION.SDK_INT.toString(),
        "brand"        to Build.BRAND,
      )
    )
  }

  override fun onDetachedFromEngine(
    binding: FlutterPlugin.FlutterPluginBinding
  ) {
    channel.setMethodCallHandler(null)
  }
}
