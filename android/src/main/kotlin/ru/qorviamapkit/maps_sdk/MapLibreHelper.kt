package ru.qorviamapkit.maps_sdk

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Helper for MapLibre native operations.
 *
 * Provides functionality to manage the MapLibre offline database
 * that isn't available through the maplibre_gl Flutter plugin.
 */
object MapLibreHelper {
    private const val TAG = "QorviaMapsSDK"
    private const val DATABASE_NAME = "mbgl-offline.db"

    /**
     * Handles method calls from Flutter.
     */
    fun handleMethodCall(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "deleteOfflineDatabase" -> {
                val deleted = deleteOfflineDatabase(context)
                result.success(deleted)
            }
            "checkDatabaseExists" -> {
                val exists = checkDatabaseExists(context)
                result.success(exists)
            }
            "getDatabasePath" -> {
                val path = getDatabasePath(context)
                result.success(path)
            }
            "getDatabaseSize" -> {
                val size = getDatabaseSize(context)
                result.success(size)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Deletes the MapLibre offline database file.
     *
     * @param context Android context
     * @return true if database was deleted, false otherwise
     */
    private fun deleteOfflineDatabase(context: Context): Boolean {
        val dbFile = File(context.filesDir, DATABASE_NAME)
        Log.d(TAG, "Attempting to delete database at: ${dbFile.absolutePath}")

        return if (dbFile.exists()) {
            val deleted = dbFile.delete()
            Log.d(TAG, "Database deleted: $deleted")
            deleted
        } else {
            Log.d(TAG, "Database file does not exist")
            false
        }
    }

    /**
     * Checks if the MapLibre offline database file exists.
     *
     * @param context Android context
     * @return true if database exists, false otherwise
     */
    private fun checkDatabaseExists(context: Context): Boolean {
        val dbFile = File(context.filesDir, DATABASE_NAME)
        val exists = dbFile.exists()
        val size = if (exists) dbFile.length() else 0
        Log.d(TAG, "Database check - exists: $exists, path: ${dbFile.absolutePath}, size: $size bytes")
        return exists
    }

    /**
     * Gets the path to the MapLibre offline database file.
     *
     * @param context Android context
     * @return Absolute path to the database file
     */
    private fun getDatabasePath(context: Context): String {
        return File(context.filesDir, DATABASE_NAME).absolutePath
    }

    /**
     * Gets the size of the MapLibre offline database file in bytes.
     *
     * @param context Android context
     * @return Size in bytes, or 0 if file doesn't exist
     */
    private fun getDatabaseSize(context: Context): Long {
        val dbFile = File(context.filesDir, DATABASE_NAME)
        return if (dbFile.exists()) dbFile.length() else 0
    }
}
