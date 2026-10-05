import 'package:flutter_test/flutter_test.dart';
import 'package:edgepulse_example/main.dart';

void main() {
  testWidgets('Renders EdgePulse Example App', (WidgetTester tester) async {
    await tester.pumpWidget(const EdgePulseExampleApp());
    expect(find.text('EdgePulse Example'), findsWidgets);
    expect(find.text('Run Trace (5 runs)'), findsOneWidget);
  });
}
