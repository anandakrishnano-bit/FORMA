# Contributing to FORMA

Thank you for your interest in contributing to **FORMA**! We welcome bug fixes, documentation improvements, architectural optimizations, and feature enhancements.

## Development Workflow

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.24.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.5.0`)
- [Android Studio](https://developer.android.com/studio) / Android SDK (API 34+ recommended, API 36 supported)
- Java Development Kit (JDK 17)

### Local Environment Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/anandakrishnano-bit/FORMA.git
   cd FORMA
   ```
2. Copy environment template and configure local variables:
   ```bash
   cp .env.example .env
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Verify code quality and automated test suite:
   ```bash
   dart format --output=none --set-exit-if-changed .
   flutter analyze --no-fatal-infos
   flutter test
   ```

---

## Coding Standards & Architectural Guidelines

- **Zero Fake Data Policy**: Never introduce hardcoded mock statistics, fake health data, or fabricated financial numbers into production features. All calculations must be derived from genuine user models.
- **Brand Palette Consistency**: Adhere strictly to the established design system tokens in `FormaColors`:
  - Background Warm Cream: `#F5F1E9`
  - Deep Charcoal: `#171719`
  - Athletic Coral: `#F27689`
  - Golden Yellow: `#FFC443`
  - Soft Icy Blue: `#C5D0DE`
  - Step Sage Green: `#9CAF88`
- **State Management**: Use `flutter_riverpod` with immutable models and explicit state providers.
- **Privacy & Security**: Never commit API keys, service account JSON files, or personal credentials.

---

## Pull Request Guidelines

1. Create a feature branch: `git checkout -b feature/your-feature-name`.
2. Ensure all unit and widget tests pass: `flutter test`.
3. Verify static analysis has zero errors or warnings: `flutter analyze`.
4. Ensure code adheres to standard formatting: `dart format .`.
5. Open a Pull Request targeting `master` with a concise summary of changes and accompanying test coverage.
