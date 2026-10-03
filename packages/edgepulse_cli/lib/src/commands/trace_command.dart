import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:edgepulse_core/edgepulse_core.dart';
import 'package:path/path.dart' as path;

/// Command to trace an AI model file using mock metrics or simulated runtime.
class TraceCommand {
  final ArgParser argParser = ArgParser()
    ..addOption(
      'model',
      abbr: 'm',
      help: 'Path to model file (required)',
    )
    ..addOption(
      'runs',
      abbr: 'r',
      defaultsTo: '10',
      help: 'Number of measured runs',
    )
    ..addOption(
      'warmup',
      abbr: 'w',
      defaultsTo: '3',
      help: 'Number of warmup runs',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output file path (prints to stdout if omitted)',
    )
    ..addOption(
      'format',
      abbr: 'f',
      defaultsTo: 'json',
      allowed: ['json', 'markdown', 'csv'],
      help: 'Export output format',
    )
    ..addOption(
      'timeout',
      abbr: 't',
      defaultsTo: '60',
      help: 'Timeout per run in seconds',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show command help',
    );

  /// Executes the trace command with given [args].
  Future<int> run(List<String> args) async {
    final ArgResults results;
    try {
      results = argParser.parse(args);
    } catch (e) {
      stderr.writeln('Error parsing arguments: $e');
      stderr.writeln(argParser.usage);
      return 1;
    }

    if (results['help'] as bool) {
      stdout.writeln('Usage: edgepulse trace --model <path> [options]');
      stdout.writeln(argParser.usage);
      return 0;
    }

    final modelPath = results['model'] as String?;
    if (modelPath == null || modelPath.trim().isEmpty) {
      stderr.writeln('Error: --model option is required.');
      stderr.writeln(argParser.usage);
      return 1;
    }

    final runs = int.tryParse(results['runs'] as String) ?? 10;
    final warmup = int.tryParse(results['warmup'] as String) ?? 3;
    final format = results['format'] as String;
    final outputPath = results['output'] as String?;

    final modelName = path.basenameWithoutExtension(modelPath);
    var modelFormat = path.extension(modelPath).replaceAll('.', '');
    if (modelFormat.isEmpty) modelFormat = 'unknown';

    stderr.writeln(
      '⚠️  Running in mock mode — real device metrics require the Flutter plugin.',
    );

    final random = Random();

    final mockCollector = MockMetricCollector(
      baseRssMb: 256.0,
      peakRssMb: 450.0,
    );

    final pulse = EdgePulse.mock(
      collector: mockCollector,
      config: TraceConfig(
        warmupRuns: warmup,
        measuredRuns: runs,
      ),
    );

    await pulse.initialize();

    final List<InferenceTrace> traces = await pulse.traceMany(
      modelId: modelName,
      modelFormat: modelFormat,
      runs: runs,
      run: () async {
        final delayMs = 80 + random.nextInt(220);
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      },
    );

    String exportedOutput;
    switch (format) {
      case 'markdown':
        exportedOutput = pulse.exportMarkdown(traces);
        break;
      case 'csv':
        exportedOutput = pulse.exportCsv(traces);
        break;
      case 'json':
      default:
        exportedOutput = pulse.exportJson(traces);
        break;
    }

    if (outputPath != null && outputPath.isNotEmpty) {
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsString(exportedOutput);
      stderr.writeln('Wrote output trace to $outputPath');
    } else {
      stdout.writeln(exportedOutput);
    }

    final summary = TraceSummary.fromTraces(
      modelId: modelName,
      traces: traces,
    );

    stderr.writeln(
      '✅ Traced ${traces.length} runs | Model: $modelName | Mean: ${summary.meanDuration.inMilliseconds}ms | Peak RAM: ${summary.peakMemoryMb.toStringAsFixed(1)}MB',
    );

    await pulse.dispose();

    return 0;
  }
}
