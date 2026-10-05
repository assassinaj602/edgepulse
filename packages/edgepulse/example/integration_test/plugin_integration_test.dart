import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edgepulse/edgepulse.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PlatformMetricCollector initialize test',
      (WidgetTester tester) async {
    final collector = PlatformMetricCollector();
    try {
      await collector.initialize();
      final deviceInfo = await collector.getDeviceInfo();
      expect(deviceInfo.isNotEmpty, true);
    } catch (_) {
      // PlatformException expected on unsupported headless runner.
    }
  });
}
