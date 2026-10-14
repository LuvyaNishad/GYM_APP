/// Body measurement and recomposition model for LEON.
library;

class BodyMeasurementEntry {
  const BodyMeasurementEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.bodyFatPercent,
    this.waistCm,
    this.chestCm,
    this.armsCm,
    this.thighsCm,
    this.notes,
  });

  final String id;
  final DateTime date;
  final double weightKg;
  final double? bodyFatPercent;
  final double? waistCm;
  final double? chestCm;
  final double? armsCm;
  final double? thighsCm;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight_kg': weightKg,
        if (bodyFatPercent != null) 'body_fat_percent': bodyFatPercent,
        if (waistCm != null) 'waist_cm': waistCm,
        if (chestCm != null) 'chest_cm': chestCm,
        if (armsCm != null) 'arms_cm': armsCm,
        if (thighsCm != null) 'thighs_cm': thighsCm,
        if (notes != null) 'notes': notes,
      };

  factory BodyMeasurementEntry.fromJson(Map<String, dynamic> json) =>
      BodyMeasurementEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weight_kg'] as num).toDouble(),
        bodyFatPercent: (json['body_fat_percent'] as num?)?.toDouble(),
        waistCm: (json['waist_cm'] as num?)?.toDouble(),
        chestCm: (json['chest_cm'] as num?)?.toDouble(),
        armsCm: (json['arms_cm'] as num?)?.toDouble(),
        thighsCm: (json['thighs_cm'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}
