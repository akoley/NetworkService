import Foundation

extension Data {

    // Serializes Data into JSON
    public func toJSON() throws -> Any? {
        var json: Any?
        do {
            json = try JSONSerialization.jsonObject(with: self, options: [])
        } catch {
            throw ParsingError.failed
        }
        return json
    }
}
