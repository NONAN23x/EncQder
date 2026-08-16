import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use(::load)
    }
}
val requiredSigningProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingSigningProperties = requiredSigningProperties.filter {
    keystoreProperties.getProperty(it).isNullOrBlank()
}
if (keystorePropertiesFile.exists() && missingSigningProperties.isNotEmpty()) {
    throw GradleException(
        "android/key.properties requests release signing but is missing: " +
            missingSigningProperties.joinToString(", "),
    )
}
val hasReleaseSigning = keystorePropertiesFile.exists()
val releaseKeystoreFile = if (hasReleaseSigning) {
    rootProject.file(keystoreProperties.getProperty("storeFile"))
} else {
    null
}
if (releaseKeystoreFile != null && !releaseKeystoreFile.isFile) {
    throw GradleException("Release keystore not found: ${releaseKeystoreFile.absolutePath}")
}

android {
    namespace = "com.nonanTech.EncQder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseKeystoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.nonanTech.EncQder"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
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

// Flutter keeps its conventional app-release.apk name for discovery. Keep
// that file and provide a user-facing EncQder-named copy beside it.
tasks.configureEach {
    if (name == "assembleRelease") {
        doLast {
            val outputDirectory = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
            // Flutter copies the finalized Gradle APK into flutter-apk only
            // after assembleRelease returns, so read the current build from
            // Gradle's APK directory rather than copying a stale prior output.
            val defaultApk = layout.buildDirectory
                .file("outputs/apk/release/app-release.apk")
                .get()
                .asFile
            if (defaultApk.isFile) {
                defaultApk.copyTo(
                    outputDirectory.resolve("EncQder-release.apk"),
                    overwrite = true,
                )
            }
        }
    }
}
