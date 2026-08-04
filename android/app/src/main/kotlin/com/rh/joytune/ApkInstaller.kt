package com.rh.joytune

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * APK 安装器：通过 FileProvider + ACTION_VIEW 把已下载的 APK 交给系统安装器。
 * Flutter 侧经 MethodChannel "joy_tune/install" 调用 installApk / openUnknownSourceSettings。
 * 独立成类，避免 MainActivity 膨胀，也便于后续扩展。
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
                        try {
                            installApk(context, path)
                            result.success(null)
                        } catch (e: Exception) {
                            // 无"安装未知应用"权限等：通过 error 回传，Flutter 侧据此引导
                            Log.e(TAG, "安装 APK 失败: ${e.message}", e)
                            result.error("install_failed", e.message, null)
                        }
                    }
                    "hasUnknownSourcePermission" -> {
                        // 是否已授权"安装未知应用"
                        result.success(canRequestPackageInstalls(context))
                    }
                    "openUnknownSourceSettings" -> {
                        // 跳转系统"安装未知应用"设置页让用户授权
                        openUnknownSourceSettings(context)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** 是否已授权"安装未知应用"（Android 8+ 安装 APK 的前提） */
    fun canRequestPackageInstalls(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.packageManager.canRequestPackageInstalls()
        } else {
            true // Android 7 及以下无需此授权
        }
    }

    /** 跳转系统"允许安装未知应用"设置页（ACTION_MANAGE_UNKNOWN_APP_SOURCES） */
    fun openUnknownSourceSettings(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${context.packageName}")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.w(TAG, "无法打开安装未知应用设置: ${e.message}")
        }
    }

    /** 交给系统安装器安装 APK；FileProvider 找不到文件/路径不匹配等异常向上抛出 */
    fun installApk(context: Context, apkPath: String) {
        // Android 8+ 必须已授权"安装未知应用"，否则安装会被系统拒绝
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !context.packageManager.canRequestPackageInstalls()
        ) {
            throw IllegalStateException("未授权安装未知应用，请先在系统设置中允许")
        }
        val file = File(apkPath)
        if (!file.exists()) {
            Log.w(TAG, "APK 不存在: $apkPath")
            throw IllegalStateException("APK 文件不存在: $apkPath")
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
            throw e
        } catch (e: SecurityException) {
            Log.w(TAG, "启动安装器被拒绝: ${e.message}")
            throw e
        }
    }
}
