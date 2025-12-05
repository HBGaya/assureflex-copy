# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Secure Storage - IMPORTANT for token saving!
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }
-keepclassmembers class * extends androidx.security.crypto.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Messaging - Token ke liye zaroori!
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keepclassmembers class com.google.firebase.messaging.** { *; }

# Dio HTTP Client
-keep class io.flutter.plugins.** { *; }

# Gson
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Keep your data models
-keep class com.assureflex.assureflex.** { *; }
-keepclassmembers class com.assureflex.assureflex.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Video Player
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Keep classes with special annotations
-keepattributes RuntimeVisibleAnnotations
-keep class * {
#    @androidx.annotation.Keep *;
}

# Preserve line number information for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Google Play Core - FIX FOR R8 ERROR
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }