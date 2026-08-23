# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Play Core (deferred components / install referrer)
-dontwarn com.google.android.play.core.**

# Gson / JSON used by plugins
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Rive / JNI
-keep class app.rive.runtime.** { *; }
-keep class app.rive.** { *; }
-dontwarn app.rive.**
