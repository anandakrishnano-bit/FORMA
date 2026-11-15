import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

// Check environment variables as secondary source (for CI/CD environments)
val envStoreFile = System.getenv("FORMA_STORE_FILE")
val envStorePassword = System.getenv("FORMA_STORE_PASSWORD")
val envKeyAlias = System.getenv("FORMA_KEY_ALIAS")
val envKeyPassword = System.getenv("FORMA_KEY_PASSWORD")

val releaseStoreFilePath = keystoreProperties.getProperty("storeFile") ?: envStoreFile
val releaseStorePassword = keystoreProperties.getProperty("storePassword") ?: envStorePassword
val releaseKeyAlias = keystoreProperties.getProperty("keyAlias") ?: envKeyAlias
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword") ?: envKeyPassword

val hasValidReleaseSigning = !releaseStoreFilePath.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.forma.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.forma.app"
        minSdk = 26
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasValidReleaseSigning) {
                val directFile = file(releaseStoreFilePath!!)
                val rootFile = rootProject.file(releaseStoreFilePath)
                storeFile = if (directFile.exists()) directFile else rootFile
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Enforce signing validation specifically during release packaging tasks
tasks.whenTaskAdded {
    if (name.startsWith("packageRelease") || name.startsWith("validateSigningRelease")) {
        doFirst {
            if (!hasValidReleaseSigning) {
                throw GradleException(
                    "\n====================================================================================\n" +
                    "FORMA BUILD ERROR: Permanent Release Signing configuration is missing!\n\n" +
                    "To build a release APK/AAB, you must configure 'android/key.properties' with:\n" +
                    "  storeFile=<path-to-your-release.jks>\n" +
                    "  storePassword=<your-keystore-password>\n" +
                    "  keyAlias=<your-key-alias>\n" +
                    "  keyPassword=<your-key-password>\n\n" +
                    "Or supply the environment variables: FORMA_STORE_FILE, FORMA_STORE_PASSWORD, FORMA_KEY_ALIAS, FORMA_KEY_PASSWORD.\n" +
                    "Silent debug signing fallback for release builds is strictly prohibited for security.\n" +
                    "====================================================================================\n"
                )
            }
            val directFile = file(releaseStoreFilePath!!)
            val rootFile = rootProject.file(releaseStoreFilePath)
            val actualFile = if (directFile.exists()) directFile else rootFile
            if (!actualFile.exists()) {
                throw GradleException(
                    "\n====================================================================================\n" +
                    "FORMA BUILD ERROR: Keystore file not found at: ${actualFile.absolutePath}\n" +
                    "Please verify the storeFile path in 'android/key.properties'.\n" +
                    "====================================================================================\n"
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
