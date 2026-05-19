# Implementation Plan: Workout Logger – Engineered Training Companion

Generated from APPROVED design doc
Date: 2026-05-19
Branch: develop
Platform: Flutter (Android primary)
Status: READY_FOR_REVIEW

## Executive Summary

Build a Flutter app that enforces a structured 4-day bodybuilding program with:

- SQLite-backed local-only data model
- Variant-specific 1RM tracking with automatic recalculation
- Mid-session exercise variant swapping with weight recalculation
- Historical session logging with 1RM snapshots
- Offline-first, phone-optimized UX for the gym

This plan implements the APPROVED design from /office-hours with full data model specification, workflow definition, and implementation roadmap.

## What We're Building

**Core Deliverables:**

1. SQLite schema (10 tables: PROGRAMS, WORKOUTS, EXERCISE_SLOTS, EXERCISE_VARIANTS, SET_TEMPLATES, VARIANT_ONE_RM_HISTORY, SESSIONS, SESSION_EXERCISES, SESSION_SETS, plus settings)
2. Session workflow UI (select workout → display warm-ups → guide through working sets → log performance)
3. Variant swap mid-session with automatic weight recalculation
4. 1RM management (update, track history, auto-recalculate future sessions)
5. Program seeding from JSON (4-day training doc → SQLite)
6. Offline sync (local data only, no cloud)

**Success Criteria:**

- App loads 4-day program and displays it
- Session workflow guides through warm-ups and working sets
- Mid-session variant swap recalculates targets instantly
- 1RM update cascades to all future sessions
- 1RM history queryable (6-month strength arc visible)
- Sessions loggable offline, no network required
- Actually usable at the gym

## Architecture: SQLite + Flutter + sqflite

### Technology Stack

- **Framework**: Flutter (Dart)
- **Database**: SQLite (sqflite package)
- **State Management**: Provider or Riverpod (TBD in implementation)
- **Build**: Android APK (primary), iOS IPA (defer)
- **Deployment**: Side-load or GitHub Releases

### Data Model (10 Tables)

**PROGRAMS** — defines a training program (e.g., "4-Day Novice Bodybuilding")

- program_id (PK)
- name, version, description
- created_at, updated_at

**WORKOUTS** — defines a day in a program (e.g., "Day 1 - Lower Strength")

- workout_id (PK), program_id (FK)
- name, day_number, order_in_program, notes

**EXERCISE_SLOTS** — defines an exercise slot in a workout (e.g., "Squat Variant")

- slot_id (PK), workout_id (FK)
- name, slot_order, category

**EXERCISE_VARIANTS** — defines a specific exercise (e.g., "Back Squat", "Front Squat")

- variant_id (PK), slot_id (FK)
- name, description

**SET_TEMPLATES** — defines prescribed sets for a slot (e.g., "3×5 @ 82.5% 1RM")

- set_template_id (PK), slot_id (FK)
- set_number, set_type (warm-up/working/back-off)
- reps_target_min, reps_target_max
- percentage_1rm (NULL if RPE-based)
- rpe_target (NULL if %1RM-based)
- rest_seconds

**VARIANT_ONE_RM_HISTORY** — tracks 1RM per variant over time

- history_id (PK), variant_id (FK)
- weight (lbs), date, notes
- is_current (boolean)

**SESSIONS** — actual workouts logged

- session_id (PK), workout_id (FK)
- date_completed, is_deload (boolean), notes

**SESSION_EXERCISES** — the variant chosen for this session

- session_exercise_id (PK), session_id (FK), slot_id (FK)
- chosen_variant_id (FK)

**SESSION_SETS** — actual performance

- session_set_id (PK), session_exercise_id (FK)
- set_number, reps_completed, weight_lifted
- one_rm_at_session_time (lbs) — historical snapshot
- rpe_actual (1-10), notes, timestamp

**SETTINGS** — app-level configuration

- key (PK), value
- (deload_frequency_weeks, etc.)

### Key Implementation Decisions

1. **Variant-specific 1RMs**: Each variant has its own 1RM history (not shared across variants)
2. **Weight rounding**: All calculated weights round to nearest 5 lbs
3. **Historical snapshots**: SESSION_SETS store the 1RM used at session time (for accurate history)
4. **Deload flagging**: SESSIONS.is_deload marks deload weeks (hardcoded to every 4 weeks for MVP)
5. **Variant swaps mid-session**: chosen_variant_id can change within a session; all calculations use current variant
6. **Warm-up algorithm**: 50% → 70% → 90% of first working set weight
7. **Variant swap with missing 1RM**: Prompt user to estimate, store temporarily, update after session
8. **Incomplete sessions**: Prompt if template calls for N sets but user only does M; allow early stop
9. **Program versioning**: Immutable programs; new versions on update (v1, v2, etc.)
10. **Program seeding**: Load from JSON fixture on first launch, then SQLite is source of truth

## Implementation Roadmap (6 Phases)

### Phase 1: Schema & Foundation

- Create SQLite schema (10 tables)
- Implement schema migrations (sqflite)
- Write seed data (4-day program as JSON)
- Load seed data on first app launch
- Create basic data access layer (DAL)

**Deliverable**: App with populated SQLite database, schema validated

### Phase 2: Session Workflow UI

- Screen: Select workout day
- Screen: Display warm-ups with calculated weights
- Screen: Display working sets with targets
- Screen: Log set (reps, weight, RPE)
- Rest timer between sets
- Completion screen

**Deliverable**: Full session flow from start to finish

### Phase 3: Variant Swap

- Mid-session "choose variant" button
- Recalculate warm-ups and working sets for new variant
- Handle missing 1RM (prompt for estimate)
- Show session record with variant swap noted

**Deliverable**: Variant swaps work smoothly, weights recalculate

### Phase 4: 1RM Management

- Screen: View 1RM history (graphed over time)
- Screen: Update 1RM (record PR)
- Auto-recalculate all future sessions when 1RM updates
- Store historical 1RM snapshot in SESSION_SETS

**Deliverable**: 1RM updates cascade, history is queryable

### Phase 5: Polish & Testing

- Error handling (bad data, edge cases)
- Offline testing (no network)
- UI refinements (button sizes, touch targets for gym use)
- Integration testing (variant swap + 1RM update interaction)

**Deliverable**: App ready for real gym use

### Phase 6: Deploy to Phone

- Build APK via `flutter build apk`
- Side-load to device or GitHub Releases
- Use at gym for 1 week
- Iterate on feedback

**Deliverable**: App on phone, usable in gym

## Risk Analysis

| Risk                                | Impact | Mitigation                                                 |
| ----------------------------------- | ------ | ---------------------------------------------------------- |
| SQLite migration complexity         | High   | Use sqflite's built-in migration system; test on seed data |
| Variant swap + 1RM consistency      | High   | Use transactions; test all combinations                    |
| Offline sync if user changes device | Medium | Document as limitation; defer to Phase 2                   |
| Warm-up algorithm edge cases        | Medium | Test all rep ranges; handle division by zero               |
| Performance with year of data       | Low    | Index session_id, variant_id; profile queries              |

## Testing Strategy

**Unit Tests**:

- Weight calculation (50/70/90% rounding)
- 1RM cascade logic
- Warm-up progression algorithm

**Integration Tests**:

- Variant swap + weight recalculation
- 1RM update + future session recalculation
- Session logging + historical snapshot

**Manual Tests**:

- Offline session (no network)
- Mid-workout variant swap
- 1RM PR entry
- Multi-session 1RM history query

## Dependencies

- `sqflite` (SQLite for Flutter)
- `provider` or `riverpod` (state management — TBD)
- `intl` (date formatting)
- Standard Flutter/Dart libs

No external APIs, no cloud sync.

## Success Metrics

- ✅ App loads program and displays exercises
- ✅ Session workflow: under 3 taps to log a set
- ✅ Variant swap: instant weight recalculation
- ✅ 1RM update: all future sessions recalculate within 100ms
- ✅ User actually uses it at gym for 1 week

## Open for Review

This plan is ready for the full /autoplan review pipeline:

- CEO phase: strategy, scope, competitive positioning
- Design phase: UI/UX, information hierarchy, workflow
- Eng phase: architecture, test coverage, performance
- DX phase: (skip — not a developer tool)

See APPROVED design doc for full problem statement, constraints, and data model detail.
