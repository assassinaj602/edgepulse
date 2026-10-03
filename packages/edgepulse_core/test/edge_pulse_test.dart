import 'package:edgepulse_core/edgepulse_core.dart';
import 'package:test/test.dart';

void main() {
  group('EdgePulse Facade', () {
    late MockMetricCollector mockCollector;
    late EdgePulse pulse;

    setUp(() {
      mockCollector = MockMetricCollector();
      pulse = EdgePulse(collector: mockCollector);
    });

    test('EdgePulse.mock factory creates instance', () {
      final mockPulse = EdgePulse.mock();
      expect(mockPulse.collector, isA<MockMetricCollector>());
      expect(mockPulse.isInitialized, isFalse);
    });

    test('lifecycle: isInitialized changes on initialize and dispose',
        () async {
      expect(pulse.isInitialized, isFalse);
      await pulse.initialize();
      expect(pulse.isInitialized, isTrue);

      await pulse.dispose();
      expect(pulse.isInitialized, isFalse);
      expect(mockCollector.disposeCallCount, equals(1));
    });

    test('calling initialize twice is idempotent', () async {
      await pulse.initialize();
      await pulse.initialize();
      expect(pulse.isInitialized, isTrue);
      expect(mockCollector.initializeCallCount, equals(1));
    });

    test('trace methods throw StateError if called before initialize', () {
      expect(
        () => pulse.trace(
          modelId: 'test',
          modelFormat: 'gguf',
          run: () async {},
        ),
        throwsStateError,
      );

      expect(
        () => pulse.traceMany(
          modelId: 'test',
          modelFormat: 'gguf',
          run: () async {},
        ),
        throwsStateError,
      );

      expect(
        () => pulse.summary(
          modelId: 'test',
          modelFormat: 'gguf',
          run: () async {},
        ),
        throwsStateError,
      );
    });

    test('trace returns an InferenceTrace after initialize', () async {
      await pulse.initialize();

      final trace = await pulse.trace(
        modelId: 'gemma-2b-q4',
        modelFormat: 'gguf',
        deviceModel: 'Pixel 8',
        osVersion: 'Android 14',
        outputConfidence: 0.92,
        metadata: const {'user': 'test'},
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
      );

      expect(trace.modelId, equals('gemma-2b-q4'));
      expect(trace.modelFormat, equals('gguf'));
      expect(trace.deviceModel, equals('Pixel 8'));
      expect(trace.osVersion, equals('Android 14'));
      expect(trace.outputConfidence, equals(0.92));
      expect(trace.metadata['user'], equals('test'));
    });

    test('traceMany runs N traces after initialize', () async {
      await pulse.initialize();

      final traces = await pulse.traceMany(
        modelId: 'mobilenet',
        modelFormat: 'tflite',
        runs: 3,
        run: () async {},
      );

      expect(traces.length, equals(3));
    });

    test('summary returns aggregated summary after initialize', () async {
      await pulse.initialize();

      final sum = await pulse.summary(
        modelId: 'resnet',
        modelFormat: 'onnx',
        run: () async {},
      );

      expect(sum.modelId, equals('resnet'));
      expect(sum.traces, isNotEmpty);
    });

    test('convenience export methods', () async {
      await pulse.initialize();
      final trace = await pulse.trace(
        modelId: 'model_a',
        modelFormat: 'tflite',
        run: () async {},
      );

      final jsonStr = pulse.exportJson([trace]);
      final mdStr = pulse.exportMarkdown([trace]);
      final csvStr = pulse.exportCsv([trace]);

      expect(jsonStr, startsWith('{'));
      expect(mdStr, contains('# EdgePulse Inference Trace Report'));
      expect(csvStr, contains('trace_id,model_id'));
    });
  });
}
