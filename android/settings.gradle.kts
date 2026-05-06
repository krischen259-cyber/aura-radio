pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val p = properties.getProperty("flutter.sdk")
            require(p != null) { "local.properties: flutter.sdk not set. Run this project with Flutter, or set flutter.sdk to your SDK path." }
            p
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    // LiteRT JNI / flutter_litert_lm AAR expects Kotlin metadata 2.3.x — 2.1.x cannot compile against it.
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false
}

include(":app")
