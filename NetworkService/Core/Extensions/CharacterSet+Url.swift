import Foundation

extension CharacterSet {
    static var urlQueryParametersAllowed: CharacterSet {
        // Does not include "?" or "/"
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowedCharacterSet
    }
}
