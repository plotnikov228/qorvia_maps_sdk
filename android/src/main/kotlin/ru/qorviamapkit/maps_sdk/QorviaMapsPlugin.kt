package ru.qorviamapkit.maps_sdk

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/**
 * QorviaMapsPlugin - Flutter plugin for Qorvia Maps SDK.
 *
 * Provides native Android functionality for MapLibre offline operations.
 */
class QorviaMapsPlugin : FlutterPlugin {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
            MapLibreHelper.handleMethodCall(context, call, result)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val CHANNEL_NAME = "ru.qorviamapkit.maps_sdk/maplibre_helper"
    }
}
