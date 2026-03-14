package ru.qorviamapkit.maps_sdk

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/**
 * QorviaMapsPlugin - Flutter plugin for Qorvia Maps SDK.
 *
 * Provides native Android functionality for:
 * - MapLibre offline operations
 * - GraphHopper offline routing
 */
class QorviaMapsPlugin : FlutterPlugin {
    private lateinit var maplibreChannel: MethodChannel
    private lateinit var routingChannel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        // MapLibre helper channel
        maplibreChannel = MethodChannel(flutterPluginBinding.binaryMessenger, MAPLIBRE_CHANNEL)
        maplibreChannel.setMethodCallHandler { call, result ->
            MapLibreHelper.handleMethodCall(context, call, result)
        }

        // GraphHopper routing channel
        routingChannel = MethodChannel(flutterPluginBinding.binaryMessenger, ROUTING_CHANNEL)
        routingChannel.setMethodCallHandler { call, result ->
            GraphHopperHelper.handleMethodCall(context, call, result)
        }

        // Initialize GraphHopper
        GraphHopperHelper.initialize(context)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        maplibreChannel.setMethodCallHandler(null)
        routingChannel.setMethodCallHandler(null)
        GraphHopperHelper.dispose()
    }

    companion object {
        const val MAPLIBRE_CHANNEL = "ru.qorviamapkit.maps_sdk/maplibre_helper"
        const val ROUTING_CHANNEL = "ru.qorviamapkit.maps_sdk/offline_routing"
    }
}
