# Everslot release keep rules (R8). Flutter's own rules are added by the Flutter Gradle plugin.

# flutter_local_notifications serialises scheduled notifications with Gson (generic signatures).
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Flutter references Play Core (deferred components) that the app does not ship.
-dontwarn com.google.android.play.core.**

# Firebase Crashlytics: readable stack traces (mapping file uploaded in release CI, T9.2).
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
