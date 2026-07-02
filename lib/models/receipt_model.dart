import 'package:hive/hive.dart';

part 'receipt_model.g.dart';

@HiveType(typeId: 6)
class Receipt {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? transactionId;

  @HiveField(2)
  final String imagePath;

  @HiveField(3)
  final String? extractedText;

  @HiveField(4)
  final double? confidenceScore;

  @HiveField(5)
  final DateTime processedAt;

  Receipt({
    required this.id,
    this.transactionId,
    required this.imagePath,
    this.extractedText,
    this.confidenceScore,
    required this.processedAt,
  });

  Receipt copyWith({
    String? id,
    String? transactionId,
    String? imagePath,
    String? extractedText,
    double? confidenceScore,
    DateTime? processedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'image_path': imagePath,
      'extracted_text': extractedText,
      'confidence_score': confidenceScore,
      'processed_at': processedAt.toIso8601String(),
    };
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'],
      transactionId: json['transaction_id'],
      imagePath: json['image_path'],
      extractedText: json['extracted_text'],
      confidenceScore: json['confidence_score']?.toDouble(),
      processedAt: DateTime.parse(json['processed_at']),
    );
  }
}
