import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/main.dart';
import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/seed/seed_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    useInMemoryDatabaseForTesting();
  });

  setUp(() async {
    await closeDatabase();
    await getDatabase();
    await loadSeedData();
  });

  tearDown(() async {
    await closeDatabase();
  });

  testWidgets('App renders workout selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Atlas'), findsWidgets);
  });
}
