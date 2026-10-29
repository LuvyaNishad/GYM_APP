/// The same clockwise muscle categories are used by every workout radar.
const muscleRadarCategories = [
  'Back',
  'Legs',
  'Chest',
  'Arms',
  'Core',
  'Shoulders',
];

/// Maps catalog anatomy and older workout labels to one of the six categories.
/// Unknown groups are left unmapped rather than inventing muscle volume.
String? radarMuscleCategory(String muscle) {
  final name = muscle.toLowerCase().trim();
  if (name.contains('delt') || name.contains('shoulder')) return 'Shoulders';
  if (name.contains('hamstring') ||
      name.contains('biceps femoris') ||
      name.contains('semitend') ||
      name.contains('semimembr') ||
      name.contains('quad') ||
      name.contains('rectus femoris') ||
      name.contains('vastus') ||
      name.contains('glut') ||
      name.contains('calf') ||
      name.contains('calves') ||
      name.contains('gastrocnemius') ||
      name.contains('soleus') ||
      name.contains('adductor') ||
      name.contains('abductor') ||
      name.contains('tibialis') ||
      name.contains('leg') ||
      name.contains('lower body')) {
    return 'Legs';
  }
  if (name.contains('bicep') ||
      name.contains('tricep') ||
      name.contains('brachialis') ||
      name.contains('brachioradialis') ||
      name.contains('forearm') ||
      name.contains('wrist') ||
      name == 'arms' ||
      name == 'arm') {
    return 'Arms';
  }
  if (name.contains('pector') ||
      name.contains('chest') ||
      name.contains('pec')) {
    return 'Chest';
  }
  if (name.contains('back') ||
      name.contains('latissimus') ||
      name == 'lats' ||
      name.contains('lat muscle') ||
      name.contains('pulldown') ||
      name.contains('rhomboid') ||
      name.contains('trap') ||
      name.contains('erector')) {
    return 'Back';
  }
  if (name.contains('abdom') ||
      name.contains('oblique') ||
      name.contains('core') ||
      name == 'abs') {
    return 'Core';
  }
  return null;
}

Map<String, double> muscleRadarTotals(Map<String, num> volumes) {
  final totals = {for (final category in muscleRadarCategories) category: 0.0};
  for (final entry in volumes.entries) {
    final category = radarMuscleCategory(entry.key);
    final value = entry.value.toDouble();
    if (category != null && value.isFinite && value > 0) {
      totals[category] = totals[category]! + value;
    }
  }
  return totals;
}
