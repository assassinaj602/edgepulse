import 'dart:convert';
import 'dart:io';

import 'package:edgepulse_cli/src/commands/compare_command.dart';
import 'package:edgepulse_core/edgepulse_core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('CompareCommand', () {
    late Directory tempDir;
    late CompareCommand command;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('edgepulse_compare_test_');
      command = CompareCommand();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<String> createSampleTraceFile(
      String filename, {
      required int durationMs,
      required double rssMb,
    }) async {
      final trace = InferenceTrace(
        traceId: 'ep_test',
        modelId: 'test_model',
        modelFormat: 'tflite',
        timestamp: DateTime.now(),
        totalDuration: Duration(milliseconds: durationMs),
        memoryStart: MemorySnapshot(
          rssMb: rssMb,
          heapMb: 50.0,
          nativeMb: 50.0,
          timestamp: DateTime.now(),
        ),
        memoryPeak: MemorySnapshot(
          rssMb: rssMb + 50.0,
          heapMb: 60.0,
          nativeMb: 70.0,
          timestamp: DateTime.now(),
        ),
        memoryEnd: MemorySnapshot(
          rssMb: rssMb + 10.0,
          heapMb: 52.0,
          nativeMb: 52.0,
          timestamp: DateTime.now(),
        ),
        thermalState: ThermalState.nominal,
      );

      final filePath = path.join(tempDir.path, filename);
      final jsonStr = const JsonExporter().export([trace]);
      await File(filePath).writeAsString(jsonStr);
      return filePath;
    }

    test('prints help when --help is passed', () async {
      final exitCode = await command.run(['--help']);
      expect(exitCode, equals(0));
    });

    test('returns exit code 1 if args are missing', () async {
      final exitCode = await command.run([]);
      expect(exitCode, equals(1));
    });

    test('returns exit code 1 if file does not exist', () async {
      final exitCode = await command.run(['non_existent.json', 'also_missing.json']);
      expect(exitCode, equals(1));
    });

    test('returns 0 when baseline is better or equal', () async {
      final file1 = await createSampleTraceFile('base.json', durationMs: 100, rssMb: 200.0);
      final file2 = await createSampleTraceFile('fast.json', durationMs: 80, rssMb: 180.0);

      final exitCode = await command.run([file1, file2]);
      expect(exitCode, equals(0));
    });

    test('returns 1 when stressed run is worse (regression detected)', () async {
      final file1 = await createSampleTraceFile('base.json', durationMs: 100, rssMb: 200.0);
      final file2 = await createSampleTraceFile('slow.json', durationMs: 250, rssMb: 400.0);

      final exitCode = await command.run([file1, file2]);
      expect(exitCode, equals(1));
    });

    test('compares in JSON format and writes to file', () async {
      final file1 = await createSampleTraceFile('base.json', durationMs: 100, rssMb: 200.0);
      final file2 = await createSampleTraceFile('stressed.json', durationMs: 150, rssMb: 250.0);
      final outputFile = path.join(tempDir.path, 'report.json');

      final exitCode = await command.run([
        file1,
        file2,
        '--format',
        'json',
        '--output',
        outputFile,
      ]);

      expect(exitCode, equals(1)); // Regression detected -> exit 1
      expect(File(outputFile).existsSync(), isTrue);

      final reportJson = jsonDecode(await File(outputFile).readAsString()) as Map<String, dynamic>;
      expect(reportJson['is_regression'], isTrue);
    });
  });
}
