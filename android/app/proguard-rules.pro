# ── Flutter engine ───────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── Firebase (Core / Auth / Firestore / Analytics / Crashlytics) ──────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
# Crashlytics needs line numbers + source file for readable stack traces.
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,Exceptions
-keep class com.google.firebase.crashlytics.** { *; }

# ── Google Mobile Ads (dormant in v1, kept so a later enable is clean) ─
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ── RevenueCat (purchases_flutter) ───────────────────────────────────
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# ── Play Billing ─────────────────────────────────────────────────────
-keep class com.android.billingclient.api.** { *; }
-dontwarn com.android.billingclient.api.**

# ── Kotlin / coroutines ─────────────────────────────────────────────
-dontwarn kotlin.**
-dontwarn kotlinx.**
-keepclassmembers class kotlin.Metadata { *; }

# ── Keep annotated-for-keep classes and native methods ──────────────
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
