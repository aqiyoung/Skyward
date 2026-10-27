package com.follow.clash.plugins

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DownloadPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var context: Context

    private lateinit var methodChannel: MethodChannel

    private var downloadReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unregisterDownloadReceiver()
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "supportedAbi" -> result.success(supportedAbi())
            "download" -> {
                val url = call.argument<String>("url")
                val fileName = call.argument<String>("fileName")
                if (url.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("bad_arguments", "url and fileName are required", null)
                } else {
                    try {
                        result.success(download(url, fileName))
                    } catch (error: Exception) {
                        result.error("download_failed", error.message, null)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    /// The ABI the device runs, which names the package that fits it.
    private fun supportedAbi(): String {
        return Build.SUPPORTED_ABIS.firstOrNull() ?: "arm64-v8a"
    }

    /// Hands the file to the system download manager, which keeps it in the
    /// Downloads folder and shows its own progress.
    private fun download(url: String, fileName: String): Long {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(fileName)
            .setDescription(fileName)
            .setMimeType("application/vnd.android.package-archive")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
        val downloadId = manager.enqueue(request)
        registerDownloadReceiver(downloadId)
        return downloadId
    }

    private fun registerDownloadReceiver(downloadId: Long) {
        unregisterDownloadReceiver()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(receiverContext: Context, intent: Intent) {
                if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) {
                    return
                }
                if (intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1) != downloadId) {
                    return
                }
                unregisterDownloadReceiver()
                handleDownloadComplete(downloadId)
            }
        }
        downloadReceiver = receiver
        val filter = IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(receiver, filter)
        }
    }

    private fun unregisterDownloadReceiver() {
        val receiver = downloadReceiver ?: return
        downloadReceiver = null
        try {
            context.unregisterReceiver(receiver)
        } catch (_: IllegalArgumentException) {
            // Already unregistered, for example after a completed download.
        }
    }

    /// Opens the system installer for a finished download, or the
    /// unknown-sources settings when installing from this app has not been
    /// allowed yet. A normal app cannot install silently, so the installer
    /// itself is always the last step; if the app is gone by the time the
    /// download finishes, the download manager's own notification still
    /// opens the same installer when tapped.
    private fun handleDownloadComplete(downloadId: Long) {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val cursor = manager.query(DownloadManager.Query().setFilterById(downloadId))
            ?: return
        cursor.use {
            if (!it.moveToFirst()) {
                return
            }
            val status = it.getInt(
                it.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS),
            )
            if (status != DownloadManager.STATUS_SUCCESSFUL) {
                return
            }
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !context.packageManager.canRequestPackageInstalls()
            ) {
                val settings = Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${context.packageName}"),
                ).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(settings)
                return
            }
            val uri = manager.getUriForDownloadedFile(downloadId) ?: return
            val install = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            context.startActivity(install)
        } catch (_: Exception) {
            // The download manager's notification remains the fallback.
        }
    }

    companion object {
        const val CHANNEL = "com.follow.clash/download"
    }
}
