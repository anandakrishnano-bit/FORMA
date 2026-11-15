# FORMA Public In-App Update System Documentation

This document explains the architecture, release workflow, security practices, and testing procedures for FORMA's GitHub-based in-app update system.

---

## 1. System Overview

FORMA uses **GitHub Releases as its official, public update distribution source**. Users who install FORMA receive future application updates directly within the app without relying on Google Play Store, Firebase App Distribution, or paid distribution platforms.

### Architecture Highlights:
- **Repository Source**: `https://github.com/anandakrishnano-bit/FORMA`
- **Release API Endpoint**: `https://api.github.com/repos/anandakrishnano-bit/FORMA/releases`
- **Release Verification**: Strict SHA-256 hash comparison between downloaded APK and published checksum.
- **Android Integration**: Native Android `FileProvider` (`content://com.forma.app.fileprovider/updates/...`) and `PackageInstaller` via `ACTION_VIEW` intent with `FLAG_GRANT_READ_URI_PERMISSION`.
- **Install Permissions**: Handles Android 8.0+ (API 26) `REQUEST_INSTALL_PACKAGES` permission check and deep-links directly to Android Settings if not yet granted.
- **UI Design System**: Faithful realization of the dark/light modern update screen with custom 3D isometric accent art, expandable markdown changelogs, and real-time streaming byte progress counters.

---

## 2. Release Priority Levels

Every release can define its priority to control how FORMA notifies users:

| Priority | When to Use | User Experience |
| :--- | :--- | :--- |
| **Normal** (`normal`) | Minor bug fixes, UI polishes, non-breaking features | Dismissible modal or subtle settings indicator. User can click "Later" to postpone. |
| **Important** (`important`) | Major new features, performance updates | Highlighted prompt; recommended for optimal experience. |
| **Critical** (`critical`) | Security patches, database schema migrations, breaking API deprecations | **Mandatory & non-dismissible**. The app requires installing this version before proceeding. |

---

## 3. GitHub Repository Configuration & Secrets

### Prerequisites
1. **GitHub Repository**: Ensure the repository `anandakrishnano-bit/FORMA` is public (or accessible with public release downloads).
2. **Workflow Permissions**: In GitHub repository settings under **Settings > Actions > General > Workflow permissions**, select **"Read and write permissions"** so GitHub Actions can publish release tags and attach assets.

### Release Workflow
The release workflow is located at `.github/workflows/release.yml`. It can be triggered in two ways:
1. **Git Tag Push**:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```
2. **GitHub Actions Manual Dispatch**:
   Go to **GitHub > Actions > FORMA Public Release Automation > Run workflow**, enter the tag (e.g. `v1.1.0`), choose priority, and execute.

---

## 4. Release Asset Specifications

Every GitHub Release published by the workflow includes three assets:

1. **`forma-vX.Y.Z.apk`**: The compiled release APK.
2. **`forma-vX.Y.Z.apk.sha256`**: A text file containing the SHA-256 hex digest:
   ```text
   b4c9e782d46e1c2f90117b... forma-v1.1.0.apk
   ```
3. **`release-metadata.json`**: Machine-readable metadata loaded by the FORMA app:
   ```json
   {
     "version": "1.1.0",
     "versionCode": 2,
     "tagName": "v1.1.0",
     "priority": "normal",
     "minSupportedVersion": "1.0.0",
     "apkFileName": "forma-v1.1.0.apk",
     "sha256": "b4c9e782d46e1c2f90117b...",
     "publishedAt": "2026-11-15T12:00:00Z"
   }
   ```

---

## 5. Android Keystore & Permanent Release Signing

> [!IMPORTANT]
> **CRITICAL ANDROID UPDATE & SIGNING RULE:**
> Android strictly forbids installing an APK update over an existing application if the signing certificate does not match (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`).
>
> 1. All published public APK releases must be signed with the **same permanent release certificate**.
> 2. Silent fallback to debug signing is **explicitly disabled** in `android/app/build.gradle.kts`. Release builds will fail immediately with clear instructions if permanent signing credentials are not configured.
> 3. Debug builds (`flutter run` / `assembleDebug`) continue to use the standard Android SDK debug keystore for seamless local development and device testing.

### Step 5.1: Generating Your Permanent Keystore Locally
Run the standard Java `keytool` command locally on your machine (do not commit the resulting `.jks` file):
```bash
keytool -genkey -v -keystore android/forma-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias forma-release-key
```
*Keep this keystore backed up securely in a password manager or offline secure storage. Losing this key will permanently break update installation for all existing users.*

### Step 5.2: Local Configuration (`android/key.properties`)
Create `android/key.properties` (based on `android/key.properties.example`):
```properties
storeFile=forma-release.jks
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyAlias=forma-release-key
keyPassword=<YOUR_KEY_PASSWORD>
```
*(Both `*.jks` and `android/key.properties` are strictly excluded in `.gitignore` and must never be committed to Git).*

### Step 5.3: GitHub Actions Secrets Configuration
To automate release builds on GitHub Actions without committing your keystore, configure the following four Repository Secrets under **GitHub > Repository Settings > Secrets and variables > Actions**:

1. **`FORMA_KEYSTORE_BASE64`**: The base64-encoded string of your `forma-release.jks` file:
   - On Windows (PowerShell):
     ```powershell
     [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/forma-release.jks")) | Set-Clipboard
     ```
   - On macOS/Linux:
     ```bash
     base64 -w 0 android/forma-release.jks | pbcopy
     ```
2. **`FORMA_STORE_PASSWORD`**: Your keystore store password.
3. **`FORMA_KEY_ALIAS`**: Your key alias (e.g., `forma-release-key`).
4. **`FORMA_KEY_PASSWORD`**: Your key password.

The GitHub Actions workflow (`.github/workflows/release.yml`) decodes the keystore only inside the ephemeral runner container, executes the signed build, and securely shreds the keystore and `key.properties` upon completion.

---

## 6. How Users Experience Updates

1. **Automatic Non-Intrusive Background Checks**:
   - Every time FORMA starts, it silently checks GitHub for updates (throttled to at most once every 4 hours to respect API quotas and battery).
   - If a new update is found and not previously dismissed, the update screen appears.
2. **Manual Check via Settings**:
   - Go to **Profile / Settings > App Preferences & System > Software Updates**.
   - Displays current version (`v1.0.0 • Up to date`).
   - Tapping it forces an immediate live GitHub query.
3. **Download & Installation Flow**:
   - User taps **"Update Now"**.
   - Chunked HTTP streaming begins with live speed (MB/s) and byte progress tracking.
   - User can pause/cancel at any time.
   - Upon download completion, SHA-256 hash is computed in background isolates and verified against GitHub.
   - FORMA passes the validated APK file to the native Android Package Installer via `FileProvider`.
   - Android shows the official system installation prompt: *"Do you want to update this app?"*.

---

## 7. Local Testing & Verification

To verify the update system without publishing a live public release:
1. Run all unit tests:
   ```bash
   flutter test test/app_update_system_test.dart
   ```
2. Build the app and deploy to the connected Android device:
   ```bash
   flutter run -d 10BF3H08FM001BT
   ```
3. In the app, navigate to **Settings > Software Updates** and observe the live check and feedback messages.
