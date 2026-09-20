// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EquipmentModel _$EquipmentModelFromJson(Map<String, dynamic> json) =>
    _EquipmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isAvailable: json['isAvailable'] as bool? ?? false,
    );

Map<String, dynamic> _$EquipmentModelToJson(_EquipmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isAvailable': instance.isAvailable,
    };
