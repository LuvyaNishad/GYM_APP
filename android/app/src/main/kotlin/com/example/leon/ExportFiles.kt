package com.example.leon

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class ExportFiles(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var bytes: ByteArray? = null
    private val limit = 50 * 1024 * 1024

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (pending != null) { result.error("busy", "A document picker is already open", null); return }
        try {
            val name = (call.argument<String>("name") ?: "backup.json")
                .replace(Regex("[^A-Za-z0-9._-]"), "_")
            val mime = call.argument<String>("mime") ?: "application/json"
            when (call.method) {
                "save" -> {
                    bytes = call.argument<ByteArray>("bytes") ?: error("Missing file bytes")
                    pending = result
                    activity.startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT)
                        .addCategory(Intent.CATEGORY_OPENABLE).setType(mime)
                        .putExtra(Intent.EXTRA_TITLE, name), 4101)
                }
                "pickBackup" -> {
                    pending = result
                    activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT)
                        .addCategory(Intent.CATEGORY_OPENABLE).setType("*/*"), 4102)
                }
                "share" -> {
                    val directory = File(activity.cacheDir, "exports").apply { mkdirs() }
                    directory.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 86400000 }
                        ?.forEach { it.delete() }
                    val file = File(directory, name)
                    file.writeBytes(call.argument<ByteArray>("bytes") ?: error("Missing bytes"))
                    val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.exports", file)
                    val share = Intent(Intent.ACTION_SEND).setType(mime)
                        .putExtra(Intent.EXTRA_STREAM, uri)
                        .apply { clipData = android.content.ClipData.newRawUri(name, uri) }
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    activity.startActivity(Intent.createChooser(share, "Share file"))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            pending = null; bytes = null
            result.error("file_error", e.message, null)
        }
    }

    fun onResult(request: Int, code: Int, intent: Intent?): Boolean {
        if (request !in 4101..4102) return false
        val result = pending ?: return true
        pending = null
        try {
            val uri: Uri? = intent?.data
            if (code != Activity.RESULT_OK || uri == null) { result.success(null); return true }
            if (request == 4101) {
                activity.contentResolver.openOutputStream(uri, "wt").use { stream ->
                    checkNotNull(stream).write(checkNotNull(bytes))
                    stream.flush()
                }
                result.success(uri.toString())
            } else {
                activity.contentResolver.openInputStream(uri).use { stream ->
                    val data = checkNotNull(stream).readBytesLimited(limit)
                    result.success(data)
                }
            }
        } catch(e: Exception) { result.error("file_error", e.message, null) }
        finally { bytes = null }
        return true
    }

    private fun java.io.InputStream.readBytesLimited(max: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(8192)
        while (true) {
            val count = read(buffer)
            if (count < 0) break
            check(out.size() + count <= max) { "Backup exceeds 50 MB" }
            out.write(buffer, 0, count)
        }
        return out.toByteArray()
    }
}
