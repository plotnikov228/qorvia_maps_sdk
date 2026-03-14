package ru.qorviamapkit.maps_sdk

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Stub helper for GraphHopper offline routing on Android.
 *
 * GraphHopper is currently disabled. Enable by uncommenting the dependency
 * in build.gradle and restoring the full implementation.
 */
object GraphHopperHelper {
    private const val TAG = "QorviaMapsSDK_GH"

    /**
     * Initializes the GraphHopper helper.
     */
    fun initialize(context: Context) {
        Log.d(TAG, "GraphHopper offline routing is currently disabled")
    }

    /**
     * Handles method calls from Flutter.
     */
    fun handleMethodCall(context: Context, call: MethodCall, result: MethodChannel.Result) {
        result.error(
            "DISABLED",
            "GraphHopper offline routing is currently disabled",
            "Enable by uncommenting the dependency in build.gradle"
        )
    }

    /**
     * Disposes all loaded graphs.
     */
    fun dispose() {
        Log.d(TAG, "GraphHopper dispose (no-op)")
    }
}
