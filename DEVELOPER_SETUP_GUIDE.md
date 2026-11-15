# FORMA — Developer Setup, Deployment & Handover Guide

This guide details the complete process for configuring, deploying, and verifying **FORMA** across Firebase, Google Cloud Functions, and Android.

---

## 1. Architecture & Credential Boundary

```
[Android Client (APK/AAB)]
   │  • Authenticated Firebase Token (App Check enforced)
   │  • ZERO Gemini API Keys
   │  • Keystore-backed AES local storage
   ▼
[Firebase Cloud Functions Gateway (TypeScript)]
   │  • Google Cloud Secret Manager (GEMINI_API_KEY)
   │  • User Context Sanitization & Token Limits
   ▼
[Google Gemini & External Providers (wger / Open Food Facts)]
```

> [!IMPORTANT]
> **Ordinary users are never asked for developer credentials.** The project owner configures the backend once. Ordinary users simply download the app, create an account, and complete the 10-step first-launch walkthrough.

---

## 2. Required Software & Accounts

1. **Flutter SDK** (v3.27+ with Dart 3.2+)
2. **Node.js** (v18 or v20 LTS) & npm
3. **Firebase CLI** (`npm install -g firebase-tools`)
4. **Google Cloud / Firebase Project** (Blaze plan required for external network egress to Gemini/wger)
5. **Google AI Studio Account** (for Gemini API credential)

---

## 3. Step-by-Step Setup Instructions

### Step 3.1: Firebase Project Configuration
1. Log in to Firebase:
   ```bash
   firebase login
   ```
2. Initialize or connect the existing project:
   ```bash
   firebase use --add forma-fitness-prod
   ```
3. Deploy Firestore and Storage security rules:
   ```bash
   firebase deploy --only firestore:rules,storage:rules
   ```

### Step 3.2: Gemini Credential & Cloud Functions Deployment
1. Navigate to the backend directory:
   ```bash
   cd firebase/functions
   npm install
   ```
2. Store the Gemini API key securely in Google Cloud Secret Manager:
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   # Paste your Google AI Studio API Key when prompted
   ```
3. Deploy the Cloud Functions:
   ```bash
   npm run build
   firebase deploy --only functions
   ```
   *Deploys:*
   - `askPersonalTrainer` (Callable with context injection)
   - `generateDailySummary` (Pub/Sub scheduled daily recap)
   - `searchExternalCatalogue` (Secure wger & Open Food Facts proxy)

### Step 3.3: Android Build Configuration
1. Ensure [`android/local.properties`](file:///c:/Users/anand/Downloads/Antigravity%20projects/Gym%20Comapnion%20app/android/local.properties) points to your local Android SDK:
   ```properties
   sdk.dir=C:\\Users\\anand\\AppData\\Local\\Android\\Sdk
   flutter.sdk=C:\\flutter
   ```
2. Generate a signed release Android App Bundle (AAB):
   ```bash
   flutter build appbundle --release
   ```
   *ProGuard code shrinking, resource optimization, and log stripping are pre-configured in `android/app/proguard-rules.pro`.*

---

## 4. Verification & Diagnostics

To verify backend connectivity without inspecting raw logs, navigate in the app to:
**Profile → Backend Diagnostics** (`/developer-diagnostics`).

The diagnostic suite automatically tests:
- Firebase Core initialization
- Firebase Authentication gateway
- Cloud Firestore deny-by-default rules
- Cloud Functions & Gemini connectivity
- Android Notification Channels
- SQLite workout crash recovery snapshot tables

---

## 5. First-Launch Ordinary User Walkthrough

When an ordinary user installs FORMA, they are presented with a clean 10-step onboarding sequence ([`onboarding_flow_screen.dart`](file:///c:/Users/anand/Downloads/Antigravity%20projects/Gym%20Comapnion%20app/lib/features/authentication/screens/onboarding_flow_screen.dart)):

1. **Welcome:** App value proposition without technical or AI jargon.
2. **Create Account:** Email & password registration.
3. **Basic Profile:** Display name (no compulsory photo).
4. **Units:** Metric vs Imperial.
5. **Workout Days:** Day chips (Mon–Sun).
6. **Habits:** Single initial starter habit (e.g., *Drink 3L Water*).
7. **Nutrition Preferences:** Regional Indian food intro without restrictive calorie targets.
8. **Notification Permissions:** Timezone-aware reminders & quiet hours setup.
9. **Privacy & Sharing:** Clear explanation of private-by-default records.
10. **Finish:** Enters the main Home dashboard directly.

