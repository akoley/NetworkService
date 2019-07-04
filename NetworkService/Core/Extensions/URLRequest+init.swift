import Foundation

extension URLRequest {
    init(url: URL,
         requestType: RequestType,
         path _: String,
         parameterType: ParameterType?,
         responseType: ResponseType,
         boundary: String,
         authorizationHeaderValue: String?,
         token: String?,
         authorizationHeaderKey: String,
         headerFields: [String: String]?) {

        self = URLRequest(url: url)
        httpMethod = requestType.rawValue

        if let parameterType = parameterType,
            let contentType = parameterType.contentType(boundary) {
            addValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let accept = responseType.accept {
            addValue(accept, forHTTPHeaderField: "Accept")
        }

        if let authorizationHeader = authorizationHeaderValue {
            setValue(authorizationHeader, forHTTPHeaderField: authorizationHeaderKey)
        } else if let token = token {
            setValue("Bearer \(token)", forHTTPHeaderField: authorizationHeaderKey)
        }

        if let headerFields = headerFields {
            for (key, value) in headerFields {
                setValue(value, forHTTPHeaderField: key)
            }
        }
    }
}
