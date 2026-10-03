import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:edgepulse_core/edgepulse_core.dart';

/// Command to compare two JSON trace files and calculate metric deltas.
class CompareCommand {
  final ArgParser argParser = ArgParser()
    ..addOption(
      'format',
      abbr: 'f',
      defaultsTo: 'table',
      allowed: ['table', 'markdown', 'json'],
      help: 'Output comparison format',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Write to file instead of stdout',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show command help',
    );

  /// Executes the compare command.
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
      stdout.writeln('Usage: edgepulse compare <file1.json> <file2.json> [options]');
      stdout.writeln(argParser.usage);
      return 0;
    }

    final rest = results.rest;
    if (rest.length < 2) {
      stderr.writeln('Error: Two JSON trace files are required for comparison.');
      stderr.writeln('Usage: edgepulse compare <baseline.json> <stressed.json>');
      return 1;
    }

    final file1Path = rest[0];
    final file2Path = rest[1];

    final File file1 = File(file1Path);
    final File file2 = File(file2Path);

    if (!await file1.exists()) {
      stderr.writeln('Error: File not found: $file1Path');
      return 1;
    }
    if (!await file2.exists()) {
      stderr.writeln('Error: File not found: $file2Path');
      return 1;
    }

    final List<InferenceTrace> traces1;
    final List<InferenceTrace> traces2;

    try {
      traces1 = _parseTracesFromFile(await file1.readAsString());
      traces2 = _parseTracesFromFile(await file2.readAsString());
    } catch (e) {
      stderr.writeln('Error parsing JSON trace files: $e');
      return 1;
    }

    if (traces1.isEmpty || traces2.isEmpty) {
      stderr.writeln('Error: One or both trace files contained no traces.');
      return 1;
    }

    final format = results['format'] as String;
    final outputPath = results['output'] as String?;

    final meanDur1 = _mean(traces1.map((t) => t.totalDurationMs.toDouble()));
    final meanDur2 = _mean(traces2.map((t) => t.totalDurationMs.toDouble()));

    final peakMem1 = _max(traces1.map((t) => t.peakRssMb));
    final peakMem2 = _max(traces2.map((t) => t.peakRssMb));

    final deltaMem1 = _mean(traces1.map((t) => t.memoryDeltaMb));
    final deltaMem2 = _mean(traces2.map((t) => t.memoryDeltaMb));

    final cpu1 = _meanOrNull(traces1.map((t) => t.cpuUsagePercent));
    final cpu2 = _meanOrNull(traces2.map((t) => t.cpuUsagePercent));

    final batt1 = _meanOrNull(traces1.map((t) => t.batteryDrainMah));
    final batt2 = _meanOrNull(traces2.map((t) => t.batteryDrainMah));

    final isRegression = meanDur2 > meanDur1 || peakMem2 > peakMem1;

    String output;
    if (format == 'json') {
      output = const JsonEncoder.withIndent('  ').convert({
        'baseline_file': file1Path,
        'stressed_file': file2Path,
        'duration_ms': {
          'baseline': meanDur1,
          'stressed': meanDur2,
          'delta': meanDur2 - meanDur1,
          'percent_change': _pctChange(meanDur1, meanDur2),
        },
        'memory_peak_mb': {
          'baseline': peakMem1,
          'stressed': peakMem2,
          'delta': peakMem2 - peakMem1,
          'percent_change': _pctChange(peakMem1, peakMem2),
        },
        'is_regression': isRegression,
      });
    } else if (format == 'markdown') {
      final buf = StringBuffer();
      buf.writeln('# EdgePulse Comparison Report');
      buf.writeln('**Baseline:** $file1Path | **Stressed:** $file2Path');
      buf.writeln();
      buf.writeln('| Metric | Baseline | Stressed | Delta | % Change |');
      buf.writeln('| --- | --- | --- | --- | --- |');
      buf.writeln(
        '| Duration (ms) | ${meanDur1.toStringAsFixed(1)} | ${meanDur2.toStringAsFixed(1)} | ${_fmtDelta(meanDur2 - meanDur1)} | ${_pctChangeFmt(meanDur1, meanDur2)} |',
      );
      buf.writeln(
        '| Memory Peak (MB) | ${peakMem1.toStringAsFixed(1)} | ${peakMem2.toStringAsFixed(1)} | ${_fmtDelta(peakMem2 - peakMem1)} | ${_pctChangeFmt(peakMem1, peakMem2)} |',
      );
      buf.writeln(
        '| Memory Delta (MB) | ${deltaMem1.toStringAsFixed(1)} | ${deltaMem2.toStringAsFixed(1)} | ${_fmtDelta(deltaMem2 - deltaMem1)} | ${_pctChangeFmt(deltaMem1, deltaMem2)} |',
      );
      output = buf.toString();
    } else {
      // Table format
      final buf = StringBuffer();
      buf.writeln('EdgePulse Comparison Report');
      buf.writeln('════════════════════════════════════════════════════════');
      buf.writeln(
        'Metric                Baseline          Stressed          Delta',
      );
      buf.writeln('────────────────────────────────────────────────────────');

      buf.writeln(
        _formatRow('Duration (ms)', meanDur1, meanDur2, isMs: true),
      );
      buf.writeln(
        _formatRow('Memory Peak (MB)', peakMem1, peakMem2),
      );
      buf.writeln(
        _formatRow('Memory Delta (MB)', deltaMem1, deltaMem2),
      );
      if (cpu1 != null && cpu2 != null) {
        buf.writeln(_formatRow('CPU Usage (%)', cpu1, cpu2));
      }
      if (batt1 != null && batt2 != null) {
        buf.writeln(_formatRow('Battery (mAh)', batt1, batt2, isSmall: true));
      }
      buf.writeln('════════════════════════════════════════════════════════');

      output = buf.toString();
    }

    if (outputPath != null && outputPath.isNotEmpty) {
      await File(outputPath).writeAsString(output);
      stderr.writeln('Wrote comparison report to $outputPath');
    } else {
      stdout.writeln(output);
    }

    return isRegression ? 1 : 0;
  }

  static List<InferenceTrace> _parseTracesFromFile(String content) {
    final dynamic parsed = jsonDecode(content);
    if (parsed is List) {
      return parsed
          .map((e) => InferenceTrace.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (parsed is Map<String, dynamic>) {
      if (parsed.containsKey('traces')) {
        final list = parsed['traces'] as List;
        return list
            .map((e) => InferenceTrace.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        return [InferenceTrace.fromJson(parsed)];
      }
    }
    throw FormatException('Unrecognized trace JSON format');
  }

  static double _mean(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double? _meanOrNull(Iterable<double?> values) {
    final nonNull = values.whereType<double>();
    if (nonNull.isEmpty) return null;
    return _mean(nonNull);
  }

  static double _max(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  static double _pctChange(double base, double stressed) {
    if (base == 0.0) return 0.0;
    return ((stressed - base) / base) * 100.0;
  }

  static String _pctChangeFmt(double base, double stressed) {
    final pct = _pctChange(base, stressed);
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  static String _fmtDelta(double delta) {
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)}';
  }

  static String _formatRow(
    String metric,
    double base,
    double stressed, {
    bool isMs = false,
    bool isSmall = false,
  }) {
    final delta = stressed - base;
    final pct = _pctChange(base, stressed);
    final sign = delta >= 0 ? '+' : '';
    final digits = isSmall ? 4 : 1;

    final baseStr = base.toStringAsFixed(digits).padRight(16);
    final stressedStr = stressed.toStringAsFixed(digits).padRight(16);
    final deltaStr = '$sign${delta.toStringAsFixed(digits)} ($sign${pct.toStringAsFixed(1)}%)';

    final metricPadded = metric.padRight(20);
    return '$metricPadded $baseStr $stressedStr $deltaStr';
  }
}
