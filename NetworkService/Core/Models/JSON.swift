import Foundation

func == (lhs: JSON, rhs: JSON) -> Bool {
    return lhs.array.debugDescription == rhs.array.debugDescription
        && lhs.dictionary.debugDescription == rhs.dictionary.debugDescription
}

enum JSON: Equatable {
    case none

    case dictionary(Data, [String: Any])

    case array(Data, [[String: Any]])

    var dictionary: [String: Any] {
        switch self {
        case let .dictionary(_, body):
            return body
        default:
            return [String: Any]()
        }
    }

    var array: [[String: Any]] {
        switch self {
        case let .array(_, body):
            return body
        default:
            return [[String: Any]]()
        }
    }

    init(_ data: Data) throws {
        let body = try JSONSerialization.jsonObject(with: data, options: [])

        if let dictionary = body as? [String: Any] {
            self = .dictionary(data, dictionary)
        } else if let array = body as? [[String: Any]] {
            self = .array(data, array)
        } else {
            self = JSON.none
        }
    }

    init(_ dictionary: [String: Any]) {
        let data = try! JSONSerialization.data(withJSONObject: dictionary, options: [])

        self = .dictionary(data, dictionary)
    }

    init(_ array: [[String: Any]]) {
        let data = try! JSONSerialization.data(withJSONObject: array, options: [])

        self = .array(data, array)
    }
}
