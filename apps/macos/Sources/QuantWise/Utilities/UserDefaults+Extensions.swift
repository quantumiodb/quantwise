import Foundation

extension UserDefaults {
    private enum Keys {
        static let serverPort = "serverPort"
        static let apiToken = "apiToken"
    }

    var serverPort: Int {
        get {
            let v = integer(forKey: Keys.serverPort)
            return v == 0 ? 3001 : v
        }
        set { set(newValue, forKey: Keys.serverPort) }
    }

    var apiToken: String? {
        get { string(forKey: Keys.apiToken) ?? "mysecret" }
        set { set(newValue, forKey: Keys.apiToken) }
    }
}
