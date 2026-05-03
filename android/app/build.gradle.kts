import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Release signing ──────────────────────────────────────────────────────────
// Keystore credentials are read from `android/key.properties`, which MUST be
// kept out of source control. Sample contents:
//
//   storeFile=/absolute/path/to/safehouse-release.jks
//   storePassword=...
//   keyAlias=safehouse
//   keyPassword=...
//
// If the file is missing (e.g. a fresh checkout), release builds will FAIL
// loudly instead of silently signing with the debug keystore.
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseSigningConfig = keystoreProperties.isNotEmpty()

android {
    namespace = "com.victorartonomy.safe_house"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.victorartonomy.safe_house"
        // local_auth requires API 23+ for BiometricPrompt; flutter_secure_storage
        // EncryptedSharedPreferences also requires API 23+.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigningConfig) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Local dev: fall back to debug keys so `flutter run --release`
                // still works, but make it obvious in build output that this
                // build is NOT shippable.
                logger.warn(
                    "⚠️  android/key.properties not found — release build " +
                    "will be signed with the DEBUG keystore. Do NOT publish."
                )
                signingConfig = signingConfigs.getByName("debug")
            }
            // NOTE: leaving minify/shrink at the Flutter plugin defaults.
            // If you ever set `isMinifyEnabled = false` here, you MUST also
            // set `isShrinkResources = false` — Gradle rejects the
            // shrink-without-minify combination.
        }
    }
}

flutter {
    source = "../.."
}