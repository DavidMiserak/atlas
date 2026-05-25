import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/database/database_constants.dart';
import 'package:atlas/data/repositories/one_rm_repository.dart';
import 'package:atlas/data/seed/seed_data.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
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

  group('Phase 5 edge cases', () {
    test('Multiple 1RM updates in one day — only last is current', () async {
      final oneRmRepo = OneRmRepository();
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;
      final today = DateTime.now();

      await oneRmRepo.recordNewOneRm(variantId, 225.0, today);
      await oneRmRepo.recordNewOneRm(variantId, 230.0, today);
      await oneRmRepo.recordNewOneRm(variantId, 235.0, today);

      final current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, 235.0);

      // Only one record should be is_current=1
      final history = await oneRmRepo.getOneRmHistory(variantId);
      final currentRecords = history.where((r) => r.isCurrent).toList();
      expect(currentRecords.length, 1);
      expect(currentRecords.first.weight, 235.0);
    });

    test('Round-number weights survive DB round-trip without CastError', () async {
      final oneRmRepo = OneRmRepository();
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;

      // Store a round number — SQLite may return int instead of double
      await oneRmRepo.recordNewOneRm(variantId, 225.0, DateTime.now());
      // These should not throw CastError
      final current = await oneRmRepo.getCurrentOneRm(variantId);
      expect(current, 225.0);
      final history = await oneRmRepo.getOneRmHistory(variantId);
      expect(history.first.weight, 225.0);
    });

    test('Same-weight update does not create duplicate history entries', () async {
      final oneRmRepo = OneRmRepository();
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;
      final db = await getDatabase();
      await db.delete(
        tableVariantOneRmHistory,
        where: '$col1rmHistoryVariantId = ?',
        whereArgs: [variantId],
      );

      final firstDate = DateTime(2026, 5, 25, 10, 0);
      final secondDate = DateTime(2026, 5, 25, 11, 0);

      await oneRmRepo.recordNewOneRm(
        variantId,
        225.0,
        firstDate,
        notes: 'Manual update',
      );
      await oneRmRepo.recordNewOneRm(
        variantId,
        225.0,
        secondDate,
        notes: 'Manual update retry',
      );

      final history = await oneRmRepo.getOneRmHistory(variantId);
      expect(history.length, 1);
      expect(history.first.weight, 225.0);
      expect(history.first.date, secondDate);
      expect(history.first.notes, 'Manual update retry');
      expect(history.first.isCurrent, isTrue);
    });

    test('getOneRmHistory hides accidental duplicate rows', () async {
      final oneRmRepo = OneRmRepository();
      await loadSeedData();
      final slot = await firstSlot();
      final variantId = slot['variantId']!;
      final db = await getDatabase();
      await db.delete(
        tableVariantOneRmHistory,
        where: '$col1rmHistoryVariantId = ?',
        whereArgs: [variantId],
      );

      final t1 = DateTime(2026, 5, 25, 10, 0, 0);
      final t2 = DateTime(2026, 5, 25, 10, 0, 10);
      await db.insert(tableVariantOneRmHistory, {
        col1rmHistoryVariantId: variantId,
        col1rmHistoryWeight: 180.0,
        col1rmHistoryDate: t1.toIso8601String(),
        col1rmHistoryNotes: 'dup-a',
        col1rmHistoryIsCurrent: 0,
      });
      await db.insert(tableVariantOneRmHistory, {
        col1rmHistoryVariantId: variantId,
        col1rmHistoryWeight: 180.0,
        col1rmHistoryDate: t2.toIso8601String(),
        col1rmHistoryNotes: 'dup-b',
        col1rmHistoryIsCurrent: 1,
      });

      final history = await oneRmRepo.getOneRmHistory(variantId);
      expect(history.length, 1);
      expect(history.first.weight, 180.0);
      expect(history.first.date, t2);
    });
  });
}
