import 'package:atlas/utils/variant_description_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowVariantDescription', () {
    test('hides null and empty descriptions', () {
      expect(shouldShowVariantDescription('Back Squat', null), isFalse);
      expect(shouldShowVariantDescription('Back Squat', ''), isFalse);
      expect(shouldShowVariantDescription('Back Squat', '   '), isFalse);
    });

    test('hides description that only repeats the variant name', () {
      expect(
        shouldShowVariantDescription('Back Squat', 'back squat'),
        isFalse,
      );
    });

    test('shows enriched description', () {
      expect(
        shouldShowVariantDescription(
          'Back Squat',
          'Primary: quads, glutes, hamstrings — barbell',
        ),
        isTrue,
      );
    });
  });
}
