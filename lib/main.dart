import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'data/database/app_database.dart';
import 'data/seed/seed_data.dart';
import 'providers/session_provider.dart';
import 'screens/workout_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database
  await getDatabase();

  // Load seed data on first launch
  await loadSeedData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SessionProvider(),
      child: MaterialApp(
        title: 'Workout Logger',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const WorkoutSelectionScreen(),
      ),
    );
  }
}
