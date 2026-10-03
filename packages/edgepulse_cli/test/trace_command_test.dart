import 'dart:convert';
import 'dart:io';

import 'package:edgepulse_cli/src/commands/trace_command.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('TraceCommand', () {
    late Directory tempDir;
    late TraceCommand command;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('edgepulse_trace_test_');
      command = TraceCommand();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('prints help when --help is passed', () async {
      final exitCode = await command.run(['--help']);
      expect(exitCode, equals(0));
    });

    test('returns exit code 1 if --model is missing', () async {
      final exitCode = await command.run([]);
      expect(exitCode, equals(1));
    });

    test('traces model and writes JSON output file', () async {
      final outputFile = path.join(tempDir.path, 'output.json');
      final exitCode = await command.run([
        '--model',
        'gemma-2b.gguf',
        '--runs',
        '5',
        '--warmup',
        '1',
        '--output',
        outputFile,
        '--format',
        'json',
      ]);

      expect(exitCode, equals(0));
      expect(File(outputFile).existsSync(), isTrue);

      final content = await File(outputFile).readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      expect(json['total_traces'], equals(5));
    });

    test('traces model with markdown format output', () async {
      final outputFile = path.join(tempDir.path, 'output.md');
      final exitCode = await command.run([
        '--model',
        'mobilenet_v3.tflite',
        '--runs',
        '2',
        '--output',
        outputFile,
        '--format',
        'markdown',
      ]);

      expect(exitCode, equals(0));
      final content = await File(outputFile).readAsString();
      expect(content, contains('# EdgePulse Inference Trace Report'));
    });

    test('traces model with csv format output', () async {
      final outputFile = path.join(tempDir.path, 'output.csv');
      final exitCode = await command.run([
        '--model',
        'resnet50.onnx',
        '--runs',
        '2',
        '--output',
        outputFile,
        '--format',
        'csv',
      ]);

      expect(exitCode, equals(0));
      final content = await File(outputFile).readAsString();
      expect(content, contains('trace_id,model_id'));
    });
  });
}
