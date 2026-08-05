plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ── 发布签名配置 ──
// 本地开发：读 android/app/key.properties（已被 .gitignore 忽略，不提交仓库）；
// CI（GitHub Actions）：由 workflow 把 Secrets 解码为 key.properties，同一份密钥保证所有版本签名一致，
// 自更新才能无缝覆盖安装（否则每次 debug 签名不同 → 覆盖安装报"签名不同"）。
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("app/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.rh.joytune"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rh.joytune"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // 固定 keystore 签名（本地 key.properties / CI Secrets），保证所有版本签名一致
            signingConfig = if (keystoreProperties["storeFile"] != null) {
                signingConfigs.getByName("release")
            } else {
                // 缺少 key.properties 时降级 debug 签名，保证本地 flutter run --release 可用
                signingConfigs.getByName("debug")
            }
            // 关闭资源收缩：google-services 生成的 default_web_client_id 被 getIdentifier() 动态引用，
            // AGP 9 默认资源收缩会误判为未使用而移除，导致 Google 登录拿不到 serverClientId（idToken=null）
            isShrinkResources = false
            isMinifyEnabled = false
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
