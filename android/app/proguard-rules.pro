# Flutter engine (needed at runtime)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }

# App model classes (keep all for Firestore/Gson serialization)
-keep class com.cashspark.** { *; }

# Gson serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Firebase Play Core (split APK installation — referenced by Flutter but optional at runtime)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Firebase core components (required for ServiceLoader/reflection-based initialization)
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.FirebaseOptions { *; }
-keep class com.google.firebase.FirebaseException { *; }
-keep class com.google.firebase.components.** { *; }
-keep class com.google.firebase.platforminfo.** { *; }
-keep class com.google.firebase.provider.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Firebase Firestore (keep ExceptionConverter to resolve R8 duplicate class conflict)
-keep class com.google.firebase.firestore.** { *; }
-keep class io.flutter.plugins.firebase.firestore.** { *; }
-keep class io.flutter.plugins.firebase.firestore.utils.ExceptionConverter { *; }

# Firebase Functions
-keep class com.google.firebase.functions.** { *; }

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# AdMob / Google Ads
-keep class com.google.android.gms.ads.** { *; }

# Google Play Services (general)
-keep class com.google.android.gms.** { *; }
