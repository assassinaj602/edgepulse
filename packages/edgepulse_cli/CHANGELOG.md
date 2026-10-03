# Changelog

All notable changes to `edgepulse_cli` are documented here.

## 0.1.0 — 2026-10-04

### Added

- `edgepulse trace` command — run N inference traces and export JSON/Markdown/CSV
- `edgepulse compare` command — compare two trace files with delta table
- `edgepulse --version` and `edgepulse --help`
- Mock mode notice when running outside a Flutter app
- CI-friendly exit codes (1 when stressed is worse)
- ANSI colors in TTY output
- Installable via `dart pub global activate edgepulse_cli` — no Flutter required
