# ============================================================
#  Medicare - ProGuard / R8 rules
# ============================================================
#  Applied to release builds when isMinifyEnabled = true.
#  Keep rules below are required by the libraries we use.
# ============================================================

# -------------------------------------------------------------
# Flutter
# -------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# -------------------------------------------------------------
# Stripe SDK
# Stripe relies heavily on reflection (PaymentSheet, 3DS, etc.).
# Keep everything in com.stripe.** and com.reactnativestripesdk.**
# -------------------------------------------------------------
-keep class com.stripe.android.** { *; }
-keep class com.stripe.** { *; }
-keep interface com.stripe.** { *; }
-keepclassmembers class com.stripe.** { *; }
-dontwarn com.stripe.**

# Stripe push provisioning / 3DS2
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.stripe.android.stripe3ds2.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.stripe.android.stripe3ds2.**

# -------------------------------------------------------------
# Jitsi Meet SDK
# Uses React Native under the hood + native modules via reflection.
# -------------------------------------------------------------
-keep class org.jitsi.meet.** { *; }
-keep class org.jitsi.meet.sdk.** { *; }
-keep class com.facebook.react.** { *; }
-keep class com.facebook.hermes.** { *; }
-keep class com.facebook.jni.** { *; }
-keep class com.facebook.soloader.** { *; }
-keepclassmembers class * {
    @com.facebook.react.uimanager.annotations.ReactProp <methods>;
    @com.facebook.react.uimanager.annotations.ReactPropGroup <methods>;
}
-keepclassmembers,includedescriptorclasses class * {
    native <methods>;
}
-dontwarn org.jitsi.meet.**
-dontwarn com.facebook.react.**
-dontwarn com.facebook.hermes.**

# WebRTC (bundled with Jitsi)
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# -------------------------------------------------------------
# Dio / OkHttp / Retrofit ecosystem
# -------------------------------------------------------------
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# -------------------------------------------------------------
# Riverpod / Flutter codegen
# Riverpod runs on the Dart side, but Dart codegen sometimes uses
# reflection-style names that R8 should leave alone.
# -------------------------------------------------------------
-keep class **.provider.** { *; }
-dontwarn riverpod.**

# -------------------------------------------------------------
# Kotlin / Coroutines
# -------------------------------------------------------------
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }

# -------------------------------------------------------------
# AndroidX / Play Core (used by deferred components on some flavors)
# -------------------------------------------------------------
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# -------------------------------------------------------------
# Keep annotations and generic signatures (needed for reflection)
# -------------------------------------------------------------
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable
