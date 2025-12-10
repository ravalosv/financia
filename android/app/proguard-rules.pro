# Google ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Flutter internals
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
 -keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Google Play Services (optional, safe to include)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Core / SplitInstall (for deferred components references)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
