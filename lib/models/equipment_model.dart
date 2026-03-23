import 'package:freezed_annotation/freezed_annotation.dart';

part 'equipment_model.freezed.dart';
part 'equipment_model.g.dart';

/// Gym equipment available used to filter exercises.
@freezed
class EquipmentModel with _$EquipmentModel {
  const factory EquipmentModel({
    required String id,
    required String name,
    @Default(false) bool isAvailable,
  }) = _EquipmentModel;

  factory EquipmentModel.fromJson(Map<String, dynamic> json) =>
      _$EquipmentModelFromJson(json);
}
