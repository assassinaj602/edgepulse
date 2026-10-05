# EdgePulse Research Paper

## How to compile this paper to PDF

Install pandoc and a LaTeX distribution:

```bash
sudo dnf install pandoc texlive-scheme-basic
```

Then:

```bash
pandoc paper.md -o paper.pdf --pdf-engine=pdflatex
```

## How to run the experiment

```bash
cd ../experiment
dart pub get
dart run run_experiment.dart
```

Or for rapid testing (<10 seconds):

```bash
dart run run_experiment.dart --fast
```

## How to regenerate figures and statistical analysis

```bash
cd ../experiment
pip install -r requirements.txt --user
python3 analyse.py
```

## How to cite

```bibtex
@misc{edgepulse2026,
  author = {Muhammad Assad Ullah},
  title  = {EdgePulse: Runtime Observability for On-Device AI},
  year   = {2026},
  url    = {https://github.com/assassinaj602/edgepulse}
}
```
