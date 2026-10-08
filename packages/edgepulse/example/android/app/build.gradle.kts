plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.edgepulse.edgepulse_example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    aaptOptions {
        noCompress.add("tflite")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId = "io.github.edgepulse.edgepulse_example"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
    }
}

flutter {
    source = "../.."
}

configurations.all {
    exclude(group = "org.tensorflow", module = "tensorflow-lite-api")
    exclude(group = "org.tensorflow", module = "tensorflow-lite-gpu")
}
