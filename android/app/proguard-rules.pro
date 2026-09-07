# Proguard / R8 Optimization Rules for AuraPlayer

# Keep Flutter Engine and Plugins
-keep class io.flutter.** { *; }
-keep class com.ryanheise.audioservice.** { *; }

# Keep media_kit and libmpv native FFI bindings
-keep class com.alexmercerind.media_kit.** { *; }
-keep class com.alexmercerind.media_kit_video.** { *; }

# Keep SQLite plugin classes
-keep class com.tekartik.sqflite.** { *; }

# Keep native methods and JNI registration
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve line numbers for readable crash stacktraces
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
