import 'dart:io';

import 'package:args/args.dart';
import 'package:edgepulse_cli/src/commands/compare_command.dart';
import 'package:edgepulse_cli/src/commands/trace_command.dart';

const String version = '0.1.0';

Future<void> main(List<String> arguments) async {
  final ArgParser parser = ArgParser()
    ..addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print EdgePulse CLI version',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print usage information',
    );

  if (arguments.isEmpty) {
    _printUsage(parser);
    exit(0);
  }

  if (arguments.contains('--version') || arguments.contains('-v')) {
    stdout.writeln('EdgePulse CLI v$version');
    exit(0);
  }

  final commandName = arguments.first;
  final commandArgs = arguments.sublist(1);

  try {
    switch (commandName) {
      case 'trace':
        final traceCmd = TraceCommand();
        final exitCode = await traceCmd.run(commandArgs);
        exit(exitCode);
      case 'compare':
        final compareCmd = CompareCommand();
        final exitCode = await compareCmd.run(commandArgs);
        exit(exitCode);
      case '--help':
      case '-h':
      case 'help':
        _printUsage(parser);
        exit(0);
      default:
        stderr.writeln('Error: Unknown command "$commandName".');
        _printUsage(parser);
        exit(1);
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  stdout
      .writeln('EdgePulse CLI — Standalone AI Model Tracing & Comparison Tool');
  stdout.writeln();
  stdout.writeln('Usage: edgepulse <command> [options]');
  stdout.writeln();
  stdout.writeln('Commands:');
  stdout.writeln('  trace     Trace an AI model execution and output metrics');
  stdout.writeln('  compare   Compare two JSON trace files and compute deltas');
  stdout.writeln();
  stdout.writeln('Global Options:');
  stdout.writeln(parser.usage);
}
