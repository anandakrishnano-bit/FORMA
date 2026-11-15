import 'package:flutter_test/flutter_test.dart';
import 'package:forma/core/legal/terms_data.dart';

void main() {
  group('FormaTermsData', () {
    test('currentVersion and metadata are valid', () {
      expect(FormaTermsData.currentVersion, isNotEmpty);
      expect(FormaTermsData.effectiveDate, isNotEmpty);
      expect(FormaTermsData.lastUpdatedDate, isNotEmpty);
      expect(FormaTermsData.fullTermsMarkdown, isNotEmpty);
    });

    test('full terms contain required sections', () {
      final md = FormaTermsData.fullTermsMarkdown;
      expect(md.contains('1. About FORMA'), isTrue);
      expect(md.contains('2. Eligibility and accounts'), isTrue);
      expect(md.contains('3. Health, fitness and nutrition information'), isTrue);
      expect(md.contains('4. AI-powered features'), isTrue);
      expect(md.contains('5. Personal expenses and shared expenses'), isTrue);
      expect(md.contains('6. Friends, groups and sharing'), isTrue);
      expect(md.contains('7. Your data and privacy'), isTrue);
      expect(md.contains('8. Third-party services'), isTrue);
      expect(md.contains('9. Intellectual property'), isTrue);
      expect(md.contains('10. Acceptable use'), isTrue);
      expect(md.contains('11. Availability and changes'), isTrue);
      expect(md.contains('12. Account suspension and deletion'), isTrue);
      expect(md.contains('13. Limitation of liability'), isTrue);
      expect(md.contains('14. Changes to these Terms'), isTrue);
      expect(md.contains('15. Governing law'), isTrue);
      expect(md.contains('16. Contact'), isTrue);
    });

    test('isAcceptanceRequired detects missing or older versions', () {
      expect(FormaTermsData.isAcceptanceRequired(null), isTrue);
      expect(FormaTermsData.isAcceptanceRequired(''), isTrue);
      expect(FormaTermsData.isAcceptanceRequired('2025-01-01'), isTrue);
      expect(FormaTermsData.isAcceptanceRequired(FormaTermsData.currentVersion), isFalse);
    });
  });
}
