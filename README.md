# Atlas

A personal strength training logbook built with Flutter. Structured around a
4-day novice bodybuilding program, Atlas tracks sets, weights, RPE, and 1RM
estimates — and surfaces progress over time through a session history with
per-exercise PR detection.

## Features

### Session workflow

- Select a workout from the 4-day program (Lower Strength, Upper Strength,
  Lower Hypertrophy, Upper Hypertrophy)
- Pre-workout overview screen with estimated duration, exercise list, and
  variant selection before the session begins
- Optional dynamic warm-up checklist before starting
- Per-exercise variant selection (e.g. Back Squat vs. Front Squat), swappable
  at any point during the session
- Slot category label shown on each exercise during an active session
- Warm-up set progression auto-calculated from working weight (50 / 70 / 90%)
- Set-by-set logging with weight, reps, and RPE
- Set notes captured via a modal button (non-blocking)
- Live 1RM estimate calculated from each working set
- Rest timer between sets
- Completion screen showing total sets, exercises, and volume moved, with
  optional session notes

### Training history

- Full session log with sets, exercises, and lbs moved per session
- `New PR` / `New 1RM` pills on sessions where records were broken
- Search and filter sessions by notes content
- Drill into any session to see every set (including set notes) with hit/miss
  coloring vs. targets
- Per-exercise `prev → now` pills in the detail view when a record was set

### Progression tracking

- 1RM history per variant, grouped by exercise slot, updated automatically
  from RPE-based estimates after each session
- Configurable 1RM formula (RPE/RTS, Epley, or others) in settings
- Working weights calculated from 1RM percentage each session
- Back-off sets rendered at reduced opacity; warm-up sets collapsed to a
  summary line
- Beginner default 1RM seeds on first launch

### Data management

- Backup database to the Downloads folder as a `.db` file
- Restore from a backup file (with optional pre-restore backup prompt)

## Tech stack

- **Flutter** (Dart) — cross-platform, targeting Android
- **SQLite** via `sqflite` — local database, schema v5
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
    repositories/   # All DB queries (includes backup/restore)
    seed/           # Program seed loader
  providers/        # SessionProvider (ChangeNotifier)
  screens/          # One file per screen
    widgets/        # Shared in-session widgets (rest timer, weight stepper, etc.)
  theme/            # App theme and responsive layout helpers
  utils/            # Progression service, weight/warm-up calculators, duration estimator
assets/
  data/
    program.json    # Full program definition (workouts, slots, variants, set templates)
    exercises.json  # Exercise catalog by slot
    warmup.json     # Dynamic warm-up movements
test/
  database_test.dart
```

## Database schema

Schema is versioned (currently v5). Migrations run automatically on upgrade
via `onUpgrade` in `app_database.dart`.

| Table                    | Purpose                                           |
| ------------------------ | ------------------------------------------------- |
| `programs`               | Training program metadata                         |
| `workouts`               | Individual workout days                           |
| `exercise_slots`         | Named slots within a workout (e.g. Squat Variant) |
| `exercise_variants`      | Selectable exercises per slot                     |
| `set_templates`          | Target sets/reps/percentage for each slot         |
| `variant_one_rm_history` | 1RM records per variant over time                 |
| `sessions`               | Completed workout sessions (with notes)           |
| `session_exercises`      | Which variant was chosen per slot per session     |
| `session_sets`           | Logged sets with weight, reps, RPE, 1RM, notes    |
| `settings`               | Key/value app settings (schema version, formula)  |
| `warmup_items`           | Dynamic warm-up exercise list                     |
