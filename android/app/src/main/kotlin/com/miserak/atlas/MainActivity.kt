package com.miserak.atlas

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.miserak.atlas/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareFile" -> {
                        val filePath = call.argument<String>("path") ?: ""
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        val subject = call.argument<String>("subject") ?: ""
                        try {
                            val file = File(filePath)
                            val uri = FileProvider.getUriForFile(this, "${packageName}.provider", file)
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = mimeType
                                putExtra(Intent.EXTRA_STREAM, uri)
                                putExtra(Intent.EXTRA_SUBJECT, subject)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(intent, subject))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SHARE_ERROR", e.message, null)
                        }
                    }
                    "saveToDownloads" -> {
                        val filePath = call.argument<String>("path") ?: ""
                        val fileName = call.argument<String>("fileName") ?: File(filePath).name
                        try {
                            saveToDownloads(File(filePath), fileName)
                            result.success(fileName)
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveToDownloads(src: File, fileName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val cv = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/octet-stream")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv)
                ?: throw IOException("Failed to create Downloads entry")
            contentResolver.openOutputStream(uri)?.use { out ->
                src.inputStream().use { it.copyTo(out) }
            } ?: throw IOException("Failed to open output stream")
            cv.clear()
            cv.put(MediaStore.Downloads.IS_PENDING, 0)
            contentResolver.update(uri, cv, null, null)
        } else {
            @Suppress("DEPRECATION")
            val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            dir.mkdirs()
            src.copyTo(File(dir, fileName), overwrite = true)
        }
    }
}
