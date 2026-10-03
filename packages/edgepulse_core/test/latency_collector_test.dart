import 'package:edgepulse_core/edgepulse_core.dart';
import 'package:test/test.dart';

void main() {
  group('LatencyCollector', () {
    late LatencyCollector collector;

    setUp(() {
      collector = LatencyCollector();
    });

    test('initial state', () {
      expect(collector.isRunning, isFalse);
      expect(collector.elapsed, equals(Duration.zero));
    });

    test('start begins timing', () async {
      collector.start();
      expect(collector.isRunning, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      collector.stop();

      expect(collector.isRunning, isFalse);
      expect(collector.elapsed.inMilliseconds, greaterThanOrEqualTo(40));
    });

    test('reset clears timer', () async {
      collector.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      collector.reset();

      expect(collector.isRunning, isFalse);
      expect(collector.elapsed, equals(Duration.zero));
    });

    test('restarting mid-flight resets the timer', () async {
      collector.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      collector.start(); // Should reset & restart
      await Future<void>.delayed(const Duration(milliseconds: 20));
      collector.stop();

      expect(collector.elapsed.inMilliseconds, lessThan(45));
    });
  });
}
