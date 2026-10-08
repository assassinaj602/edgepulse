---
layout: default
title: Installation
parent: Docs
nav_order: 1
has_children: false
permalink: /docs/installation/
---

# Installation

## CLI (no Flutter required)

```bash
dart pub global activate edgepulse_cli
edgepulse --help
```

Add to your `PATH` if the command isn't found:

```bash
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.bashrc
source ~/.bashrc
```

## Flutter plugin

Add to your `pubspec.yaml`:

```yaml
dependencies:
  edgepulse: ^0.2.2
  edgepulse_core: ^0.1.0
```

Then:

```bash
flutter pub get
```

## Minimum requirements

| Platform | Minimum |
|----------|---------|
| Dart SDK | 3.0.0 |
| Flutter | 3.10.0 |
| Android | API 21 (thermal requires API 29+) |
| iOS | 12.0 |

## Verify the install

```bash
edgepulse --version
```

Should print the current CLI version.
