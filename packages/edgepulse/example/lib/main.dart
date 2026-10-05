import 'package:flutter/material.dart';
import 'package:edgepulse/edgepulse.dart';

void main() => runApp(const EdgePulseExampleApp());

class EdgePulseExampleApp extends StatelessWidget {
  const EdgePulseExampleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'EdgePulse Example',
      home: TracePage(),
    );
  }
}

class TracePage extends StatefulWidget {
  const TracePage({super.key});
  @override
  State<TracePage> createState() => _TracePageState();
}

class _TracePageState extends State<TracePage> {
  String _output = 'Tap "Run Trace" to start.';
  bool _loading = false;

  Future<void> _runTrace() async {
    setState(() {
      _loading = true;
      _output = 'Tracing…';
    });

    final pulse = EdgePulse(
      collector: PlatformMetricCollector(),
      config: const TraceConfig(
        measuredRuns: 5,
        warmupRuns: 1,
        collectThermal: true,
        collectBattery: true,
        collectCpu: true,
      ),
    );

    try {
      await pulse.initialize();
      final traces = await pulse.traceMany(
        modelId: 'example-model',
        modelFormat: 'mock',
        // Replace this with your actual model inference call:
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        },
      );
      await pulse.dispose();

      final json = pulse.exportJson(traces);
      setState(() {
        _output = json;
      });
    } on StateError catch (e) {
      setState(() {
        _output = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EdgePulse Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _runTrace,
              child: Text(_loading ? 'Tracing…' : 'Run Trace (5 runs)'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _output,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
