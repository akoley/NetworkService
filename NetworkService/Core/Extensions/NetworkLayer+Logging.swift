import Foundation
extension NetworkLayer {

    func logError(parameterType: ParameterType?,
                  parameters: Any? = nil,
                  data: Data?,
                  request: URLRequest?,
                  response: URLResponse?, error: NSError?) {

        guard isErrorLoggingEnabled else { return }
        guard let error = error else { return }

        let isCancelled = error.code == NSURLErrorCancelled
        if isCancelled {
            if let request = request, let url = request.url {
                print("Cancelled request: \(url.absoluteString)")
            }
        } else {
            print("Error \(error.code): \(error.description)")

            if let request = request, let url = request.url {
                print("URL: \(url.absoluteString)")
            }

            if let headers = request?.allHTTPHeaderFields {
                print("Headers: \(headers)")
            }

            if let parameterType = parameterType, let parameters = parameters {
                switch parameterType {
                case .json:
                    do {
                        let data = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                        let string = String(data: data, encoding: .utf8)
                        if let string = string {
                            print("Parameters: \(string)")
                        }
                    } catch let error as NSError {
                        print("Failed pretty printing parameters: \(parameters), error: \(error)")
                    }
                case .formURLEncoded:
                    guard let parametersDictionary = parameters as? [String: Any] else {
                        fatalError("Couldn't cast parameters as dictionary: \(parameters)")
                    }
                    do {
                        let formattedParameters = try parametersDictionary.urlEncodedString()
                        print("Parameters: \(formattedParameters)")
                    } catch let error as NSError {
                        print("Failed parsing Parameters: \(parametersDictionary) — \(error)")
                    }
                    print(" ")
                default: break
                }
            }

            if let data = data, let stringData = String(data: data, encoding: .utf8) {
                print("Data: \(stringData)")
            }

            if let response = response as? HTTPURLResponse {
                print("Response Headers: \(response.allHeaderFields)")
                print("Response Status code: \(response.statusCode) — \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))")
            }
        }
    }
}
