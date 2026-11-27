import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}

val releaseStoreFile = file("keystore.jks")
val releaseStorePassword = localProperties.getProperty("storePassword")
val releaseKeyAlias = localProperties.getProperty("keyAlias")
val releaseKeyPassword = localProperties.getProperty("keyPassword")
val hasReleaseSigning = releaseStoreFile.exists() &&
    releaseStorePassword != null &&
    releaseKeyAlias != null &&
    releaseKeyPassword != null

/**
 * The ABIs this build is for, read from the property Flutter passes
 * (`-Ptarget-platform=android-arm64`). A build that names one architecture packs
 * a single APK with the engine for that architecture only -- but our own core
 * ships a `libclash.so` per ABI, and Gradle would pack every one of them, so an
 * "arm64" package would still carry x86 libraries it can never load and weigh
 * three times what it needs to. Filtering here makes the name true of the whole
 * package. A split build names all its architectures, which filters nothing.
 */
val requestedAbis = (project.findProperty("target-platform") as String?)
    ?.split(',')
    ?.mapNotNull {
        when (it.trim()) {
            "android-arm" -> "armeabi-v7a"
            "android-arm64" -> "arm64-v8a"
            "android-x64" -> "x86_64"
            "android-x86" -> "x86"
            else -> null
        }
    }
    .orEmpty()

/**
 * The thousand-block the architecture occupies, mirroring the table the
 * Flutter plugin uses when it splits (`output.versionCodeOverride =
 * abiVersionCode * 1000 + base`). That override is what orders an arm64
 * package above the arm32 one it replaces.
 *
 * It only runs for a split build. A build that names one architecture does not
 * split, so the arithmetic never happened and the package went out 2000 below
 * the one already on the phone -- which Android refused to install over, as a
 * downgrade, no matter that its versionName read newer. Applying the block here
 * puts one architecture's packages in one sequence whether the build split or
 * not.
 */
val singleAbiBlock = requestedAbis.singleOrNull()?.let {
    when (it) {
        "armeabi-v7a" -> 1
        "arm64-v8a" -> 2
        "x86_64" -> 4
        else -> null
    }
}

android {
    namespace = "com.follow.clash"
    compileSdk = libs.versions.compileSdk.get().toInt()
    ndkVersion = libs.versions.ndkVersion.get()

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Ours, not upstream's `com.follow.clash`: the app ships under its own
        // name, so it must not answer to upstream's id either. The namespace
        // above stays upstream's -- the Kotlin packages and the plugins' method
        // channels live there, and only the installed id is ours.
        applicationId = "com.threely.skyward"
        minSdk = flutter.minSdkVersion
        targetSdk = libs.versions.targetSdk.get().toInt()
        versionCode = flutter.versionCode + (singleAbiBlock ?: 0) * 1000
        // Our revision over upstream rides in the versionCode and in the
        // versionName the app and Android both report, so the two always agree;
        // the app still reads it back through APP_VERSION (see
        // lib/common/package.dart).
        versionName = System.getenv("APP_VERSION_NAME") ?: flutter.versionName
        if (requestedAbis.isNotEmpty()) {
            ndk {
                // Cleared rather than added to: the Flutter plugin fills this
                // same set with its whole supported list, and it only leaves it
                // alone because the build passes `disable-abi-filtering`.
                abiFilters.clear()
                abiFilters.addAll(requestedAbis)
            }
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            applicationIdSuffix = ".dev"
        }

        release {
            isMinifyEnabled = true
            isShrinkResources = true
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
                applicationIdSuffix = ".dev"
            }

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    sourceSets {
        // Unit tests live under android/tests/ instead of each module's src/test.
        getByName("test").java.setSrcDirs(listOf("../tests/app"))
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(project(":service"))
    implementation(project(":common"))
    implementation(project(":core"))
    implementation(libs.core.splashscreen)
    implementation(libs.gson)
    implementation(libs.smali.dexlib2) {
        exclude(group = "com.google.guava", module = "guava")
    }
    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
}
