# Atlas

A personal strength training logbook built with Flutter. Structured around a
4-day novice bodybuilding program, Atlas tracks sets, weights, RPE, and 1RM
estimates — and surfaces progress over time through a session history with
per-exercise PR detection.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="screenshots/01_home.png" alt="Workouts home" width="200"/><br/><sub>Workouts home</sub></td>
    <td align="center"><img src="screenshots/05_workout_detail.png" alt="Workout overview" width="200"/><br/><sub>Workout overview</sub></td>
    <td align="center"><img src="screenshots/06_active_workout.png" alt="Active session" width="200"/><br/><sub>Active session</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/07_log_sets.png" alt="Log sets" width="200"/><br/><sub>Log sets</sub></td>
    <td align="center"><img src="screenshots/08_rest_timer.png" alt="Rest timer" width="200"/><br/><sub>Rest timer</sub></td>
    <td align="center"><img src="screenshots/09_last_set.png" alt="Last set" width="200"/><br/><sub>Last set</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/10_workout_summary_1.png" alt="Workout summary" width="200"/><br/><sub>Workout summary</sub></td>
    <td align="center"><img src="screenshots/11_workout_summary_2.png" alt="Next session progression" width="200"/><br/><sub>Next session progression</sub></td>
    <td align="center"><img src="screenshots/12_session_review.png" alt="Session review" width="200"/><br/><sub>Session review</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/02_history.png" alt="Training log" width="200"/><br/><sub>Training log</sub></td>
    <td align="center"><img src="screenshots/03_1rm.png" alt="1RM history" width="200"/><br/><sub>1RM history</sub></td>
    <td align="center"><img src="screenshots/04_settings.png" alt="Settings" width="200"/><br/><sub>Settings</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/14_home_inprogress_badge.png" alt="In-progress badge" width="200"/><br/><sub>In-progress badge</sub></td>
    <td align="center"><img src="screenshots/15_home_two_inprogress.png" alt="Multiple in-progress" width="200"/><br/><sub>Multiple in-progress</sub></td>
    <td align="center"><img src="screenshots/16_preflight_continue.png" alt="Continue session" width="200"/><br/><sub>Continue session</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/17_history_pr_pills.png" alt="PR &amp; 1RM pills" width="200"/><br/><sub>PR &amp; 1RM pills</sub></td>
    <td align="center"><img src="screenshots/18_1rm_list.png" alt="1RM leaderboard" width="200"/><br/><sub>1RM leaderboard</sub></td>
    <td align="center"><img src="screenshots/19_1rm_backsquat_history.png" alt="Back Squat progression" width="200"/><br/><sub>Back Squat progression</sub></td>
  </tr>
</table>

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
- Partial workout resume — if a session is left in-progress, the home screen
  shows an amber badge and a live progress bar on that workout card; sessions
  within the last 24 hours are resumable, and multiple workouts can be
  in-progress simultaneously

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
