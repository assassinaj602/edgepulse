import 'package:meta/meta.dart';

/// Represents timing and output details for a specific model layer execution.
@immutable
class LayerTiming {
  /// Name or identifier of the layer (e.g., "attention_0", "embedding", "ffn_1").
  final String layerName;

  /// Type category of the layer (e.g., "attention", "ffn", "embedding", "conv").
  final String layerType;

  /// Time spent executing this layer.
  final Duration duration;

  /// Size of the output tensor produced by this layer in bytes, if available.
  final int? outputSizeBytes;

  /// Creates a [LayerTiming] instance.
  const LayerTiming({
    required this.layerName,
    required this.layerType,
    required this.duration,
    this.outputSizeBytes,
  });

  /// Factory constructor to create a [LayerTiming] from JSON data.
  factory LayerTiming.fromJson(Map<String, dynamic> json) {
    return LayerTiming(
      layerName: json['layer_name'] as String,
      layerType: json['layer_type'] as String,
      duration: Duration(milliseconds: json['duration_ms'] as int),
      outputSizeBytes: json['output_size_bytes'] as int?,
    );
  }

  /// Converts the layer timing into a JSON map representation.
  Map<String, dynamic> toJson() {
    return {
      'layer_name': layerName,
      'layer_type': layerType,
      'duration_ms': duration.inMilliseconds,
      'output_size_bytes': outputSizeBytes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayerTiming &&
          runtimeType == other.runtimeType &&
          layerName == other.layerName &&
          layerType == other.layerType &&
          duration == other.duration &&
          outputSizeBytes == other.outputSizeBytes;

  @override
  int get hashCode =>
      Object.hash(layerName, layerType, duration, outputSizeBytes);

  @override
  String toString() =>
      'LayerTiming(layerName: $layerName, layerType: $layerType, duration: $duration, outputSizeBytes: $outputSizeBytes)';
}
