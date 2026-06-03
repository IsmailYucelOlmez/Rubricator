import groovy.json.JsonSlurper
import java.io.FileInputStream
import java.util.Base64
import java.util.Properties
import org.gradle.api.GradleException

private fun decodeDartDefines(raw: String): MutableMap<String, String> {
    val result = linkedMapOf<String, String>()
    for (entry in raw.split(",")) {
        if (entry.isBlank()) continue
        val decoded = String(Base64.getDecoder().decode(entry), Charsets.UTF_8)
        val separator = decoded.indexOf('=')
        if (separator <= 0) continue
        result[decoded.substring(0, separator)] = decoded.substring(separator + 1)
    }
    return result
}

private fun encodeDartDefines(defines: Map<String, String>): String =
    defines.entries.joinToString(",") { (key, value) ->
        Base64.getEncoder().encodeToString("$key=$value".toByteArray(Charsets.UTF_8))
    }

// Flutter always passes its own dart-defines; merge env.production.json when Supabase keys are missing.
run {
    val requiredKeys = listOf("SUPABASE_URL", "SUPABASE_ANON_KEY")
    val existingRaw = project.findProperty("dart-defines")?.toString().orEmpty()
    val defines =
        if (existingRaw.isNotBlank()) decodeDartDefines(existingRaw) else linkedMapOf()

    if (requiredKeys.any { defines[it].isNullOrBlank() }) {
        val envFile = rootProject.file("../env.production.json")
        if (envFile.exists()) {
            @Suppress("UNCHECKED_CAST")
            val env = JsonSlurper().parseText(envFile.readText()) as Map<String, Any>
            env.forEach { (key, value) ->
                val text = value?.toString()?.trim().orEmpty()
                if (text.isNotEmpty()) defines[key] = text
            }
            project.extensions.extraProperties["dart-defines"] = encodeDartDefines(defines)
            logger.lifecycle(
                "Merged ${env.size} entries from ${envFile.name} into dart-defines.",
            )
        } else if (
            gradle.startParameter.taskNames.any { task ->
                task.contains("Release", ignoreCase = true) ||
                    task.contains("AppBundle", ignoreCase = true) ||
                    task.contains("assembleRelease", ignoreCase = true) ||
                    task.contains("bundleRelease", ignoreCase = true)
            }
        ) {
            throw GradleException(
                "Missing ${envFile.absolutePath}. " +
                    "Copy env.example.json to env.production.json, then build with:\n" +
                    "flutter build appbundle --release --dart-define-from-file=env.production.json",
            )
        }
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rubricator"
    compileSdk = flutter.compileSdkVersion
    buildToolsVersion = "35.0.0"
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rubricator"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        release {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException("Missing android/key.properties for release signing.")
            }
            signingConfig = signingConfigs.getByName("release")
        }
    }

}

flutter {
    source = "../.."
}
