import Foundation

/// Road type classifications for routing.
enum RoadType: Int {
    case motorway = 1
    case trunk = 2
    case primary = 3
    case secondary = 4
    case tertiary = 5
    case residential = 6
    case unclassified = 7
    case footway = 8
    case cycleway = 9
    case path = 10
    case service = 11
    case other = 0

    static func from(_ value: Int) -> RoadType {
        return RoadType(rawValue: value) ?? .other
    }
}

/// Geographic bounding box.
struct GeoBounds {
    let minLat: Double
    let minLon: Double
    let maxLat: Double
    let maxLon: Double

    init(minLat: Double, minLon: Double, maxLat: Double, maxLon: Double) {
        self.minLat = minLat
        self.minLon = minLon
        self.maxLat = maxLat
        self.maxLon = maxLon
    }

    func contains(lat: Double, lon: Double) -> Bool {
        return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
    }
}

/// Routing graph loaded from a .ghz file.
///
/// The graph consists of nodes (intersections) and edges (road segments).
/// This implementation uses an adjacency list representation for efficient
/// neighbor lookups during A* pathfinding.
class RoutingGraph {
    /// A node in the routing graph (intersection).
    struct Node {
        let id: Int
        let lat: Double
        let lon: Double
    }

    /// An edge in the routing graph (road segment).
    struct Edge {
        let fromNodeId: Int
        let toNodeId: Int
        let distance: Double
        let roadType: RoadType
        let maxSpeed: Int
        let isOneway: Bool
    }

    /// Spatial index cell for efficient nearest neighbor search.
    private struct SpatialCell {
        var nodeIds: [Int] = []
    }

    // Graph data
    private var nodes: [Int: Node] = [:]
    private var adjacencyList: [Int: [Edge]] = [:]

    // Spatial index for fast nearest node lookup
    private var spatialIndex: [[SpatialCell]] = []
    private let cellSize = 0.01 // ~1km cell size
    private var indexBounds: GeoBounds?

    // Graph metadata
    private(set) var bounds: GeoBounds = GeoBounds(minLat: 0, minLon: 0, maxLat: 0, maxLon: 0)
    private(set) var nodeCount: Int = 0
    private(set) var edgeCount: Int = 0

    /// Initializes a graph from a directory containing graph files.
    init(directory: URL) throws {
        try loadGraph(from: directory)
        buildSpatialIndex()
    }

    // MARK: - Graph Loading

    /// Loads the graph from binary files.
    private func loadGraph(from directory: URL) throws {
        let fileManager = FileManager.default

        // Look for graph files
        let graphFile = directory.appendingPathComponent("graph.bin")
        let nodesFile = directory.appendingPathComponent("nodes.bin")
        let edgesFile = directory.appendingPathComponent("edges.bin")

        if fileManager.fileExists(atPath: graphFile.path) {
            // Single combined file format
            try loadCombinedFormat(from: graphFile)
        } else if fileManager.fileExists(atPath: nodesFile.path) &&
                    fileManager.fileExists(atPath: edgesFile.path) {
            // Separate files format
            try loadSeparateFormat(nodesFile: nodesFile, edgesFile: edgesFile)
        } else {
            // Try to parse any available data files
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            if let firstFile = contents.first {
                try loadGenericFormat(from: firstFile)
            } else {
                throw RoutingError.invalidData("No graph files found in directory")
            }
        }

        nodeCount = nodes.count
        edgeCount = adjacencyList.values.reduce(0) { $0 + $1.count }

        NSLog("[RoutingGraph] Loaded graph: \(nodeCount) nodes, \(edgeCount) edges")
    }

    /// Loads a combined binary graph file.
    private func loadCombinedFormat(from url: URL) throws {
        let data = try Data(contentsOf: url)
        var offset = 0

        // Read header
        let nodeCountValue = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
        offset += 4
        let edgeCountValue = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
        offset += 4

        // Read bounds
        let minLat = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
        offset += 8
        let minLon = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
        offset += 8
        let maxLat = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
        offset += 8
        let maxLon = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
        offset += 8

        bounds = GeoBounds(minLat: minLat, minLon: minLon, maxLat: maxLat, maxLon: maxLon)

        // Read nodes
        for i in 0..<Int(nodeCountValue) {
            let lat = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
            offset += 8
            let lon = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
            offset += 8

            nodes[i] = Node(id: i, lat: lat, lon: lon)
            adjacencyList[i] = []
        }

        // Read edges
        for _ in 0..<Int(edgeCountValue) {
            let fromId = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) })
            offset += 4
            let toId = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) })
            offset += 4
            let distance = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
            offset += 8
            let roadTypeValue = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int8.self) })
            offset += 1
            let maxSpeed = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int8.self) })
            offset += 1
            let onewayFlag = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt8.self) }
            offset += 1

            let edge = Edge(
                fromNodeId: fromId,
                toNodeId: toId,
                distance: distance,
                roadType: RoadType.from(roadTypeValue),
                maxSpeed: maxSpeed,
                isOneway: onewayFlag != 0
            )

            adjacencyList[fromId]?.append(edge)

            // Add reverse edge if not oneway
            if onewayFlag == 0 {
                let reverseEdge = Edge(
                    fromNodeId: toId,
                    toNodeId: fromId,
                    distance: distance,
                    roadType: RoadType.from(roadTypeValue),
                    maxSpeed: maxSpeed,
                    isOneway: false
                )
                adjacencyList[toId]?.append(reverseEdge)
            }
        }
    }

    /// Loads separate node and edge files.
    private func loadSeparateFormat(nodesFile: URL, edgesFile: URL) throws {
        // Load nodes
        let nodesData = try Data(contentsOf: nodesFile)
        var offset = 0

        let nodeCountValue = nodesData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
        offset += 4

        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLon = Double.infinity
        var maxLon = -Double.infinity

        for i in 0..<Int(nodeCountValue) {
            let lat = nodesData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
            offset += 8
            let lon = nodesData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
            offset += 8

            nodes[i] = Node(id: i, lat: lat, lon: lon)
            adjacencyList[i] = []

            minLat = min(minLat, lat)
            maxLat = max(maxLat, lat)
            minLon = min(minLon, lon)
            maxLon = max(maxLon, lon)
        }

        bounds = GeoBounds(minLat: minLat, minLon: minLon, maxLat: maxLat, maxLon: maxLon)

        // Load edges
        let edgesData = try Data(contentsOf: edgesFile)
        offset = 0

        let edgeCountValue = edgesData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
        offset += 4

        for _ in 0..<Int(edgeCountValue) {
            let fromId = Int(edgesData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) })
            offset += 4
            let toId = Int(edgesData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) })
            offset += 4
            let distance = edgesData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Double.self) }
            offset += 8

            let edge = Edge(
                fromNodeId: fromId,
                toNodeId: toId,
                distance: distance,
                roadType: .unclassified,
                maxSpeed: 50,
                isOneway: false
            )

            adjacencyList[fromId]?.append(edge)

            // Add reverse edge
            let reverseEdge = Edge(
                fromNodeId: toId,
                toNodeId: fromId,
                distance: distance,
                roadType: .unclassified,
                maxSpeed: 50,
                isOneway: false
            )
            adjacencyList[toId]?.append(reverseEdge)
        }
    }

    /// Generic format loader (fallback).
    private func loadGenericFormat(from url: URL) throws {
        // Try to read as plain text or JSON
        let data = try Data(contentsOf: url)

        // Check if it's JSON
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            try loadJSONFormat(json)
            return
        }

        // Try as binary
        try loadCombinedFormat(from: url)
    }

    /// Loads graph from JSON format.
    private func loadJSONFormat(_ json: [String: Any]) throws {
        guard let nodesArray = json["nodes"] as? [[String: Any]],
              let edgesArray = json["edges"] as? [[String: Any]] else {
            throw RoutingError.invalidData("Invalid JSON graph format")
        }

        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLon = Double.infinity
        var maxLon = -Double.infinity

        for (index, nodeDict) in nodesArray.enumerated() {
            guard let lat = nodeDict["lat"] as? Double,
                  let lon = nodeDict["lon"] as? Double else { continue }

            let id = nodeDict["id"] as? Int ?? index
            nodes[id] = Node(id: id, lat: lat, lon: lon)
            adjacencyList[id] = []

            minLat = min(minLat, lat)
            maxLat = max(maxLat, lat)
            minLon = min(minLon, lon)
            maxLon = max(maxLon, lon)
        }

        bounds = GeoBounds(minLat: minLat, minLon: minLon, maxLat: maxLat, maxLon: maxLon)

        for edgeDict in edgesArray {
            guard let fromId = edgeDict["from"] as? Int,
                  let toId = edgeDict["to"] as? Int else { continue }

            let distance = edgeDict["distance"] as? Double ?? 0
            let roadTypeValue = edgeDict["type"] as? Int ?? 0
            let maxSpeed = edgeDict["maxSpeed"] as? Int ?? 50
            let oneway = edgeDict["oneway"] as? Bool ?? false

            let edge = Edge(
                fromNodeId: fromId,
                toNodeId: toId,
                distance: distance,
                roadType: RoadType.from(roadTypeValue),
                maxSpeed: maxSpeed,
                isOneway: oneway
            )

            adjacencyList[fromId]?.append(edge)

            if !oneway {
                let reverseEdge = Edge(
                    fromNodeId: toId,
                    toNodeId: fromId,
                    distance: distance,
                    roadType: RoadType.from(roadTypeValue),
                    maxSpeed: maxSpeed,
                    isOneway: false
                )
                adjacencyList[toId]?.append(reverseEdge)
            }
        }
    }

    // MARK: - Spatial Index

    /// Builds a spatial index for fast nearest neighbor search.
    private func buildSpatialIndex() {
        guard !nodes.isEmpty else { return }

        indexBounds = bounds

        // Calculate grid size
        let latCells = Int(ceil((bounds.maxLat - bounds.minLat) / cellSize)) + 1
        let lonCells = Int(ceil((bounds.maxLon - bounds.minLon) / cellSize)) + 1

        // Initialize grid
        spatialIndex = Array(repeating: Array(repeating: SpatialCell(), count: lonCells), count: latCells)

        // Populate grid
        for (id, node) in nodes {
            let latIndex = Int((node.lat - bounds.minLat) / cellSize)
            let lonIndex = Int((node.lon - bounds.minLon) / cellSize)

            if latIndex >= 0 && latIndex < latCells && lonIndex >= 0 && lonIndex < lonCells {
                spatialIndex[latIndex][lonIndex].nodeIds.append(id)
            }
        }

        NSLog("[RoutingGraph] Built spatial index: \(latCells)x\(lonCells) cells")
    }

    // MARK: - Public API

    /// Gets a node by ID.
    func node(id: Int) -> Node? {
        return nodes[id]
    }

    /// Gets edges from a node.
    func edges(from nodeId: Int) -> [Edge] {
        return adjacencyList[nodeId] ?? []
    }

    /// Finds the nearest node to a coordinate.
    func findNearestNode(lat: Double, lon: Double) -> Node? {
        guard let indexBounds = indexBounds else {
            return findNearestNodeBruteForce(lat: lat, lon: lon)
        }

        // Find cell
        let latIndex = Int((lat - indexBounds.minLat) / cellSize)
        let lonIndex = Int((lon - indexBounds.minLon) / cellSize)

        // Search in expanding rings
        var minDistance = Double.infinity
        var nearestNode: Node?

        for radius in 0...5 {
            for dLat in -radius...radius {
                for dLon in -radius...radius {
                    if abs(dLat) != radius && abs(dLon) != radius { continue }

                    let cellLat = latIndex + dLat
                    let cellLon = lonIndex + dLon

                    guard cellLat >= 0 && cellLat < spatialIndex.count &&
                          cellLon >= 0 && cellLon < spatialIndex[cellLat].count else { continue }

                    for nodeId in spatialIndex[cellLat][cellLon].nodeIds {
                        guard let node = nodes[nodeId] else { continue }
                        let distance = sqrt(pow(node.lat - lat, 2) + pow(node.lon - lon, 2))
                        if distance < minDistance {
                            minDistance = distance
                            nearestNode = node
                        }
                    }
                }
            }

            if nearestNode != nil { break }
        }

        return nearestNode ?? findNearestNodeBruteForce(lat: lat, lon: lon)
    }

    /// Brute force nearest node search (fallback).
    private func findNearestNodeBruteForce(lat: Double, lon: Double) -> Node? {
        var minDistance = Double.infinity
        var nearestNode: Node?

        for (_, node) in nodes {
            let distance = sqrt(pow(node.lat - lat, 2) + pow(node.lon - lon, 2))
            if distance < minDistance {
                minDistance = distance
                nearestNode = node
            }
        }

        return nearestNode
    }
}
