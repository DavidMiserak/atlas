import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('program.json schema validation', () {
    late Map<String, dynamic> json;

    setUpAll(() async {
      final raw = await rootBundle.loadString('assets/data/program.json');
      json = jsonDecode(raw) as Map<String, dynamic>;
    });

    test('top-level programs array exists and has one entry', () {
      expect(json.containsKey('programs'), isTrue);
      final programs = json['programs'] as List<dynamic>;
      expect(programs.length, 1);
    });

    test('program has required metadata fields', () {
      final program = (json['programs'] as List<dynamic>)[0] as Map<String, dynamic>;
      expect(program['name'], isNotEmpty);
      expect(program['version'], isNotEmpty);
      expect(program['description'], isNotEmpty);
    });

    test('program has 4 workouts', () {
      final program = (json['programs'] as List<dynamic>)[0] as Map<String, dynamic>;
      final workouts = program['workouts'] as List<dynamic>;
      expect(workouts.length, 4);
    });

    test('workouts have sequential day_number 1-4', () {
      final program = (json['programs'] as List<dynamic>)[0] as Map<String, dynamic>;
      final workouts = (program['workouts'] as List<dynamic>).cast<Map<String, dynamic>>();
      final dayNumbers = workouts.map((w) => w['day_number'] as int).toList()..sort();
      expect(dayNumbers, [1, 2, 3, 4]);
    });

    test('every slot has required fields', () {
      final program = (json['programs'] as List<dynamic>)[0] as Map<String, dynamic>;
      for (final workout in (program['workouts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        for (final slot in (workout['exercise_slots'] as List<dynamic>).cast<Map<String, dynamic>>()) {
          expect(slot['name'], isNotEmpty, reason: 'slot missing name in ${workout['name']}');
          expect(slot['order'], isNotNull, reason: 'slot missing order in ${workout['name']}');
          expect(slot['category'], isNotEmpty, reason: 'slot missing category in ${workout['name']}');
          expect(slot['set_template'], isNotNull, reason: 'slot missing set_template in ${slot['name']}');
          expect(slot['variants'], isNotNull, reason: 'slot missing variants in ${slot['name']}');
        }
      }
    });

    test('every set_template has a valid type and rest_seconds', () {
      final program = (json['programs'] as List<dynamic>)[0] as Map<String, dynamic>;
      for (final workout in (program['workouts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        for (final slot in (workout['exercise_slots'] as List<dynamic>).cast<Map<String, dynamic>>()) {
          final tpl = slot['set_template'] as Map<String, dynamic>;
          expect(['percentage', 'rpe'], contains(tpl['type']),
              reason: 'invalid type in ${slot['name']}');
          expect(tpl['rest_seconds'], isNotNull,
              reason: 'missing rest_seconds in ${slot['name']}');
          expect(tpl['rest_seconds'] as int, greaterThan(0),
              reason: 'rest_seconds <= 0 in ${slot['name']}');
          if (tpl['type'] == 'percentage') {
            expect(tpl['percentage_1rm'], isNotNull,
                reason: 'percentage type missing percentage_1rm in ${slot['name']}');
          } else {
            expect(tpl['rpe_target'], isNotNull,
                reason: 'rpe type missing rpe_target in ${slot['name']}');
          }
        }
      }
    });

    test('percentage slots have rest_seconds >= 150 (no accidental 120s for compounds)', () {
      final program = (json['programs'] as List<dynamic>)[0] as Map<String, dynamic>;
      for (final workout in (program['workouts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        for (final slot in (workout['exercise_slots'] as List<dynamic>).cast<Map<String, dynamic>>()) {
          final tpl = slot['set_template'] as Map<String, dynamic>;
          if (tpl['type'] == 'percentage') {
            expect(tpl['rest_seconds'] as int, greaterThanOrEqualTo(150),
                reason: 'percentage slot ${slot['name']} has short rest — check ms-training-bb.md');
          }
        }
      }
    });

    test('every variant has a positive initial_one_rm', () {
      final program = (json['programs'] as List<dynamic>)[0] as Map<String, dynamic>;
      for (final workout in (program['workouts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        for (final slot in (workout['exercise_slots'] as List<dynamic>).cast<Map<String, dynamic>>()) {
          for (final variant in (slot['variants'] as List<dynamic>).cast<Map<String, dynamic>>()) {
            expect(variant['initial_one_rm'], isNotNull,
                reason: '${variant['name']} in ${slot['name']} missing initial_one_rm');
            expect((variant['initial_one_rm'] as num).toDouble(), greaterThan(0),
                reason: '${variant['name']} has non-positive initial_one_rm');
          }
        }
      }
    });

    test('Back Squat has initial_one_rm = 135 (test hack removed)', () {
      final program = (json['programs'] as List<dynamic>)[0] as Map<String, dynamic>;
      final day1 = (program['workouts'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((w) => w['day_number'] == 1);
      final squatSlot = (day1['exercise_slots'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((s) => s['name'] == 'Squat Variant');
      final backSquat = (squatSlot['variants'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((v) => v['name'] == 'Back Squat');
      expect(backSquat['initial_one_rm'], 135);
    });
  });
}
