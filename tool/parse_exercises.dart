// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('gym_exercise_library.md');
  if (!file.existsSync()) {
    print('File gym_exercise_library.md not found');
    exit(1);
  }

  final lines = file.readAsLinesSync();

  String currentCategory = '';
  String currentSubCategory = '';
  String? currentExerciseName;
  Map<String, String> currentFields = {};

  final List<Map<String, dynamic>> exercises = [];

  void flushExercise() {
    if (currentExerciseName != null && currentFields.containsKey('ID')) {
      final id = currentFields['ID']!.replaceAll('`', '').trim();
      final desc = currentFields['Description'] ?? '';
      
      // Parse primary muscles
      final rawPrimary = currentFields['Primary muscles'] ?? '';
      final primaryMuscles = rawPrimary
          .split(RegExp(r'[;,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Parse secondary muscles
      final rawSecondary = currentFields['Secondary muscles / stabilizers'] ?? '';
      final secondaryMuscles = rawSecondary
          .split(RegExp(r'[;,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Parse equipment
      final rawEquipment = currentFields['Equipment'] ?? '';
      final equipmentList = rawEquipment
          .split(RegExp(r'[;,]'))
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      // Primary equipment normalization (barbell, dumbbell, cable, machine, bodyweight)
      String primaryEquipment = 'barbell';
      final eqJoined = equipmentList.join(' ').toLowerCase();
      if (eqJoined.contains('barbell') || eqJoined.contains('plates')) {
        primaryEquipment = 'barbell';
      } else if (eqJoined.contains('dumbbell')) {
        primaryEquipment = 'dumbbell';
      } else if (eqJoined.contains('cable') || eqJoined.contains('pulley')) {
        primaryEquipment = 'cable';
      } else if (eqJoined.contains('machine') || eqJoined.contains('smith') || eqJoined.contains('hack') || eqJoined.contains('press machine')) {
        primaryEquipment = 'machine';
      } else if (eqJoined.contains('bodyweight') || eqJoined.contains('pull-up bar') || eqJoined.contains('dip bar') || eqJoined.contains('mat')) {
        primaryEquipment = 'bodyweight';
      } else if (eqJoined.contains('band')) {
        primaryEquipment = 'band';
      } else if (eqJoined.contains('kettlebell')) {
        primaryEquipment = 'kettlebell';
      } else {
        primaryEquipment = equipmentList.isNotEmpty ? equipmentList.first : 'other';
      }

      // Movement / Type
      final rawMoveType = currentFields['Movement / type'] ?? '';
      final isCompound = rawMoveType.toLowerCase().contains('compound');
      final exerciseType = isCompound
          ? 'compound'
          : (rawMoveType.toLowerCase().contains('isolation') ? 'isolation' : 'mobility');

      // Movement pattern
      String movementPattern = 'general';
      final mtLower = rawMoveType.toLowerCase();
      if (mtLower.contains('horizontal push')) {
        movementPattern = 'horizontal_push';
      } else if (mtLower.contains('vertical push') || mtLower.contains('overhead')) {
        movementPattern = 'vertical_push';
      } else if (mtLower.contains('horizontal pull') || mtLower.contains('row')) {
        movementPattern = 'horizontal_pull';
      } else if (mtLower.contains('vertical pull') || mtLower.contains('pulldown') || mtLower.contains('pull-up')) {
        movementPattern = 'vertical_pull';
      } else if (mtLower.contains('squat')) {
        movementPattern = 'squat';
      } else if (mtLower.contains('hinge')) {
        movementPattern = 'hinge';
      } else if (mtLower.contains('lunge')) {
        movementPattern = 'lunge';
      } else if (mtLower.contains('curl')) {
        movementPattern = 'curl';
      } else if (mtLower.contains('extension')) {
        movementPattern = 'extension';
      } else if (mtLower.contains('carry')) {
        movementPattern = 'carry';
      } else if (mtLower.contains('rotation')) {
        movementPattern = 'rotation';
      }

      // Difficulty
      final difficulty = currentFields['Difficulty'] ?? 'beginner to intermediate';

      // Tags
      final rawTags = currentFields['Tags'] ?? '';
      final tags = RegExp(r'`([^`]+)`')
          .allMatches(rawTags)
          .map((m) => m.group(1)!)
          .toList();

      // How to perform (instructions)
      final rawHow = currentFields['How to perform'] ?? '';
      // Split into clean steps by comma or period if sensible
      final instructions = rawHow
          .split(RegExp(r'\.(?=\s+[A-Z]|\s*$)'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Coaching notes
      final coachingNotes = currentFields['Coaching / safety notes'] ?? '';

      // Logging suggestions
      final loggingSuggestions = currentFields['Logging suggestions'] ?? '';

      // Clean top-level category
      String topCategory = currentCategory;
      if (topCategory.startsWith('Arms')) {
        topCategory = 'Arms';
      } else if (topCategory.startsWith('Legs')) {
        topCategory = 'Legs';
      } else if (topCategory.startsWith('Core')) {
        topCategory = 'Core';
      } else if (topCategory.startsWith('Full Body')) {
        topCategory = 'Full Body';
      } else if (topCategory.startsWith('Mobility')) {
        topCategory = 'Mobility';
      }

      // Default rest: compounds get 120s, isolations 90s, mobility 60s
      final defaultRest = isCompound ? 120 : (exerciseType == 'isolation' ? 90 : 60);

      exercises.add({
        'id': id,
        'name': currentExerciseName,
        'category': topCategory,
        'sub_category': currentSubCategory,
        'description': desc,
        'primary_muscles': primaryMuscles,
        'secondary_muscles': secondaryMuscles,
        'equipment': equipmentList,
        'primary_equipment': primaryEquipment,
        'movement_pattern': movementPattern,
        'exercise_type': exerciseType,
        'difficulty': difficulty,
        'tags': tags,
        'instructions': instructions.isNotEmpty ? instructions : [rawHow],
        'coaching_notes': coachingNotes,
        'logging_suggestions': loggingSuggestions,
        'default_rest_seconds': defaultRest,
        'is_custom': false,
        'alternatives': <String>[],
      });
    }
    currentExerciseName = null;
    currentFields = {};
  }

  String? activeFieldKey;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.startsWith('### ')) {
      flushExercise();
      final fullHeader = line.substring(4).trim();
      currentCategory = fullHeader;
      if (fullHeader.contains(' - ')) {
        final parts = fullHeader.split(' - ');
        currentCategory = parts[0].trim();
        currentSubCategory = parts[1].trim();
      } else {
        currentSubCategory = fullHeader;
      }
      continue;
    }

    if (line.startsWith('#### ')) {
      flushExercise();
      currentExerciseName = line.substring(5).trim();
      activeFieldKey = null;
      continue;
    }

    if (currentExerciseName != null) {
      final match = RegExp(r'^\s*-\s+\*\*([^:]+):\*\*\s*(.*)$').firstMatch(line);
      if (match != null) {
        final key = match.group(1)!.trim();
        final value = match.group(2)!.trim();
        currentFields[key] = value;
        activeFieldKey = key;
      } else if (activeFieldKey != null && line.trim().isNotEmpty && !line.startsWith('-')) {
        // Multi-line continuation of current field
        currentFields[activeFieldKey] = '${currentFields[activeFieldKey]} ${line.trim()}';
      }
    }
  }

  flushExercise();

  print('Parsed ${exercises.length} exercises successfully.');

  // Second pass: Populate smart alternatives!
  // An alternative is an exercise with the same category AND movement pattern or muscle group, but different equipment/variation
  for (final ex in exercises) {
    final id = ex['id'] as String;
    final category = ex['category'] as String;
    final pattern = ex['movement_pattern'] as String;
    final primary = (ex['primary_muscles'] as List).cast<String>();

    final candidates = exercises.where((other) {
      if (other['id'] == id) return false;
      if (other['category'] != category) return false;
      // Match pattern or primary muscle
      final otherPattern = other['movement_pattern'] as String;
      final otherPrimary = (other['primary_muscles'] as List).cast<String>();
      final sharesPrimary = primary.any((m) => otherPrimary.contains(m));
      return (otherPattern == pattern && pattern != 'general') || sharesPrimary;
    }).take(3).map((e) => e['id'] as String).toList();

    ex['alternatives'] = candidates;
  }

  final outDir = Directory('assets/data');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final outFile = File('assets/data/exercise_catalog.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(exercises));
  print('Saved ${exercises.length} exercises to assets/data/exercise_catalog.json (${outFile.lengthSync()} bytes)');
}
