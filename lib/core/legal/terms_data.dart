/// Static constants, metadata, and full legal text for FORMA Terms and Conditions.
/// Bundled locally to ensure 100% offline access at all times.
class FormaTermsData {
  static const String currentVersion = '2026-11-15';
  static const String effectiveDate = '15 November 2026';
  static const String lastUpdatedDate = '15 November 2026';

  static const String fullTermsMarkdown = '''
# FORMA
## Terms and Conditions

**Effective date:** $effectiveDate  
**Last updated:** $lastUpdatedDate

Welcome to FORMA. These Terms and Conditions govern your access to and use of the FORMA application and its associated services.

By creating an account or using FORMA, you agree to these Terms. If you do not agree, please do not use the application.

---

### 1. About FORMA

FORMA is a personal lifestyle and activity management application that brings together:

- Workout planning and activity tracking.
- Nutrition and food logging.
- Habit tracking.
- Personal expense management.
- Friends, groups and activity sharing.
- Activity summaries and intelligent insights.
- Optional integrations with supported health and fitness services.

Features may change, improve, or become unavailable as the application develops.

---

### 2. Eligibility and accounts

You must meet the minimum age requirements applicable to your location to use FORMA.

If you are under the age of legal majority, you must have parental or guardian consent wherever required by applicable law.

You agree to:

- Provide accurate account information.
- Keep your login credentials secure.
- Maintain control over your account.
- Notify us if you believe your account has been accessed without permission.
- Avoid creating accounts for impersonation or fraudulent purposes.

You are responsible for activity performed through your account, subject to applicable law.

---

### 3. Health, fitness and nutrition information

FORMA provides tools for recording and understanding personal activity, exercise, nutrition and wellness information.

FORMA is not a medical service and does not provide medical diagnosis, treatment or emergency assistance.

- Workout suggestions are intended for general fitness and activity planning.
- Nutrition information may depend on food databases, serving sizes and user-entered information.
- Activity measurements may depend on your device and connected services.
- AI-generated insights may contain inaccuracies and should not be treated as verified medical advice.

Always use your own judgment when making decisions about exercise, food and health.

Do not use FORMA as a substitute for medical care.

---

### 4. AI-powered features

Some FORMA features may use third-party artificial intelligence services.

If you enable these features, you may be asked to provide your own API credentials for supported services.

You agree that:

- You are responsible for the API credentials you provide.
- Third-party AI services may have their own terms, privacy policies and usage limits.
- AI-generated responses may be incomplete or inaccurate.
- AI-generated content should be reviewed before being relied upon.
- FORMA does not guarantee the accuracy or availability of AI-generated content.

---

### 5. Personal expenses and shared expenses

FORMA provides tools to record personal expenses, budgets and shared expense arrangements.

These tools are for tracking and calculating financial information only.

FORMA does not itself transfer money, process payments, provide banking services or guarantee that another participant will reimburse you.

You are responsible for checking expense entries, participant allocations and settlement records.

Your personal expenses and budgets are private unless you explicitly choose to share information through a supported feature.

---

### 6. Friends, groups and sharing

FORMA may allow you to connect with other users, join groups and share selected activity information.

You agree to:

- Respect other users.
- Share only information you are comfortable sharing.
- Avoid harassment, impersonation, spam or abusive behaviour.
- Respect other users' privacy.
- Not attempt to access another user's private information.

Some information, including health records, nutrition logs and personal expenses, should remain private unless you explicitly choose otherwise through an available feature.

We may restrict accounts that misuse social features or violate these Terms.

---

### 7. Your data and privacy

Your use of FORMA is also governed by our Privacy Policy.

The Privacy Policy explains what information is collected, how it is used, how connected services work, and how you can exercise your privacy rights.

You are responsible for ensuring that information you submit or share is appropriate and that you have permission to share information belonging to others.

---

### 8. Third-party services

FORMA may integrate with third-party platforms, services, APIs and devices.

These services may have separate terms, privacy policies, availability requirements and limitations.

We do not control third-party services and cannot guarantee their continued availability or accuracy.

Your use of those services is also subject to their applicable terms.

---

### 9. Intellectual property

FORMA's application, branding, logos, interface design and original content are protected by applicable intellectual property laws.

You may use the application for its intended personal purposes.

You must not:

- Copy or redistribute proprietary portions of FORMA without permission.
- Misuse FORMA's branding or identity.
- Reverse engineer or interfere with the application except where permitted by applicable law.
- Use FORMA to violate another person's intellectual property rights.

Open-source components remain subject to their respective licences.

---

### 10. Acceptable use

You agree not to:

- Use FORMA for unlawful purposes.
- Attempt to compromise its security.
- Interfere with its normal operation.
- Access accounts or data without authorization.
- Upload malicious files or harmful content.
- Abuse services, APIs or application features.
- Misrepresent your identity or impersonate another person.

---

### 11. Availability and changes

We aim to keep FORMA available and reliable, but uninterrupted service cannot be guaranteed.

Features may be updated, modified, suspended or discontinued.

We may introduce new functionality, improve existing features or change how certain services operate.

Important changes to these Terms will be communicated through an appropriate application notice or other suitable method.

---

### 12. Account suspension and deletion

You may stop using FORMA at any time.

Where supported, you may request account deletion through the application.

We may suspend or restrict access when necessary to protect users, maintain security, investigate misuse or comply with applicable law.

Account deletion and data retention will be handled according to the Privacy Policy and applicable legal requirements.

---

### 13. Limitation of liability

To the extent permitted by applicable law, FORMA is provided on an as-available basis.

We do not guarantee that all information, measurements, recommendations or third-party integrations will always be accurate, complete or available.

Nothing in these Terms excludes rights or protections that cannot legally be excluded.

To the extent permitted by law, we are not responsible for indirect or consequential losses arising from use of the application.

---

### 14. Changes to these Terms

We may revise these Terms as FORMA develops.

The latest version and its effective date will be available within the application.

Where required, we will request your acceptance of material changes before you continue using affected services.

---

### 15. Governing law

These Terms are governed by the applicable laws of India, subject to any mandatory consumer protection and other legal rights that apply in your jurisdiction.

Disputes will be handled by the competent courts or authorities as determined by applicable law.

---

### 16. Contact

For questions about these Terms, contact:

**FORMA Support**  
Refer to the official developer contact details in the FORMA application settings.

---

**FORMA**  
Make every day count.
''';

  /// Determines if an authenticated user must review or re-accept the current terms.
  static bool isAcceptanceRequired(String? userAcceptedVersion) {
    if (userAcceptedVersion == null || userAcceptedVersion.trim().isEmpty) {
      return true;
    }
    return userAcceptedVersion.trim() != currentVersion;
  }
}
