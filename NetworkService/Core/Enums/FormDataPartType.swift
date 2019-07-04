import Foundation

public enum FormDataPartType {
    case data
    case png
    case jpg
    case custom(String)

    var contentType: String {
        switch self {
        case .data:
            return "application/octet-stream"
        case .png:
            return "image/png"
        case .jpg:
            return "image/jpeg"
        case let .custom(value):
            return value
        }
    }
}
