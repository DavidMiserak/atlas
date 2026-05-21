import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'data/database/app_database.dart';
import 'data/seed/seed_data.dart';
import 'theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'screens/workout_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('main: Starting app initialization');

  // Initialize sqflite for desktop platforms
  if (Platform.isLinux || Platform.isWindows) {
    developer.log('main: Initializing sqflite FFI');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    // Recover from any restore that was interrupted by an app kill.
    final orphan = await checkOrphanedRestoreFile();
    if (orphan != null) {
      developer.log('main: orphaned restore staging file detected — completing restore');
      try {
        await completeOrphanedRestore();
        developer.log('main: orphaned restore completed successfully');
      } catch (e) {
        developer.log('main: orphaned restore failed, discarding staging file: $e');
        await discardOrphanedRestore();
      }
    }

    // Initialize database
    developer.log('main: Initializing database');
    await getDatabase();
    developer.log('main: Database initialized successfully');

    // Load seed data on first launch
    developer.log('main: Loading seed data');
    await loadSeedData();
    developer.log('main: Seed data loaded successfully');
  } catch (e) {
    developer.log('main: Error during initialization: $e');
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SessionProvider(),
      child: MaterialApp(
        title: 'Atlas',
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const WorkoutSelectionScreen(),
      ),
    );
  }
}
