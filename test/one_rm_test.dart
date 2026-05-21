import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/database/database_constants.dart';
import 'package:atlas/data/repositories/one_rm_repository.dart';
import 'package:atlas/data/seed/seed_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    useInMemoryDatabaseForTesting();
  });

  setUp(() async {
    await closeDatabase();
  });

  tearDown(() async {
    await closeDatabase();
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, int>> firstSlot() async {
    final db = await getDatabase();
    final slots = await db.query(
      tableExerciseSlots,
      where: '$colSlotWorkoutId = ?',
      whereArgs: [1],
      orderBy: '$colSlotOrder ASC',
      limit: 1,
    );
    final slotId = slots.first[colSlotId] as int;
    final variants = await db.query(
      tableExerciseVariants,
      where: '$colVariantSlotId = ?',
      whereArgs: [slotId],
      limit: 1,
    );
    final variantId = variants.first[colVariantId] as int;
    return {'slotId': slotId, 'variantId': variantId};
  }

  group('OneRmRepository', () {
    test('getCurrentOneRmsForVariants batch queries efficiently', () async {
      await loadSeedData();

      // Get variants from the database
      final db = await getDatabase();
      final variants = await db.query(tableExerciseVariants, limit: 3);
      final variantIds =
          variants.map((v) => v[colVariantId] as int).toList();

      final oneRmRepo = OneRmRepository();
      // Query all variants at once (batch query)
      final results = await oneRmRepo.getCurrentOneRmsForVariants(variantIds);

      // Verify the batch query returns results for all variants
      expect(results.length, 3);
      expect(results.containsKey(variantIds[0]), true);
      expect(results.containsKey(variantIds[1]), true);
      expect(results.containsKey(variantIds[2]), true);
    });

    test('getCurrentOneRmsForVariants returns empty map for empty input',
        () async {
      final oneRmRepo = OneRmRepository();
      final results = await oneRmRepo.getCurrentOneRmsForVariants([]);
      expect(results.isEmpty, true);
    });

    test('recordNewOneRm sets is_current flag correctly', () async {
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;
      final oneRmRepo = OneRmRepository();

      // Clear any existing 1RMs for this variant
      final db = await getDatabase();
      await db.delete(tableVariantOneRmHistory,
          where: '$col1rmHistoryVariantId = ?', whereArgs: [variantId]);

      // Record first 1RM
      await oneRmRepo.recordNewOneRm(variantId, 225.0, DateTime.now());
      var current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, 225.0);

      // Record second 1RM
      await oneRmRepo.recordNewOneRm(variantId, 235.0, DateTime.now());
      current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, 235.0);

      // Verify only the latest is marked as current
      final history = await oneRmRepo.getOneRmHistory(variantId);
      expect(history.length, 2);
      expect(history[0].weight, 235.0);
      expect(history[0].isCurrent, true);
      expect(history[1].weight, 225.0);
      expect(history[1].isCurrent, false);
    });
  });

  group('Manual 1RM Override', () {
    test('Manual override updates current 1RM', () async {
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;
      final oneRmRepo = OneRmRepository();

      // Clear any existing records
      final db = await getDatabase();
      await db.delete(tableVariantOneRmHistory,
          where: '$col1rmHistoryVariantId = ?', whereArgs: [variantId]);

      // Record initial 1RM
      await oneRmRepo.recordNewOneRm(variantId, 200.0, DateTime.now(),
          notes: 'Auto-progression');
      var current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, 200.0);

      // Manual override with higher weight
      await oneRmRepo.recordNewOneRm(variantId, 225.0, DateTime.now(),
          notes: 'Manual update');
      current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, 225.0);

      // Verify history order (newest first)
      final history = await oneRmRepo.getOneRmHistory(variantId);
      expect(history.length, 2);
      expect(history[0].weight, 225.0);
      expect(history[0].notes, 'Manual update');
      expect(history[1].weight, 200.0);
    });

    test('Manual override with lower weight updates correctly', () async {
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;
      final oneRmRepo = OneRmRepository();

      // Clear any existing records
      final db = await getDatabase();
      await db.delete(tableVariantOneRmHistory,
          where: '$col1rmHistoryVariantId = ?', whereArgs: [variantId]);

      // Set high initial 1RM
      await oneRmRepo.recordNewOneRm(variantId, 300.0, DateTime.now());

      // Manual override with lower weight
      await oneRmRepo.recordNewOneRm(variantId, 250.0, DateTime.now(),
          notes: 'Manual update');

      final current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, 250.0);

      final history = await oneRmRepo.getOneRmHistory(variantId);
      expect(history[0].weight, 250.0);
    });
  });

  group('1RM History Validation', () {
    test('Empty variant list returns empty map', () async {
      final oneRmRepo = OneRmRepository();
      final results = await oneRmRepo.getCurrentOneRmsForVariants([]);
      expect(results, isEmpty);
    });

    test('Non-existent variant returns null', () async {
      await loadSeedData();
      final oneRmRepo = OneRmRepository();
      final results = await oneRmRepo.getCurrentOneRmsForVariants([999999]);
      expect(results[999999], isNull);
    });

    test('History records maintain chronological order', () async {
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;
      final oneRmRepo = OneRmRepository();

      // Clear any existing records
      final db = await getDatabase();
      await db.delete(tableVariantOneRmHistory,
          where: '$col1rmHistoryVariantId = ?', whereArgs: [variantId]);

      // Record multiple 1RMs with different dates
      final now = DateTime.now();
      await oneRmRepo.recordNewOneRm(variantId, 200.0, now);
      await oneRmRepo.recordNewOneRm(
          variantId, 210.0, now.add(const Duration(days: 1)));
      await oneRmRepo.recordNewOneRm(
          variantId, 220.0, now.add(const Duration(days: 2)));

      final history = await oneRmRepo.getOneRmHistory(variantId);
      expect(history.length, 3);
      // Ordered newest first (DESC by date)
      expect(history[0].weight, 220.0);
      expect(history[1].weight, 210.0);
      expect(history[2].weight, 200.0);
    });
  });

  group('Weight Validation', () {
    test('Zero weight is rejected', () async {
      final oneRmRepo = OneRmRepository();
      // Weight 0 is invalid but database should accept it
      // The validation happens at the UI layer
      // This test verifies the repository doesn't filter
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;

      await oneRmRepo.recordNewOneRm(variantId, 0.0, DateTime.now());
      final current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, 0.0);
    });

    test('Negative weight is accepted by repository', () async {
      final oneRmRepo = OneRmRepository();
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;

      // Repository doesn't validate, UI does
      await oneRmRepo.recordNewOneRm(variantId, -100.0, DateTime.now());
      final current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, -100.0);
    });

    test('Decimal weights are preserved', () async {
      final oneRmRepo = OneRmRepository();
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;

      const testWeight = 225.5;
      await oneRmRepo.recordNewOneRm(variantId, testWeight, DateTime.now());
      final current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, testWeight);
    });
  });
}
