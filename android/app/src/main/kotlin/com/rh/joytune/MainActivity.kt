package com.rh.joytune

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // 设备 ID 通道：Flutter 侧通过此通道获取 Android 系统稳定的 ANDROID_ID
    private val channelName = "joy_tune/device_id"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getSystemDeviceId") {
                    // Settings.Secure.ANDROID_ID：系统级稳定 ID，无需任何权限
                    val androidId = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ANDROID_ID
                    )
                    result.success(androidId)
                } else {
                    result.notImplemented()
                }
            }
    }
}
