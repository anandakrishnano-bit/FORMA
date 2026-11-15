# Security Policy & Vulnerability Reporting

FORMA adheres to strict privacy-by-design and security best practices to protect sensitive personal biometric, health, financial, and authentication data.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| 1.x     | :x:                |

---

## Security Architecture & Guarantees

### 1. Zero Knowledge Personal Finances
- **Strict User-Level Isolation**: Personal budgets, transaction records, recurring commitments, and spending insights are saved exclusively under the authenticated user's private collection (`users/{uid}/personal_expenses`).
- **Backend Rules**: Firestore Security Rules strictly prohibit read, write, query, or batch operations by any external user, friend, or group member.
- **Biometric Protection**: Personal expense analytics and ledger views can be locked behind device biometrics (Fingerprint / Face ID / Pin) via `LocalAuthenticationService`.

### 2. Biometric Key Storage & Encryption
- Sensitive credentials—including the user's personal Google Gemini API key—are never committed to version control, never bundled into application assets, and never synchronized to public Firestore documents.
- User API keys are stored exclusively on-device in the Android Keystore using hardware-backed AES encryption (`flutter_secure_storage`).

### 3. Firebase Authentication & Session Security
- Authentication methods (Email/Password, Google Sign-In, and Firebase Phone OTP) are configured with strict rate limiting, verification enforcement, and session revocation checks.
- Account enumeration protections are enabled where supported by the Firebase Auth backend.
- Critical operations (such as deleting an account or changing credentials) require recent authentication (`reauthenticateWithCredential`).

---

## Reporting a Security Vulnerability

If you discover a potential security vulnerability within FORMA, please report it responsibly:

1. **Do not open a public issue.**
2. Send a detailed report to the security maintainers at: `security@forma.fit` (or through GitHub Private Vulnerability Reporting).
3. Please include:
   - Detailed description of the vulnerability.
   - Reproduction steps, proof-of-concept payload, or stack traces.
   - Impact assessment on user privacy or data integrity.
4. Maintainers will acknowledge receipt within 48 hours and work with you on a coordinated disclosure timeline.
