# Keep generic type info for Gson (used by flutter_local_notifications)
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# Flutter engine
-keep class io.flutter.** { *; }

# SQLCipher
-keep class net.zetetic.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Play Core (deferred components — referenced by Flutter engine)
-dontwarn com.google.android.play.core.**

# RevenueCat
-keep class com.revenuecat.** { *; }

# Preserve source file names and line numbers for readable stack traces
-keepattributes SourceFile,LineNumberTable
