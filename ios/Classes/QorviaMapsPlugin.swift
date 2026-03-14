import Flutter
import UIKit

/// QorviaMapsPlugin - Flutter plugin for Qorvia Maps SDK.
///
/// Provides native iOS functionality for:
/// - Offline routing using A* algorithm
public class QorviaMapsPlugin: NSObject, FlutterPlugin {
    private var routingChannel: FlutterMethodChannel?
    private let routingEngine = RoutingEngine()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = QorviaMapsPlugin()

        // Routing channel
        let routingChannel = FlutterMethodChannel(
            name: "ru.qorviamapkit.maps_sdk/offline_routing",
            binaryMessenger: registrar.messenger()
        )
        instance.routingChannel = routingChannel

        registrar.addMethodCallDelegate(instance, channel: routingChannel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadGraph":
            handleLoadGraph(call, result: result)
        case "unloadGraph":
            handleUnloadGraph(call, result: result)
        case "calculateRoute":
            handleCalculateRoute(call, result: result)
        case "isGraphLoaded":
            handleIsGraphLoaded(call, result: result)
        case "getLoadedGraphs":
            handleGetLoadedGraphs(result: result)
        case "getGraphInfo":
            handleGetGraphInfo(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleLoadGraph(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let regionId = args["regionId"] as? String,
              let graphPath = args["graphPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "regionId and graphPath are required", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.routingEngine.loadGraph(regionId: regionId, graphPath: graphPath)
                DispatchQueue.main.async {
                    result([
                        "success": true,
                        "regionId": regionId
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func handleUnloadGraph(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let regionId = args["regionId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "regionId is required", details: nil))
            return
        }

        routingEngine.unloadGraph(regionId: regionId)
        result(true)
    }

    private func handleCalculateRoute(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let regionId = args["regionId"] as? String,
              let fromLat = args["fromLat"] as? Double,
              let fromLon = args["fromLon"] as? Double,
              let toLat = args["toLat"] as? Double,
              let toLon = args["toLon"] as? Double else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required route parameters", details: nil))
            return
        }

        let profile = args["profile"] as? String ?? "car"
        let waypoints = args["waypoints"] as? [[String: Double]]

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let routeResult = try self.routingEngine.calculateRoute(
                    regionId: regionId,
                    fromLat: fromLat,
                    fromLon: fromLon,
                    toLat: toLat,
                    toLon: toLon,
                    profile: profile,
                    waypoints: waypoints
                )
                DispatchQueue.main.async {
                    result(routeResult)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "ROUTE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func handleIsGraphLoaded(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let regionId = args["regionId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "regionId is required", details: nil))
            return
        }

        result(routingEngine.isGraphLoaded(regionId: regionId))
    }

    private func handleGetLoadedGraphs(result: @escaping FlutterResult) {
        result(routingEngine.getLoadedGraphs())
    }

    private func handleGetGraphInfo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let regionId = args["regionId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "regionId is required", details: nil))
            return
        }

        result(routingEngine.getGraphInfo(regionId: regionId))
    }
}
