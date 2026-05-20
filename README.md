# Atlas

A personal strength training logbook built with Flutter. Structured around a
4-day novice bodybuilding program, Atlas tracks sets, weights, RPE, and 1RM
estimates — and surfaces progress over time through a session history with
per-exercise PR detection.

## Features

### Session workflow

- Select a workout from the 4-day program (Lower Strength, Upper Strength,
  Lower Hypertrophy, Upper Hypertrophy)
- Optional dynamic warm-up checklist before starting
- Per-exercise variant selection (e.g. Back Squat vs. Front Squat)
- Warm-up set progression auto-calculated from working weight (50 / 70 / 90%)
- Set-by-set logging with weight, reps, and RPE
- Live 1RM estimate calculated from each working set
- Completion screen showing total sets, exercises, and volume moved

### Training history

- Full session log with sets, exercises, and lbs moved per session
- `New PR` / `New 1RM` pills on sessions where records were broken
- Drill into any session to see every set with hit/miss coloring vs. targets
- Per-exercise `prev → now` pills in the detail view when a record was set

### Progression tracking

- 1RM history per variant, updated automatically from RPE-based estimates
- Working weights calculated from 1RM percentage each session
- Back-off sets rendered at reduced opacity; warm-up sets collapsed to a
  summary line

## Tech stack

- **Flutter** (Dart) — cross-platform, targeting Android
- **SQLite** via `sqflite` — local database, schema v3
- **Provider** — state management
- **Google Fonts** — BarlowCondensed, SpaceGrotesk, Outfit, JetBrainsMono

## Getting started

```bash
# Run analyzer, tests, and launch (requires connected device or emulator)
make run

# Build and push debug APK to connected Android device
make push-apk

# Build and push release APK
make push-apk-release
```

```bash
# Set up pre-commit hooks (first time)
make pre-commit-setup
```

## Project structure

```text
lib/
  data/
    database/       # SQLite setup, migrations, constants
    models/         # Dart data classes
    repositories/   # All DB queries
    seed/           # Program seed data and exercise catalog
  providers/        # SessionProvider (ChangeNotifier)
  screens/          # One file per screen
    widgets/        # Shared in-session widgets
assets/
  data/
    exercises.json  # Full exercise catalog by slot
    warmup.json     # Dynamic warm-up movements
test/
  database_test.dart
```

## Database schema

Schema is versioned (currently v3). Migrations run automatically on upgrade
via `onUpgrade` in `app_database.dart`.

| Table                    | Purpose                                           |
| ------------------------ | ------------------------------------------------- |
| `programs`               | Training program metadata                         |
| `workouts`               | Individual workout days                           |
| `exercise_slots`         | Named slots within a workout (e.g. Squat Variant) |
| `exercise_variants`      | Selectable exercises per slot                     |
| `set_templates`          | Target sets/reps/percentage for each slot         |
| `variant_one_rm_history` | 1RM records per variant over time                 |
| `sessions`               | Completed workout sessions                        |
| `session_exercises`      | Which variant was chosen per slot per session     |
| `session_sets`           | Logged sets with weight, reps, RPE, 1RM snapshot  |
| `settings`               | Key/value app settings (schema version, etc.)     |
| `warmup_items`           | Dynamic warm-up exercise list                     |
