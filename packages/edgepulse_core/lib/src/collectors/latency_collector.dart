/// A small Stopwatch wrapper for measuring inference duration.
///
/// Used internally by [PulseRunner] but exposed publicly so custom
/// runners and integrations can reuse the same timing semantics.
class LatencyCollector {
  final Stopwatch _stopwatch = Stopwatch();

  /// Starts the timer. Safe to call multiple times — restarts if already running.
  void start() {
    _stopwatch
      ..reset()
      ..start();
  }

  /// Stops the timer.
  void stop() {
    _stopwatch.stop();
  }

  /// Resets the timer to zero.
  void reset() {
    _stopwatch
      ..stop()
      ..reset();
  }

  /// Elapsed duration since [start] was called.
  Duration get elapsed => _stopwatch.elapsed;

  /// Whether the timer is currently running.
  bool get isRunning => _stopwatch.isRunning;
}
