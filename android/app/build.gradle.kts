import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.vehicle_tracker"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Actualizamos ambos a JavaVersion.VERSION_17 para que coincidan con Kotlin
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // ID Oficial de tu app en Google Play
        applicationId = "com.vehio.mobile"
        // Forzamos targetSdk a 36 cumpliendo con políticas de Google Play 2026
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: System.getenv("CM_KEY_ALIAS")
                ?: System.getenv("FMM_KEY_ALIAS")
            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: System.getenv("CM_KEY_PASSWORD")
                ?: System.getenv("FMM_KEY_PASSWORD")
            val storeFilePath = keystoreProperties.getProperty("storeFile")
                ?: System.getenv("CM_KEYSTORE_PATH")
                ?: System.getenv("FMM_KEYSTORE_PATH")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
                ?: System.getenv("CM_KEYSTORE_PASSWORD")
                ?: System.getenv("FMM_KEYSTORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
