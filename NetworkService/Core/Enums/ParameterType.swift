import Foundation

public enum ParameterType {
    case none, json, formURLEncoded, multipartFormData, custom(String)

    func contentType(_ boundary: String) -> String? {
        switch self {
        case .none:
            return nil
        case .json:
            return "application/json"
        case .formURLEncoded:
            return "application/x-www-form-urlencoded"
        case .multipartFormData:
            return "multipart/form-data; boundary=\(boundary)"
        case let .custom(value):
            return value
        }
    }
}
