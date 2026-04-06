plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

android {
    namespace = "com.retraq.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.retraq.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing: reads from android/key.properties (not committed to git).
    // Create key.properties with:
    //   storePassword=<password>
    //   keyPassword=<password>
    //   keyAlias=retraq
    //   storeFile=<path-to-keystore.jks>
    // Release signing: try key.properties first (local dev), then env vars (CI)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val useReleaseKey = keystorePropertiesFile.exists()
    val useCiSigning = !useReleaseKey && System.getenv("KEYSTORE_BASE64") != null

    if (useReleaseKey) {
        val keystoreProperties = Properties()
        keystoreProperties.load(keystorePropertiesFile.inputStream())
        signingConfigs {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    } else if (useCiSigning) {
        // CI signing from GitHub Actions secrets passed as environment variables.
        // KEYSTORE_BASE64 is decoded to a .jks file by the CI workflow before build.
        signingConfigs {
            create("release") {
                storeFile = file(System.getenv("KEYSTORE_PATH") ?: "release-keystore.jks")
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
                keyAlias = System.getenv("KEY_ALIAS") ?: ""
                keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = if (useReleaseKey || useCiSigning) {
                signingConfigs.getByName("release")
            } else {
                // Fall back to debug keys for development
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
