# ─── Flutter Engine ──────────────────────────────────────
# The Flutter engine must be fully kept for runtime JNI calls.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ─── Kotlin ──────────────────────────────────────────────
# Keep Kotlin metadata and coroutines used by plugins.
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature, Exceptions
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleAnnotations, RuntimeInvisibleParameterAnnotations
-keepattributes SourceFile, LineNumberTable
-keep class kotlin.Metadata { *; }
-keep class kotlin.coroutines.** { *; }
-dontwarn kotlin.**

# ─── Firebase Core ─────────────────────────────────────
# Firebase uses ServiceLoader and reflection for component initialization.
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.FirebaseOptions { *; }
-keep class com.google.firebase.FirebaseException { *; }
-keep class com.google.firebase.FirebaseNetworkException { *; }
-keep class com.google.firebase.FirebaseTooManyRequestsException { *; }
-keep class com.google.firebase.components.** { *; }
-keep class com.google.firebase.platforminfo.** { *; }
-keep class com.google.firebase.provider.** { *; }
-keep class com.google.firebase.internal.** { *; }
-keep class com.google.firebase.tracing.** { *; }
-keep class com.google.firebase.datatransport.** { *; }
-keep class com.google.firebase.installations.** { *; }
-keep class * extends com.google.firebase.components.ComponentRegistrar { *; }
-dontwarn com.google.firebase.**

# ─── Firebase Auth ─────────────────────────────────────
# All Firebase Auth native classes must be kept for credential exchange,
# token refresh, and method channel operations to work in release builds.
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.auth.internal.** { *; }
-keep class com.google.firebase.auth.api.** { *; }
-keep class * extends com.google.firebase.auth.AuthCredential { *; }
-keepclassmembers class * extends com.google.firebase.auth.AuthCredential { *; }
-keep class * extends com.google.firebase.auth.ActionCodeSettings { *; }
-keep class * extends com.google.firebase.auth.PhoneAuthProvider { *; }
-keep class com.google.firebase.auth.FirebaseAuth { *; }
-keep class com.google.firebase.auth.FirebaseUser { *; }
-keep class com.google.firebase.auth.UserInfo { *; }
-keep class com.google.firebase.auth.AuthResult { *; }
-keep class com.google.firebase.auth.GetTokenResult { *; }
-keep class com.google.firebase.auth.SignInMethodQueryResult { *; }
-keep class com.google.firebase.auth.AdditionalUserInfo { *; }
-keep class com.google.firebase.auth.EmailAuthProvider { *; }
-keep class com.google.firebase.auth.EmailAuthCredential { *; }
-keep class com.google.firebase.auth.GoogleAuthProvider { *; }
-keep class com.google.firebase.auth.OAuthProvider { *; }
-keep class com.google.firebase.auth.ActionCodeSettings { *; }
-keep class com.google.firebase.auth.UserProfileChangeRequest { *; }
-dontwarn com.google.firebase.auth.**

# ─── firebase_auth Flutter Plugin (Android-side) ────────
# These classes bridge Dart method channels to native Firebase Auth calls.
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin { *; }
-keep class io.flutter.plugins.firebase.auth.FlutterFirebaseAuthUser { *; }
-keep class io.flutter.plugins.firebase.auth.GeneratedAndroidReferrerPlugin { *; }
-keep class io.flutter.plugins.firebase.auth.PigeonParser { *; }
-dontwarn io.flutter.plugins.firebase.auth.**

# ─── Firebase Firestore (CRITICAL for snapshot listeners) ─
# Firestore uses method channels and native callbacks for snapshot listeners.
# All classes must be kept to prevent silent failures in real-time streams.
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.firestore.core.** { *; }
-keep class com.google.firebase.firestore.local.** { *; }
-keep class com.google.firebase.firestore.model.** { *; }
-keep class com.google.firebase.firestore.remote.** { *; }
-keep class com.google.firebase.firestore.util.** { *; }
-keep class com.google.firebase.firestore.auth.** { *; }
-keep class com.google.firebase.firestore.internal.** { *; }
-keep class * extends com.google.firebase.firestore.EventListener { *; }
-keep class * implements com.google.firebase.firestore.EventListener { *; }
-dontwarn com.google.firebase.firestore.**

# ─── cloud_firestore Flutter Plugin (Android-side) ──────
# These classes bridge Dart method channels to native Firestore calls.
-keep class io.flutter.plugins.firebase.firestore.** { *; }
-keep class io.flutter.plugins.firebase.firestore.utils.ExceptionConverter { *; }
-keep class io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin { *; }
-keep class io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestoreQuery { *; }
-keep class io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestoreCollectionReference { *; }
-keep class io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestoreDocumentReference { *; }
-keep class io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestoreTransaction { *; }
-keep class io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestoreWriteBatch { *; }
-keep class io.flutter.plugins.firebase.firestore.stream.** { *; }
-keep class io.flutter.plugins.firebase.firestore.callbacks.** { *; }
-dontwarn io.flutter.plugins.firebase.firestore.**

# ─── Firebase Storage ───────────────────────────────────
-keep class com.google.firebase.storage.** { *; }
-keep class io.flutter.plugins.firebase.storage.** { *; }
-dontwarn com.google.firebase.storage.**

# ─── Firebase Functions ─────────────────────────────────
-keep class com.google.firebase.functions.** { *; }
-keep class io.flutter.plugins.firebase.functions.** { *; }
-dontwarn com.google.firebase.functions.**

# ─── Firebase Crashlytics ───────────────────────────────
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.crashlytics.internal.** { *; }
-keepattributes *Annotation*
-keepattributes SourceFile, LineNumberTable
-dontwarn com.google.firebase.crashlytics.**

# ─── Firebase Messaging (FCM) ──────────────────────────
-keep class com.google.firebase.messaging.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService { *; }
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin { *; }
-dontwarn com.google.firebase.messaging.**

# ─── Firebase Dynamic Links / App Indexing ──────────────
-keep class com.google.firebase.dynamiclinks.** { *; }
-dontwarn com.google.firebase.dynamiclinks.**

# ─── Google Sign-In ─────────────────────────────────────
# All Google Sign-In native classes must be kept for OAuth flow.
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.signin.** { *; }
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keep class com.google.android.gms.auth.api.identity.** { *; }
-dontwarn com.google.android.gms.auth.**

# ─── google_sign_in Flutter Plugin (Android-side) ────────
# These classes bridge Dart method channels to native Google Sign-In.
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class io.flutter.plugins.googlesignin.GoogleSignInPlugin { *; }
-dontwarn io.flutter.plugins.googlesignin.**

# ─── Google Play Services (general) ─────────────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ─── AdMob / Google Ads ─────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ─── Google Play Core (split APK / in-app updates) ───────
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ─── Connectivity Plus (network listener) ────────────────
-keep class io.flutter.plugins.connectivity.** { *; }
-keep class io.flutter.plugins.connectivity_plus.** { *; }
-dontwarn io.flutter.plugins.connectivity.**

# ─── Flutter Secure Storage ──────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.it_nomads.fluttersecurestorage.cipher.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ─── Image Picker ──────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# ─── Share Plus ────────────────────────────────────────
-keep class esimeneine.flutter_share_plus.** { *; }
-dontwarn esimeneine.flutter_share_plus.**

# ─── URL Launcher ──────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# ─── Flutter Local Notifications ─────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ─── Path Provider ───────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ─── Shared Preferences ─────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# ─── Gson (used by some plugins) ─────────────────────────
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-dontwarn com.google.gson.**

# ─── OkHttp (used by Firebase) ────────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ─── Bouncy Castle (used by some crypto plugins) ──────────
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ─── AndroidX ───────────────────────────────────────────
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# ─── Any reflection/reachability ─────────────────────────
-keepattributes RuntimeVisibleAnnotations, RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations, RuntimeInvisibleParameterAnnotations
-keepattributes EnclosingMethod
-keepattributes InnerClasses
