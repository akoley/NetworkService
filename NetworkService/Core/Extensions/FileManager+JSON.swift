import Foundation

extension FileManager {

    static func json(from fileName: String,
                     bundle: Bundle = Bundle.main) throws -> Any? {
        var json: Any?
        guard let url = URL(string: fileName),
            let filePath = bundle.path(
                forResource: url.deletingPathExtension().absoluteString,
                ofType: url.pathExtension) else { throw ParsingError.fileNotFound }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { throw ParsingError.failed }

        json = try data.toJSON()

        return json
    }

    public func exists(at url: URL) -> Bool {
        let path = url.path
        return fileExists(atPath: path)
    }

    public func remove(at url: URL) throws {
        let path = url.path
        guard FileManager.default.isDeletableFile(atPath: url.path) else { return }

        try FileManager.default.removeItem(atPath: path)
    }
}
