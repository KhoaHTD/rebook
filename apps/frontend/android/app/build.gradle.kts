plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    buildFeatures {
        resValues = true
    }

    namespace = "vn.edu.fpt.book_marketplace"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "vn.edu.fpt.book_marketplace"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Cài song song nhiều bản trên cùng một máy (vd. bản mock và bản nối backend thật để demo):
        //   REBOOK_APP_ID_SUFFIX=.live REBOOK_APP_LABEL="ReBook Live" flutter build apk ...
        // Không đặt biến môi trường → build như cũ (id gốc, tên "ReBook").
        System.getenv("REBOOK_APP_ID_SUFFIX")?.takeIf { it.isNotBlank() }?.let {
            applicationIdSuffix = it
        }
        resValue("string", "app_name", System.getenv("REBOOK_APP_LABEL")?.takeIf { it.isNotBlank() } ?: "ReBook")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
