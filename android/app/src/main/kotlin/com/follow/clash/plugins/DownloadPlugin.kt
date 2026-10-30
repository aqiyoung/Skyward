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
import java.security.MessageDigest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DownloadPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var context: Context

    private lateinit var methodChannel: MethodChannel

    private var downloadReceiver: BroadcastReceiver? = null

    /// The download the complete receiver already opened an installer (or
    /// the unknown-sources settings) for, so a Dart-side backup call for
    /// the same download does not open a second installer window.
    private var installerOpenedForDownloadId: Long? = null

    /// Expected SHA-256 per download, from the hash the release published
    /// for its APK asset. Kept in memory only: entries are dropped after
    /// the download is handled or cancelled.
    private val expectedSha256 = mutableMapOf<Long, String>()

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
                val sha256 = call.argument<String>("expectedSha256")
                if (url.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("bad_arguments", "url and fileName are required", null)
                } else {
                    try {
                        result.success(download(url, fileName, sha256))
                    } catch (error: Exception) {
                        result.error("download_failed", error.message, null)
                    }
                }
            }
            "status" -> {
                val downloadId = call.argument<Number>("downloadId")?.toLong()
                if (downloadId == null) {
                    result.error("bad_arguments", "downloadId is required", null)
                } else {
                    try {
                        result.success(downloadStatus(downloadId))
                    } catch (error: Exception) {
                        result.error("status_failed", error.message, null)
                    }
                }
            }
            "cancel" -> {
                val downloadId = call.argument<Number>("downloadId")?.toLong()
                if (downloadId == null) {
                    result.error("bad_arguments", "downloadId is required", null)
                } else {
                    unregisterDownloadReceiver()
                    expectedSha256.remove(downloadId)
                    val manager =
                        context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                    result.success(manager.remove(downloadId) > 0)
                }
            }
            "install" -> {
                val downloadId = call.argument<Number>("downloadId")?.toLong()
                if (downloadId == null) {
                    result.error("bad_arguments", "downloadId is required", null)
                } else if (installerOpenedForDownloadId == downloadId) {
                    // The complete receiver already opened the installer (or
                    // the unknown-sources settings) for this download.
                    result.success(false)
                } else {
                    result.success(handleDownloadComplete(downloadId))
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
    private fun download(url: String, fileName: String, sha256: String?): Long {
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
        if (!sha256.isNullOrBlank()) {
            expectedSha256[downloadId] = sha256
        }
        registerDownloadReceiver(downloadId)
        return downloadId
    }

    /// The state Dart polls to drive its in-app progress dialog. A missing
    /// row means the download is gone (cancelled or removed), which Dart
    /// reports as failed rather than polling forever.
    private fun downloadStatus(downloadId: Long): Map<String, Any> {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val cursor = manager.query(DownloadManager.Query().setFilterById(downloadId))
            ?: return mapOf(
                "status" to "failed",
                "downloadedBytes" to 0,
                "totalBytes" to -1,
            )
        cursor.use {
            if (!it.moveToFirst()) {
                return mapOf(
                    "status" to "failed",
                    "downloadedBytes" to 0,
                    "totalBytes" to -1,
                )
            }
            val status = when (
                it.getInt(it.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            ) {
                DownloadManager.STATUS_RUNNING -> "running"
                DownloadManager.STATUS_SUCCESSFUL -> "successful"
                DownloadManager.STATUS_FAILED -> "failed"
                DownloadManager.STATUS_PAUSED -> "paused"
                DownloadManager.STATUS_PENDING -> "pending"
                else -> "unknown"
            }
            val downloaded = it.getLong(
                it.getColumnIndexOrThrow(
                    DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR,
                ),
            )
            val total = it.getLong(
                it.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES),
            )
            return mapOf(
                "status" to status,
                "downloadedBytes" to downloaded,
                "totalBytes" to total,
            )
        }
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
    private fun handleDownloadComplete(downloadId: Long): Boolean {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val cursor = manager.query(DownloadManager.Query().setFilterById(downloadId))
            ?: return false
        cursor.use {
            if (!it.moveToFirst()) {
                return false
            }
            val status = it.getInt(
                it.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS),
            )
            if (status != DownloadManager.STATUS_SUCCESSFUL) {
                expectedSha256.remove(downloadId)
                return false
            }
        }
        // When the release published a SHA-256 for this APK, the file must
        // match before anything opens an installer for it. A mismatch means
        // tampering or corruption: delete the file and refuse to install.
        // Without a published hash (older releases) this step is skipped.
        val expected = expectedSha256.remove(downloadId)
        if (expected != null && !verifySha256(manager, downloadId, expected)) {
            manager.remove(downloadId)
            return false
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
                installerOpenedForDownloadId = downloadId
                return true
            }
            val uri = manager.getUriForDownloadedFile(downloadId) ?: return false
            val install = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            context.startActivity(install)
            installerOpenedForDownloadId = downloadId
            return true
        } catch (_: Exception) {
            // The download manager's notification remains the fallback.
            return false
        }
    }

    /// Computes the SHA-256 of a finished download and compares it with
    /// the expected hex string. False on any error, so a file that cannot
    /// be read is never installed.
    private fun verifySha256(
        manager: DownloadManager,
        downloadId: Long,
        expected: String,
    ): Boolean {
        val uri = manager.getUriForDownloadedFile(downloadId) ?: return false
        val actual = try {
            val digest = MessageDigest.getInstance("SHA-256")
            context.contentResolver.openInputStream(uri)?.use { input ->
                val buffer = ByteArray(8192)
                var read: Int
                while (input.read(buffer).also { read = it } != -1) {
                    digest.update(buffer, 0, read)
                }
            } ?: return false
            digest.digest().joinToString("") { "%02x".format(it) }
        } catch (_: Exception) {
            return false
        }
        return actual.equals(expected, ignoreCase = true)
    }

    companion object {
        const val CHANNEL = "com.follow.clash/download"
    }
}
