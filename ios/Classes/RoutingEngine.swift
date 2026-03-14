import Foundation

/// Error types for routing operations.
enum RoutingError: LocalizedError {
    case graphNotFound(String)
    case graphLoadFailed(String)
    case routeNotFound
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .graphNotFound(let regionId):
            return "Graph not loaded: \(regionId)"
        case .graphLoadFailed(let message):
            return "Failed to load graph: \(message)"
        case .routeNotFound:
            return "No route found between the points"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

/// Routing engine using A* algorithm for offline routing on iOS.
///
/// This engine provides offline routing functionality by loading
/// road network graphs and calculating routes using the A* algorithm.
class RoutingEngine {
    /// Loaded graphs by region ID
    private var loadedGraphs: [String: RoutingGraph] = [:]

    /// Queue for thread-safe graph access
    private let graphQueue = DispatchQueue(label: "com.qorvia.routing.graph", attributes: .concurrent)

    // MARK: - Graph Management

    /// Loads a routing graph from a .ghz file.
    ///
    /// The .ghz file is a zipped archive containing the routing graph data.
    ///
    /// - Parameters:
    ///   - regionId: Unique identifier for this graph
    ///   - graphPath: Path to the .ghz file
    func loadGraph(regionId: String, graphPath: String) throws {
        NSLog("[RoutingEngine] Loading graph: \(regionId) from \(graphPath)")

        // Check if already loaded
        if isGraphLoaded(regionId: regionId) {
            NSLog("[RoutingEngine] Graph already loaded: \(regionId)")
            return
        }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: graphPath) else {
            throw RoutingError.graphLoadFailed("Graph file not found: \(graphPath)")
        }

        // Get app documents directory for extraction
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let extractDir = documentsURL.appendingPathComponent("routing_graphs").appendingPathComponent(regionId)

        // Clean up old extraction
        if fileManager.fileExists(atPath: extractDir.path) {
            try? fileManager.removeItem(at: extractDir)
        }
        try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)

        // Extract the .ghz file
        try extractZip(from: URL(fileURLWithPath: graphPath), to: extractDir)

        // Load the graph
        let graph = try RoutingGraph(directory: extractDir)

        graphQueue.async(flags: .barrier) {
            self.loadedGraphs[regionId] = graph
        }

        NSLog("[RoutingEngine] Graph loaded successfully: \(regionId), nodes: \(graph.nodeCount)")
    }

    /// Unloads a routing graph.
    func unloadGraph(regionId: String) {
        NSLog("[RoutingEngine] Unloading graph: \(regionId)")

        graphQueue.async(flags: .barrier) {
            self.loadedGraphs.removeValue(forKey: regionId)
        }

        // Clean up extracted files
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let extractDir = documentsURL.appendingPathComponent("routing_graphs").appendingPathComponent(regionId)
        try? fileManager.removeItem(at: extractDir)
    }

    /// Checks if a graph is loaded.
    func isGraphLoaded(regionId: String) -> Bool {
        var result = false
        graphQueue.sync {
            result = loadedGraphs[regionId] != nil
        }
        return result
    }

    /// Gets list of loaded graph IDs.
    func getLoadedGraphs() -> [String] {
        var result: [String] = []
        graphQueue.sync {
            result = Array(loadedGraphs.keys)
        }
        return result
    }

    /// Gets information about a loaded graph.
    func getGraphInfo(regionId: String) -> [String: Any]? {
        var graph: RoutingGraph?
        graphQueue.sync {
            graph = loadedGraphs[regionId]
        }

        guard let g = graph else { return nil }

        return [
            "regionId": regionId,
            "profiles": ["car", "bike", "foot"],
            "nodeCount": g.nodeCount,
            "edgeCount": g.edgeCount,
            "bounds": [
                "minLat": g.bounds.minLat,
                "minLon": g.bounds.minLon,
                "maxLat": g.bounds.maxLat,
                "maxLon": g.bounds.maxLon
            ]
        ]
    }

    // MARK: - Route Calculation

    /// Calculates a route using the A* algorithm.
    ///
    /// - Parameters:
    ///   - regionId: Region identifier
    ///   - fromLat: Starting latitude
    ///   - fromLon: Starting longitude
    ///   - toLat: Destination latitude
    ///   - toLon: Destination longitude
    ///   - profile: Routing profile (car, bike, foot)
    ///   - waypoints: Optional intermediate waypoints
    /// - Returns: Dictionary containing route data
    func calculateRoute(
        regionId: String,
        fromLat: Double,
        fromLon: Double,
        toLat: Double,
        toLon: Double,
        profile: String,
        waypoints: [[String: Double]]?
    ) throws -> [String: Any] {
        var graph: RoutingGraph?
        graphQueue.sync {
            graph = loadedGraphs[regionId]
        }

        guard let g = graph else {
            throw RoutingError.graphNotFound(regionId)
        }

        NSLog("[RoutingEngine] Calculating route: (\(fromLat), \(fromLon)) -> (\(toLat), \(toLon)) via \(profile)")

        // Build list of points
        var points: [(lat: Double, lon: Double)] = [(fromLat, fromLon)]
        if let wps = waypoints {
            for wp in wps {
                if let lat = wp["lat"], let lon = wp["lon"] {
                    points.append((lat, lon))
                }
            }
        }
        points.append((toLat, toLon))

        // Calculate route through all points
        var totalPath: [RoutingGraph.Node] = []
        var totalDistance: Double = 0
        var totalTime: Double = 0

        for i in 0..<(points.count - 1) {
            let from = points[i]
            let to = points[i + 1]

            // Find nearest nodes
            guard let startNode = g.findNearestNode(lat: from.lat, lon: from.lon),
                  let endNode = g.findNearestNode(lat: to.lat, lon: to.lon) else {
                throw RoutingError.routeNotFound
            }

            // Run A* algorithm
            guard let (path, distance, time) = astar(
                graph: g,
                start: startNode,
                end: endNode,
                profile: profile
            ) else {
                throw RoutingError.routeNotFound
            }

            // Append to total path
            if !totalPath.isEmpty && !path.isEmpty {
                // Skip first node to avoid duplicates
                totalPath.append(contentsOf: path.dropFirst())
            } else {
                totalPath.append(contentsOf: path)
            }

            totalDistance += distance
            totalTime += time
        }

        // Build result
        let routePoints = totalPath.map { [$0.lat, $0.lon] }
        let instructions = buildInstructions(path: totalPath, graph: g)
        let bbox = calculateBbox(points: totalPath)

        return [
            "success": true,
            "distance": totalDistance,
            "time": totalTime * 1000, // Convert to milliseconds
            "points": routePoints,
            "instructions": instructions,
            "bbox": bbox
        ]
    }

    // MARK: - A* Algorithm

    /// A* pathfinding algorithm.
    private func astar(
        graph: RoutingGraph,
        start: RoutingGraph.Node,
        end: RoutingGraph.Node,
        profile: String
    ) -> (path: [RoutingGraph.Node], distance: Double, time: Double)? {
        // Priority queue (min-heap by f-score)
        var openSet = PriorityQueue<AStarNode>()
        var closedSet = Set<Int>()

        // g-scores and f-scores
        var gScore: [Int: Double] = [start.id: 0]
        var fScore: [Int: Double] = [start.id: heuristic(from: start, to: end)]
        var cameFrom: [Int: Int] = [:]

        openSet.enqueue(AStarNode(nodeId: start.id, fScore: fScore[start.id]!))

        while !openSet.isEmpty {
            guard let current = openSet.dequeue() else { break }

            if current.nodeId == end.id {
                // Reconstruct path
                var path = [graph.node(id: end.id)!]
                var currentId = end.id

                while let parentId = cameFrom[currentId] {
                    path.insert(graph.node(id: parentId)!, at: 0)
                    currentId = parentId
                }

                let distance = gScore[end.id] ?? 0
                let time = calculateTime(distance: distance, profile: profile)

                return (path, distance, time)
            }

            if closedSet.contains(current.nodeId) {
                continue
            }
            closedSet.insert(current.nodeId)

            guard let currentNode = graph.node(id: current.nodeId) else { continue }

            // Explore neighbors
            for edge in graph.edges(from: current.nodeId) {
                if closedSet.contains(edge.toNodeId) {
                    continue
                }

                // Calculate edge cost based on profile
                let edgeCost = edgeCostForProfile(edge: edge, profile: profile)
                let tentativeG = (gScore[current.nodeId] ?? .infinity) + edgeCost

                if tentativeG < (gScore[edge.toNodeId] ?? .infinity) {
                    cameFrom[edge.toNodeId] = current.nodeId
                    gScore[edge.toNodeId] = tentativeG

                    if let neighbor = graph.node(id: edge.toNodeId) {
                        let f = tentativeG + heuristic(from: neighbor, to: end)
                        fScore[edge.toNodeId] = f
                        openSet.enqueue(AStarNode(nodeId: edge.toNodeId, fScore: f))
                    }
                }
            }
        }

        return nil // No path found
    }

    /// Heuristic function for A* (haversine distance).
    private func heuristic(from: RoutingGraph.Node, to: RoutingGraph.Node) -> Double {
        return haversineDistance(
            lat1: from.lat, lon1: from.lon,
            lat2: to.lat, lon2: to.lon
        )
    }

    /// Calculates edge cost based on routing profile.
    private func edgeCostForProfile(edge: RoutingGraph.Edge, profile: String) -> Double {
        var baseCost = edge.distance

        // Apply profile-specific weights
        switch profile {
        case "car":
            // Prefer roads, avoid footpaths
            switch edge.roadType {
            case .motorway, .trunk, .primary:
                baseCost *= 0.8
            case .secondary, .tertiary:
                baseCost *= 0.9
            case .residential, .unclassified:
                baseCost *= 1.0
            case .footway, .cycleway, .path:
                baseCost *= 10.0 // Avoid
            default:
                baseCost *= 1.0
            }

        case "bike":
            // Prefer bike-friendly roads
            switch edge.roadType {
            case .cycleway:
                baseCost *= 0.7
            case .residential, .path:
                baseCost *= 0.9
            case .secondary, .tertiary:
                baseCost *= 1.0
            case .primary:
                baseCost *= 1.3
            case .motorway, .trunk:
                baseCost *= 10.0 // Avoid
            default:
                baseCost *= 1.0
            }

        case "foot":
            // Prefer footpaths
            switch edge.roadType {
            case .footway, .path:
                baseCost *= 0.8
            case .residential:
                baseCost *= 0.9
            case .cycleway:
                baseCost *= 1.0
            case .motorway, .trunk:
                baseCost *= 10.0 // Avoid
            default:
                baseCost *= 1.0
            }

        default:
            break
        }

        return baseCost
    }

    /// Calculates travel time based on distance and profile.
    private func calculateTime(distance: Double, profile: String) -> Double {
        let speed: Double // m/s
        switch profile {
        case "car":
            speed = 13.9 // ~50 km/h average
        case "bike":
            speed = 4.2 // ~15 km/h average
        case "foot":
            speed = 1.4 // ~5 km/h average
        default:
            speed = 13.9
        }
        return distance / speed
    }

    // MARK: - Helper Methods

    /// Haversine formula to calculate distance between two points.
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0 // Earth radius in meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    /// Builds turn-by-turn instructions from a path.
    private func buildInstructions(path: [RoutingGraph.Node], graph: RoutingGraph) -> [[String: Any]] {
        var instructions: [[String: Any]] = []

        if path.isEmpty { return instructions }

        // Start instruction
        instructions.append([
            "text": "Start",
            "distance": 0,
            "time": 0,
            "sign": 0,
            "streetName": ""
        ])

        var accumulatedDistance: Double = 0
        var lastTurnIndex = 0

        for i in 1..<path.count {
            let prev = path[i - 1]
            let curr = path[i]
            let distance = haversineDistance(
                lat1: prev.lat, lon1: prev.lon,
                lat2: curr.lat, lon2: curr.lon
            )
            accumulatedDistance += distance

            // Check for turns (simplified)
            if i < path.count - 1 {
                let next = path[i + 1]
                let angle = calculateTurnAngle(
                    from: prev, through: curr, to: next
                )

                // If significant turn, create instruction
                if abs(angle) > 30 {
                    let turnSign = angle > 0 ? 2 : -2 // Right : Left
                    let turnText = angle > 0 ? "Turn right" : "Turn left"

                    instructions.append([
                        "text": turnText,
                        "distance": accumulatedDistance,
                        "time": calculateTime(distance: accumulatedDistance, profile: "car") * 1000,
                        "sign": turnSign,
                        "streetName": "",
                        "turnAngle": angle
                    ])

                    accumulatedDistance = 0
                    lastTurnIndex = i
                }
            }
        }

        // Arrive instruction
        instructions.append([
            "text": "Arrive at destination",
            "distance": accumulatedDistance,
            "time": calculateTime(distance: accumulatedDistance, profile: "car") * 1000,
            "sign": 4,
            "streetName": ""
        ])

        return instructions
    }

    /// Calculates turn angle between three points.
    private func calculateTurnAngle(
        from: RoutingGraph.Node,
        through: RoutingGraph.Node,
        to: RoutingGraph.Node
    ) -> Double {
        let bearing1 = calculateBearing(from: from, to: through)
        let bearing2 = calculateBearing(from: through, to: to)
        var angle = bearing2 - bearing1

        // Normalize to -180 to 180
        while angle > 180 { angle -= 360 }
        while angle < -180 { angle += 360 }

        return angle
    }

    /// Calculates bearing between two points.
    private func calculateBearing(from: RoutingGraph.Node, to: RoutingGraph.Node) -> Double {
        let lat1 = from.lat * .pi / 180
        let lat2 = to.lat * .pi / 180
        let dLon = (to.lon - from.lon) * .pi / 180

        let x = sin(dLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        return atan2(x, y) * 180 / .pi
    }

    /// Calculates bounding box for a list of points.
    private func calculateBbox(points: [RoutingGraph.Node]) -> [Double] {
        guard !points.isEmpty else { return [0, 0, 0, 0] }

        var minLat = points[0].lat
        var maxLat = points[0].lat
        var minLon = points[0].lon
        var maxLon = points[0].lon

        for point in points {
            minLat = min(minLat, point.lat)
            maxLat = max(maxLat, point.lat)
            minLon = min(minLon, point.lon)
            maxLon = max(maxLon, point.lon)
        }

        return [minLon, minLat, maxLon, maxLat]
    }

    /// Extracts a ZIP file to a directory.
    private func extractZip(from sourceURL: URL, to destinationURL: URL) throws {
        // Use built-in ZIP support (iOS 11+)
        let fileManager = FileManager.default

        // Check if file has .ghz extension (it's a zip)
        let data = try Data(contentsOf: sourceURL)

        // Write to temp .zip file
        let tempZipURL = destinationURL.appendingPathComponent("temp.zip")
        try data.write(to: tempZipURL)

        // Use Archive utility
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", tempZipURL.path, "-d", destinationURL.path]

        // For iOS, we need to use a different approach since Process isn't available
        // Instead, use FileManager's unzipItem or a manual implementation

        // Simple manual unzip for iOS
        try unzipFile(at: tempZipURL, to: destinationURL)

        // Clean up temp file
        try? fileManager.removeItem(at: tempZipURL)
    }

    /// Manual ZIP extraction for iOS.
    private func unzipFile(at sourceURL: URL, to destinationURL: URL) throws {
        // Note: For production, use a proper ZIP library like ZIPFoundation
        // This is a simplified implementation that assumes the .ghz contains
        // a simple directory structure

        let fileManager = FileManager.default
        let sourceData = try Data(contentsOf: sourceURL)

        // For now, just copy the data as-is (the actual implementation
        // should use a proper ZIP library)
        // In a real implementation, you would:
        // 1. Add ZIPFoundation dependency
        // 2. Use: try FileManager.default.unzipItem(at: sourceURL, to: destinationURL)

        NSLog("[RoutingEngine] Note: ZIP extraction requires ZIPFoundation library for production use")

        // Create a placeholder graph file for testing
        let graphFile = destinationURL.appendingPathComponent("graph.bin")
        try sourceData.write(to: graphFile)
    }
}

// MARK: - A* Helper Structures

/// Node for A* priority queue.
private struct AStarNode: Comparable {
    let nodeId: Int
    let fScore: Double

    static func < (lhs: AStarNode, rhs: AStarNode) -> Bool {
        return lhs.fScore < rhs.fScore
    }

    static func == (lhs: AStarNode, rhs: AStarNode) -> Bool {
        return lhs.nodeId == rhs.nodeId
    }
}

/// Simple priority queue implementation.
private struct PriorityQueue<T: Comparable> {
    private var heap: [T] = []

    var isEmpty: Bool { heap.isEmpty }

    mutating func enqueue(_ element: T) {
        heap.append(element)
        siftUp(heap.count - 1)
    }

    mutating func dequeue() -> T? {
        guard !heap.isEmpty else { return nil }

        if heap.count == 1 {
            return heap.removeLast()
        }

        let first = heap[0]
        heap[0] = heap.removeLast()
        siftDown(0)
        return first
    }

    private mutating func siftUp(_ index: Int) {
        var child = index
        var parent = (child - 1) / 2

        while child > 0 && heap[child] < heap[parent] {
            heap.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }

    private mutating func siftDown(_ index: Int) {
        var parent = index
        let count = heap.count

        while true {
            let left = 2 * parent + 1
            let right = 2 * parent + 2
            var smallest = parent

            if left < count && heap[left] < heap[smallest] {
                smallest = left
            }
            if right < count && heap[right] < heap[smallest] {
                smallest = right
            }

            if smallest == parent { break }

            heap.swapAt(parent, smallest)
            parent = smallest
        }
    }
}
