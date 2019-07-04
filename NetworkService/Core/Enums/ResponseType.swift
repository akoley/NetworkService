import Foundation

public enum ResponseType {
    case json
    case data
    case image

    var accept: String? {
        switch self {
        case .json:
            return "application/json"
        default:
            return nil
        }
    }
}
