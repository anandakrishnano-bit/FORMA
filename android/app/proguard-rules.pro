# Proguard Rules for FORMA (Android Release Build)
# Enforces code shrinking, dead code removal and obfuscation without breaking Flutter plugins.

# Flutter Engine & Framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google & Firebase Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**

# Android Keystore & Secure Storage
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Models & JSON Serialization (Keep property names for schema validation)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Remove debugging logs in release APK/AAB
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}

