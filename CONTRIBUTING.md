# Contributing to EdgePulse

Thank you for your interest in contributing to EdgePulse. This document explains 
how to get started, the project structure, and our contribution workflow.

---

## Repository Structure

EdgePulse is a monorepo managed with [Melos](https://melos.invertase.dev/).

```
packages/
├── edgepulse_core/      ← Pure Dart core (no Flutter). Start here.
├── edgepulse/           ← Flutter plugin with native Android + iOS layers.
└── edgepulse_cli/       ← Standalone CLI binary.
research/
├── experiment/          ← Empirical study scripts and raw trace data.
└── paper/               ← Research paper source.
```

## Development Setup

```bash
git clone https://github.com/assassinaj602/edgepulse.git
cd edgepulse
dart pub global activate melos
melos bootstrap
melos run test
melos run analyze
```

## Contribution Workflow

1. Pick an issue labeled `good first issue` or `help wanted`
2. Comment on the issue to claim it
3. Fork the repo and create a branch: `feat/your-feature-name`
4. Make your changes with tests
5. Run `melos run test` and `melos run analyze` — both must pass
6. Open a PR against `main` using the PR template
7. A maintainer will review within 5 business days

## Adding a New MetricCollector

A `MetricCollector` is the plugin point for adding new metric sources.
Implement the abstract class in `edgepulse_core`:

```dart
class MyCollector implements MetricCollector {
  @override
  Future<MemorySnapshot> captureMemory() async { ... }

  @override
  Future<ThermalState> captureThermalState() async { ... }

  @override
  Future<double?> captureBatteryDrainMah() async { ... }

  @override
  Future<double?> captureCpuUsagePercent() async { ... }

  @override
  Future<void> initialize() async { ... }

  @override
  Future<void> dispose() async { ... }
}
```

## Adding a New Exporter

Implement `TraceExporter` in `edgepulse_core/lib/src/exporters/`:

```dart
class MyExporter implements TraceExporter {
  @override
  String export(List<InferenceTrace> traces) { ... }

  @override
  String get fileExtension => 'myformat';
}
```

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- All public APIs must have dartdoc comments
- All new code must have tests
- Run `dart format` before committing

## Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(core): add LayerTiming model
fix(cli): handle missing model file gracefully
docs(readme): add platform support table
test(core): add MemorySnapshot serialization tests
chore(ci): add coverage reporting
```

## Questions?

Open a [Discussion](https://github.com/assassinaj602/edgepulse/discussions) 
— not an issue — for questions.
