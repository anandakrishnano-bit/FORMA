# Changelog

All notable changes to the FORMA project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2026-11-15

### Added
- **Android Home Screen Widgets**:
  - Native Material 3 AppWidgets for Daily Activity, Workout Plan, and Budget Balance with direct deep-linking capabilities.
  - Bridge service `HomeWidgetService` for real-time synchronization between Flutter and Android `AppWidgetProvider`.
- **Activity Calendar**:
  - Full-screen historical monthly calendar visualization with 5-dot semantic day badges:
    - Workout (Coral `#F27689`)
    - Nutrition (Gold `#FFC443`)
    - Habits (Icy Blue `#C5D0DE`)
    - Steps & Cardio (Sage Green `#9CAF88`)
    - Budget & Expenses (Charcoal `#171719`)
  - Interactive day breakdown sheets displaying individual sessions, macro breakdowns, and itemized expenses.
- **Customizable Home Screen**:
  - Live preview and drag-and-drop card reordering for all 8 home dashboard cards.
  - Persistent user preference storage with dual local SharedPreferences and remote Firestore synchronization.
- **Universal Global Search**:
  - Integrated full-catalog search across exercises, foods, recipes, workout logs, nutrition history, habits, and expenses.
  - Debounced queries, filter pills, and search history persistence.
- **Universal Quick-Add Action Hub**:
  - Rotating floating action button accessible globally across all navigation tabs.
  - Speed-dial bottom sheet for rapid logging of workouts, meals, habits, personal expenses, shared expenses, and water intake.
- **Smart Spending Insights**:
  - Weekly and monthly burn-rate analytics, dynamic spending trend charts, and category distribution meters.
  - Automated detection of recurring grocery and fitness subscriptions.
- **Weekly Intelligence Report ("Your Week in FORMA")**:
  - Automated end-of-week performance review aggregating volume, cardiovascular steps, macro consistency, and budget adherence.
  - Editorial Gemini AI coaching synthesis with deterministic athletic fallback.
- **Dynamic Workout App Icons**:
  - Android activity aliases allowing custom launcher icons (Default, Chest, Back, Legs, Arms, Rest Day) with runtime switching.
- **Lock Screen Live Workout Status**:
  - Android 16 Live Updates notification integration (`NotificationCompat.Builder` with chronometer and live progress metrics).

### Fixed
- **Friends Tab Cold Start Race Condition**:
  - Resolved timing defect where Friends list failed to load on cold start prior to visiting Challenges by converting repository streams to reactively listen to `authStateChanges()`.
- **Predictive Back Navigation**:
  - Complete Android 16 predictive back gesture support throughout navigation stacks and modals.
- **Portion Size & Expense Calculations**:
  - Full minor-unit integer precision for financial splits and dynamic portion scaling for nutrition.

---

## [1.0.0] - Initial Release
- Core fitness logging, nutrition tracking, and habit streaks.
- Firebase Authentication with Email, Google Sign-In, and Phone OTP.
- Cloud Firestore real-time synchronization and offline caching.
