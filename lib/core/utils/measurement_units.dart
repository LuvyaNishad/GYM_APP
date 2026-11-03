import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_providers.dart';

/// Storage always uses kilograms and centimetres; conversion happens at the UI.
class MeasurementUnits {
  const MeasurementUnits({this.weightUnit = 'kg', this.heightUnit = 'cm'});
  final String weightUnit, heightUnit;
  bool get imperialWeight => weightUnit == 'lbs' || weightUnit == 'lb';
  String get weightLabel => imperialWeight ? 'lbs' : 'kg';
  String get heightInputLabel => heightUnit == 'ft' ? 'in' : 'cm';
  double weightFromKg(double kg) => imperialWeight ? kg * 2.2046226218 : kg;
  double weightToKg(double value) =>
      imperialWeight ? value / 2.2046226218 : value;
  String weightInput(double kg) => weightFromKg(
    kg,
  ).toStringAsFixed(3).replaceFirst(RegExp(r'(?<=\.\d)0+$'), '');
  String preciseWeight(double kg) => '${weightInput(kg)} $weightLabel';
  double heightFromCm(double cm) => heightUnit == 'ft' ? cm / 2.54 : cm;
  double heightToCm(double value) => heightUnit == 'ft' ? value * 2.54 : value;
  String length(double? cm) => cm == null
      ? 'Not set'
      : '${heightFromCm(cm).toStringAsFixed(1)} $heightInputLabel';
  String weight(double? kg, {int decimals = 1}) => kg == null
      ? 'Not set'
      : '${weightFromKg(kg).toStringAsFixed(decimals)} $weightLabel';
  String height(double? cm) {
    if (cm == null) return 'Not set';
    if (heightUnit != 'ft') return '${cm.toStringAsFixed(0)} cm';
    final inches = (cm / 2.54).round();
    return '${inches ~/ 12} ft ${inches % 12} in';
  }
}

final measurementUnitsProvider = Provider<MeasurementUnits>((ref) {
  final user = ref.watch(userProfileProvider);
  return MeasurementUnits(
    weightUnit: user?.weightUnit ?? 'kg',
    heightUnit: user?.heightUnit ?? 'cm',
  );
});
