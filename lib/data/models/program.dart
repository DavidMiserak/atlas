import 'workout.dart';

class Program {
  final int? id;
  final String name;
  final String version;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Workout> workouts;

  Program({
    this.id,
    required this.name,
    required this.version,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.workouts = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'program_id': id,
      'name': name,
      'version': version,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Program fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['program_id'] as int?,
      name: map['name'] as String,
      version: map['version'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Program copyWith({
    int? id,
    String? name,
    String? version,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Workout>? workouts,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workouts: workouts ?? this.workouts,
    );
  }
}
