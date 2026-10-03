# EdgePulse CLI

Standalone CLI tool for EdgePulse — trace on-device AI models and compare inference results from any terminal or CI/CD pipeline without Flutter.

## Usage

```bash
edgepulse trace --model model.gguf --runs 20 --output trace.json
edgepulse compare baseline.json stressed.json
```
