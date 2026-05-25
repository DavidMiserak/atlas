import 'package:atlas/data/models/session_review.dart';
import 'package:atlas/providers/session_provider.dart';
import 'package:atlas/screens/session_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeSessionProvider extends SessionProvider {
  _FakeSessionProvider(this._summaries);

  final List<SessionSummary> _summaries;

  @override
  Future<List<SessionSummary>> getAllSessionSummaries() async => _summaries;

  @override
  Future<Set<int>> searchSessionIds(String query) async => {};
}

Widget _buildHarness(SessionProvider provider) {
  return ChangeNotifierProvider<SessionProvider>.value(
    value: provider,
    child: const MaterialApp(home: SessionReviewScreen()),
  );
}

SessionSummary _summary({required int id, required bool isDemo}) {
  return SessionSummary(
    sessionId: id,
    workoutName: 'Day 1: Lower Strength',
    dateCompleted: DateTime(2026, 5, 25),
    exerciseCount: 5,
    totalSetsLogged: 15,
    totalVolume: 4200,
    isDemo: isDemo,
  );
}

void main() {
  testWidgets('shows demo badge for demo session rows', (tester) async {
    final provider = _FakeSessionProvider([_summary(id: 1, isDemo: true)]);

    await tester.pumpWidget(_buildHarness(provider));
    await tester.pumpAndSettle();

    expect(find.text('Demo'), findsOneWidget);
  });

  testWidgets('does not show demo badge for regular sessions', (tester) async {
    final provider = _FakeSessionProvider([_summary(id: 1, isDemo: false)]);

    await tester.pumpWidget(_buildHarness(provider));
    await tester.pumpAndSettle();

    expect(find.text('Demo'), findsNothing);
  });
}
