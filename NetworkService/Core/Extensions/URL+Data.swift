import Foundation

extension URL {
    func getData() -> Data {
        let path = self.path
        guard let data = FileManager.default.contents(atPath: path) else {
            fatalError("Couldn't get image in destination url: \(self)") }

        return data
    }
}
