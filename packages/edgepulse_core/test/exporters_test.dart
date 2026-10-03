import 'dart:convert';

import 'package:edgepulse_core/edgepulse_core.dart';
import 'package:test/test.dart';

void main() {
  group('Exporters', () {
    final now = DateTime.utc(2026, 10, 3, 10, 0, 0);

    final sampleTrace1 = InferenceTrace(
      traceId: 'ep_test01',
      modelId: 'gemma-2b',
      modelFormat: 'gguf',
      deviceModel: 'Pixel 8',
      osVersion: 'Android 14',
      timestamp: now,
      totalDuration: const Duration(milliseconds: 847),
      memoryStart: MemorySnapshot(
        rssMb: 312.4,
        heapMb: 100.0,
        nativeMb: 212.4,
        timestamp: now,
      ),
      memoryPeak: MemorySnapshot(
        rssMb: 489.1,
        heapMb: 150.0,
        nativeMb: 339.1,
        timestamp: now,
      ),
      memoryEnd: MemorySnapshot(
        rssMb: 318.2,
        heapMb: 105.0,
        nativeMb: 213.2,
        timestamp: now,
      ),
      thermalState: ThermalState.nominal,
      batteryDrainMah: 0.023,
      cpuUsagePercent: 87.3,
      layerTimings: const [
        LayerTiming(
          layerName: 'embedding',
          layerType: 'embedding',
          duration: Duration(milliseconds: 12),
        ),
        LayerTiming(
          layerName: 'attention_0',
          layerType: 'attention',
          duration: Duration(milliseconds: 94),
        ),
      ],
      outputConfidence: 0.91,
    );

    final sampleTrace2 = InferenceTrace(
      traceId: 'ep_test02',
      modelId: 'mobilenet_v3',
      modelFormat: 'tflite',
      timestamp: now,
      totalDuration: const Duration(milliseconds: 45),
      memoryStart: MemorySnapshot(
        rssMb: 120.0,
        heapMb: 40.0,
        nativeMb: 80.0,
        timestamp: now,
      ),
      memoryPeak: MemorySnapshot(
        rssMb: 180.0,
        heapMb: 60.0,
        nativeMb: 120.0,
        timestamp: now,
      ),
      memoryEnd: MemorySnapshot(
        rssMb: 125.0,
        heapMb: 42.0,
        nativeMb: 83.0,
        timestamp: now,
      ),
      thermalState: ThermalState.fair,
    );

    group('JsonExporter', () {
      const exporter = JsonExporter();

      test('fileExtension is json', () {
        expect(exporter.fileExtension, equals('json'));
      });

      test('export produces valid parseable JSON map', () {
        final jsonString = exporter.export([sampleTrace1, sampleTrace2]);
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(parsed['total_traces'], equals(2));
        expect(parsed['traces'], isA<List>());
        final tracesList = parsed['traces'] as List;
        expect(tracesList.length, equals(2));

        final restored = InferenceTrace.fromJson(
          tracesList[0] as Map<String, dynamic>,
        );
        expect(restored.traceId, equals('ep_test01'));
        expect(restored.modelId, equals('gemma-2b'));
      });

      test('exportSingle exports direct trace object', () {
        final jsonString = exporter.exportSingle(sampleTrace1);
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(parsed['trace_id'], equals('ep_test01'));
        expect(parsed['model_id'], equals('gemma-2b'));
      });
    });

    group('MarkdownExporter', () {
      const exporter = MarkdownExporter();

      test('fileExtension is md', () {
        expect(exporter.fileExtension, equals('md'));
      });

      test('export empty list', () {
        final result = exporter.export([]);
        expect(result, contains('No traces available.'));
      });

      test('export produces markdown tables and sections', () {
        final result = exporter.export([sampleTrace1]);

        expect(result, contains('# EdgePulse Inference Trace Report'));
        expect(result, contains('## Run 1 (ep_test01)'));
        expect(result, contains('**Model:** gemma-2b (gguf)'));
        expect(result, contains('**Device:** Pixel 8 (Android 14)'));
        expect(result, contains('| Metric | Value |'));
        expect(result, contains('| Duration | 847ms |'));
        expect(result, contains('| Memory Start | 312.4 MB |'));
        expect(result, contains('| Memory Peak | 489.1 MB |'));
        expect(result, contains('| Thermal State | nominal |'));
        expect(result, contains('## Layer Timings'));
        expect(result, contains('| embedding | embedding | 12ms |'));
        expect(result, contains('<details>'));
        expect(result, contains('<summary>Raw JSON</summary>'));
      });
    });

    group('CsvExporter', () {
      const exporter = CsvExporter();

      test('fileExtension is csv', () {
        expect(exporter.fileExtension, equals('csv'));
      });

      test('export produces header and data lines', () {
        final csvString = exporter.export([sampleTrace1, sampleTrace2]);
        final lines = csvString.trim().split('\n');

        expect(lines.length, equals(3));
        expect(lines[0], equals(InferenceTrace.csvHeader));

        expect(lines[1], contains('ep_test01'));
        expect(lines[1], contains('gemma-2b'));
        expect(lines[1], contains('gguf'));
        expect(lines[1], contains('847'));

        expect(lines[2], contains('ep_test02'));
        expect(lines[2], contains('mobilenet_v3'));
        expect(lines[2], contains('tflite'));
        expect(lines[2], contains('45'));
      });
    });
  });
}
