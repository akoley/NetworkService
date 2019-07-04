@testable import NetworkService

struct TestUtil {
    static func removeFileIfNeeded(_ networkLayer: NetworkLayer,
                                   path: String,
                                   cacheName: String? = nil) throws {
        guard let destinationURL = try? networkLayer.destinationURL(
            for: path, cacheName: cacheName) else {
                fatalError("Couldn't get destination URL for path: \(path) and cacheName: \(String(describing: cacheName))")
        }
        if FileManager.default.exists(at: destinationURL) {
            try FileManager.default.remove(at: destinationURL)
        }
    }
}
