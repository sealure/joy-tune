package com.rh.joytune

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // 设备 ID 通道：Flutter 侧通过此通道获取 Android 系统稳定的 ANDROID_ID 与设备 ABI
    private val channelName = "joy_tune/device_id"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSystemDeviceId" -> {
                        // Settings.Secure.ANDROID_ID：系统级稳定 ID，无需任何权限
                        val androidId = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.ANDROID_ID
                        )
                        result.success(androidId)
                    }
                    "getSupportedAbi" -> {
                        // 设备 ABI（SUPPORTED_ABIS 优先项）：arm64-v8a / armeabi-v7a / x86_64，
                        // 用于自动更新按 CPU 架构匹配对应的 APK 产物
                        result.success(Build.SUPPORTED_ABIS.firstOrNull())
                    }
                    else -> result.notImplemented()
                }
            }
        // 注册 APK 安装通道（独立类，保持 MainActivity 精简）
        ApkInstaller.register(flutterEngine, applicationContext)
    }
}
