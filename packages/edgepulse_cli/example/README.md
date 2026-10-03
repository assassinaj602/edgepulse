# edgepulse_cli Examples

## Install

```bash
dart pub global activate edgepulse_cli
```

## Trace a model

```bash
edgepulse trace --model model.gguf --runs 20 --output trace.json
```

## Compare two trace files

```bash
edgepulse compare baseline.json stressed.json
```

## Get help

```bash
edgepulse --help
edgepulse trace --help
edgepulse compare --help
```
