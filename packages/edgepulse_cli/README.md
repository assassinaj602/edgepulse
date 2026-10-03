# edgepulse_cli

Standalone CLI for EdgePulse — trace on-device AI models and compare inference results from any terminal or CI/CD pipeline. No Flutter required.

## Installation

```bash
dart pub global activate edgepulse_cli
```

## Quick Start

### Trace a model

```bash
edgepulse trace --model model.gguf --runs 20 --output trace.json
```

### Compare two trace files

```bash
edgepulse compare baseline.json stressed.json
```

### Get help

```bash
edgepulse --help
edgepulse trace --help
edgepulse compare --help
```

## Features

- `trace`: Execute N inference traces, capturing memory snapshots, thermal status, layer timing, and export to JSON, Markdown, or CSV.
- `compare`: Compare baseline vs target traces with statistical summary (p50/p95/p99) and delta analysis.
- ANSI color output and terminal formatting.
- Exit codes suitable for CI/CD pipeline automated regression checking.

## License

MIT License. See [LICENSE](LICENSE) for details.
