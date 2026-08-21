package com.rh.joytune

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // 设备 ID 通道：Flutter 侧通过此通道获取 Android 系统稳定的 ANDROID_ID 与设备 ABI
    private val channelName = "joy_tune/device_id"
    // 下载目录通道：Flutter 侧获取公共 Download 目录 + 存储写入权限
    private val downloadDirChannel = "joy_tune/download_dir"
    // 运行时请求存储权限标识
    private val requestCodeStorage = 1001

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
        // 下载目录通道：歌曲下载落盘公共 Download/JoyTune
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadDirChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDownloadDir" -> {
                        // 公共下载目录（/storage/emulated/0/Download），用户可访问
                        val dir = Environment.getExternalStoragePublicDirectory(
                            Environment.DIRECTORY_DOWNLOADS
                        )
                        result.success(dir.absolutePath)
                    }
                    "hasStoragePermission" -> {
                        result.success(hasStoragePermission())
                    }
                    "requestStoragePermission" -> {
                        requestDownloadStoragePermission()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // 注册 APK 安装通道（独立类，保持 MainActivity 精简）
        ApkInstaller.register(flutterEngine, applicationContext)
    }

    /// 是否具备写公共 Download 目录的权限：
    /// Android 11+ 需"所有文件访问"（MANAGE_EXTERNAL_STORAGE）；
    /// Android 6~10 需 WRITE_EXTERNAL_STORAGE 运行时授权。
    private fun hasStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    /// 请求写公共 Download 权限：
    /// Android 11+ 跳系统"所有文件访问"设置页；Android 6~10 运行时权限弹窗。
    private fun requestDownloadStoragePermission() {
        if (hasStoragePermission()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            } catch (e: Exception) {
                // 回落：打开系统"所有文件访问"总设置页
                try {
                    startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
                } catch (e2: Exception) {
                    Toast.makeText(this, "请到系统设置开启存储权限", Toast.LENGTH_SHORT).show()
                }
            }
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                requestCodeStorage
            )
        }
    }
}
