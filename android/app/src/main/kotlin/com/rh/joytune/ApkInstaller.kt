package com.rh.joytune

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * APK 安装器：通过 FileProvider + ACTION_VIEW 把已下载的 APK 交给系统安装器。
 * Flutter 侧经 MethodChannel "joy_tune/install" 调用 installApk。
 * 独立成类，避免 MainActivity 膨胀，也便于后续扩展（如 REQUEST_INSTALL_PACKAGES 场景）。
 */
object ApkInstaller {
    private const val CHANNEL = "joy_tune/install"
    // 与 AndroidManifest.xml 中 FileProvider 的 authorities 保持一致
    private const val AUTHORITY = "com.rh.joytune.fileprovider"
    private const val TAG = "ApkInstaller"

    /** 在 FlutterEngine 上注册安装通道（MainActivity.configureFlutterEngine 调用） */
    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("bad_arg", "apk path is empty", null)
                            return@setMethodCallHandler
                        }
                        installApk(context, path)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** 交给系统安装器安装 APK */
    fun installApk(context: Context, apkPath: String) {
        val file = File(apkPath)
        if (!file.exists()) {
            Log.w(TAG, "APK 不存在: $apkPath")
            return
        }
        val uri: Uri = FileProvider.getUriForFile(context, AUTHORITY, file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            // 跨进程授权给系统安装器读取
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            // 用 applicationContext 启动必需
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            context.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Log.w(TAG, "未找到可处理 APK 安装的组件: ${e.message}")
        } catch (e: SecurityException) {
            Log.w(TAG, "启动安装器被拒绝: ${e.message}")
        }
    }
}
