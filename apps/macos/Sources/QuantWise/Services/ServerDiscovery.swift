import Foundation

/// Scans localhost ports 3001-3005 for a running QuantWise HTTP server.
actor ServerDiscovery {
    static let portRange = 3001 ... 3005

    func discover() async -> URL? {
        // Try all ports concurrently
        return await withTaskGroup(of: (Int, Bool).self) { group in
            for port in Self.portRange {
                group.addTask {
                    let ok = await self.checkHealth(port: port)
                    return (port, ok)
                }
            }
            var found: Int?
            for await (port, ok) in group {
                if ok, found == nil || port < (found ?? Int.max) {
                    found = port
                }
            }
            guard let port = found else { return nil }
            return URL(string: "http://localhost:\(port)")
        }
    }

    private func checkHealth(port: Int) async -> Bool {
        guard let url = URL(string: "http://localhost:\(port)/health") else { return false }
        var req = URLRequest(url: url)
        req.timeoutInterval = 2
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return false }
            let health = try JSONDecoder().decode(HealthResponse.self, from: data)
            return health.status == "ok"
        } catch {
            return false
        }
    }
}
