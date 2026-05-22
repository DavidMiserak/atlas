import 'package:atlas/screens/set_logging_screen.dart';
import 'package:atlas/screens/widgets/rest_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildWarmupSetConfigs', () {
    test('matches program spec rest guidance and reps', () {
      final configs = buildWarmupSetConfigs(150);

      expect(configs.length, 3);

      expect(configs[0].reps, 8);
      expect(configs[0].targetRestSeconds, 120);
      expect(configs[0].rangeLabel, '1:00-2:00');

      expect(configs[1].reps, 4);
      expect(configs[1].targetRestSeconds, 180);
      expect(configs[1].rangeLabel, '2:00-3:00');

      expect(configs[2].reps, 2);
      expect(configs[2].targetRestSeconds, 150);
      expect(configs[2].rangeLabel, 'See Working Set');
      expect(configs[2].guidanceText, contains('You can skip anytime'));
    });
  });

  group('RestTimer', () {
    testWidgets('shows guidance text and skip is immediately available',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestTimer(
              restSeconds: 120,
              guidanceText: 'Recommended rest: 1:00-2:00. You can skip anytime.',
              onComplete: _noop,
            ),
          ),
        ),
      );

      expect(find.text('Recommended rest: 1:00-2:00. You can skip anytime.'),
          findsOneWidget);

      final skipButton =
          tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Skip'));
      expect(skipButton.onPressed, isNotNull);
    });

    testWidgets('auto-completes at target rest time', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestTimer(
              restSeconds: 2,
              onComplete: () => completed++,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      expect(completed, 1);
    });
  });
}

void _noop() {}
