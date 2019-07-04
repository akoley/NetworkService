import Foundation

extension NetworkLayer {

    func handleJSONRequest(_ requestType: RequestType,
                           path: String,
                           cacheName: String?,
                           parameterType: ParameterType?,
                           parameters: Any?,
                           parts: [FormDataPart]? = nil,
                           responseType: ResponseType,
                           cachingType: CachingType,
                           completion: @escaping (_ result: JSONResult) -> Void) -> String {

        switch cachingType {
        case .memory, .memoryAndFile:
            if let object = objectFromCache(
                for: path,
                cacheName: nil,
                cachingType: cachingType,
                responseType: responseType) {

                TestingManager.operationBlock(isSynchronous) {
                    let url = try! self.getEncodedURL(with: path)
                    let response = HTTPURLResponse(url: url, statusCode: 200)
                    completion(JSONResult(body: object, response: response, error: nil))
                }
            }
        default: break
        }

        return requestData(
            requestType,
            path: path,
            cachingType: cachingType,
            parameterType: parameterType,
            parameters: parameters,
            parts: parts,
            responseType: responseType) { data, response, error in

            TestingManager.operationBlock(self.isSynchronous) {
                completion(JSONResult(body: data, response: response, error: error))
            }
        }
    }

    func handleImageRequest(_ requestType: RequestType,
                            path: String,
                            cacheName: String?,
                            cachingType: CachingType,
                            responseType: ResponseType,
                            completion: @escaping (_ result: ImageResult) -> Void) -> String {

        let object = objectFromCache(for: path,
                                     cacheName: cacheName,
                                     cachingType: cachingType,
                                     responseType: responseType)
        if let object = object {
           TestingManager.operationBlock(isSynchronous) {
                let url = try! self.getEncodedURL(with: path)
                let response = HTTPURLResponse(url: url, statusCode: 200)
                completion(ImageResult(body: object, response: response, error: nil))
            }

            let requestID = UUID().uuidString
            return requestID
        } else {
            return requestData(requestType,
                               path: path,
                               cachingType: cachingType,
                               parameterType: nil,
                               parameters: nil,
                               parts: nil,
                               responseType: responseType) { data, response, error in
                let returnedImage = self.cacheOrPurgeImage(
                    data: data,
                    path: path,
                    cacheName: cacheName,
                    cachingType: cachingType)

                TestingManager.operationBlock(self.isSynchronous) {
                    completion(ImageResult(body: returnedImage, response: response, error: error))
                }
            }
        }
    }

    func objectFromCache(for path: String,
                         cacheName: String?,
                         cachingType: CachingType,
                         responseType: ResponseType) -> Any? {
        guard let destinationURL = try? destinationURL(
            for: path,
            cacheName: cacheName) else {
                fatalError(
                    "Couldn't get destination URL for path: \(path) and cacheName: \(String(describing: cacheName))")
        }

        switch cachingType {
        case .memory:
            try? FileManager.default.remove(at: destinationURL)
            return cache.object(forKey: destinationURL.absoluteString as AnyObject)
        case .memoryAndFile:
            if let object = cache.object(forKey: destinationURL.absoluteString as AnyObject) {
                return object
            } else if FileManager.default.exists(at: destinationURL) {
                var returnedObject: Any?

                let object = destinationURL.getData()
                if responseType == .image {
                    returnedObject = Image(data: object)
                } else {
                    returnedObject = object
                }
                if let returnedObject = returnedObject {
                    cache.setObject(returnedObject as AnyObject,
                                    forKey: destinationURL.absoluteString as AnyObject)
                }
                return returnedObject
            } else {
                return nil
            }
        case .none:
            cache.removeObject(forKey: destinationURL.absoluteString as AnyObject)
            try? FileManager.default.remove(at: destinationURL)
            return nil
        }
    }

    func handleDataRequest(_ requestType: RequestType,
                           path: String,
                           cacheName: String?,
                           cachingType: CachingType,
                           responseType: ResponseType, completion: @escaping (_ result: DataResult) -> Void) -> String {

        let object = objectFromCache(for: path,
                                     cacheName: cacheName,
                                     cachingType: cachingType,
                                     responseType: responseType)
        if let object = object {
            TestingManager.operationBlock(isSynchronous) {
                let url = try! self.getEncodedURL(with: path)
                let response = HTTPURLResponse(url: url, statusCode: 200)
                completion(DataResult(body: object, response: response, error: nil))
            }
            let requestID = UUID().uuidString
            return requestID
        } else {
            return requestData(requestType,
                               path: path,
                               cachingType: cachingType,
                               parameterType: nil,
                               parameters: nil,
                               parts: nil,
                               responseType: responseType) { data, response, error in
                self.cacheOrPurgeData(data: data,
                                      path: path,
                                      cacheName: cacheName,
                                      cachingType: cachingType)

                TestingManager.operationBlock(self.isSynchronous) {
                    completion(DataResult(body: data, response: response, error: error))
                }
            }
        }
    }

    func requestData(_ requestType: RequestType,
                     path: String,
                     cachingType: CachingType,
                     parameterType: ParameterType?,
                     parameters: Any?,
                     parts: [FormDataPart]?,
                     responseType: ResponseType,
                     completion: @escaping (_ response: Data?, _ response: HTTPURLResponse, _ error: NSError?) -> Void) -> String {
        let requestID = UUID().uuidString
        var request = URLRequest(
            url: try! getEncodedURL(with: path),
            requestType: requestType, path: path,
            parameterType: parameterType,
            responseType: responseType,
            boundary: boundary,
            authorizationHeaderValue: authorizationHeaderValue,
            token: token,
            authorizationHeaderKey: authorizationHeaderKey,
            headerFields: headerFields
        )

        var serializingError: NSError?
        if let parameterType = parameterType {
            switch parameterType {
            case .none: break
            case .json:
                if let parameters = parameters {
                    do {
                        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                    } catch let error as NSError {
                        serializingError = error
                    }
                }
            case .formURLEncoded:
                guard let parametersDictionary = parameters as? [String: Any] else {
                    fatalError("Couldn't convert parameters to a dictionary: \(String(describing: parameters))")
                }
                do {
                    let formattedParameters = try parametersDictionary.urlEncodedString()
                    switch requestType {
                    case .get, .delete:
                        let urlEncodedPath: String
                        if path.contains("?") {
                            if let lastCharacter = path.last, lastCharacter == "?" {
                                urlEncodedPath = path + formattedParameters
                            } else {
                                urlEncodedPath = path + "&" + formattedParameters
                            }
                        } else {
                            urlEncodedPath = path + "?" + formattedParameters
                        }
                        request.url = try! getEncodedURL(with: urlEncodedPath)
                    case .post, .put, .patch:
                        request.httpBody = formattedParameters.data(using: .utf8)
                    }
                } catch let error as NSError {
                    serializingError = error
                }
            case .multipartFormData:
                var bodyData = Data()

                if let parameters = parameters as? [String: Any] {
                    for (key, value) in parameters {
                        let usedValue: Any = value is NSNull ? "null" : value
                        var body = ""
                        body += "--\(boundary)\r\n"
                        body += "Content-Disposition: form-data; name=\"\(key)\""
                        body += "\r\n\r\n\(usedValue)\r\n"
                        bodyData.append(body.data(using: .utf8)!)
                    }
                }

                if let parts = parts {
                    for var part in parts {
                        part.boundary = boundary
                        bodyData.append(part.formData as Data)
                    }
                }

                bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
                request.httpBody = bodyData as Data
            case .custom:
                request.httpBody = parameters as? Data
            }
        }

        if let serializingError = serializingError {
            let url = try! getEncodedURL(with: path)
            let response = HTTPURLResponse(url: url, statusCode: serializingError.code)
            completion(nil, response, serializingError)
        } else {
            var connectionError: Error?
            let semaphore = DispatchSemaphore(value: 0)
            var returnedResponse: URLResponse?
            var returnedData: Data?

            let session = self.session.dataTask(with: request) { data, response, error in
                returnedResponse = response
                connectionError = error
                returnedData = data

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        if let data = data, data.count > 0 {
                            returnedData = data
                        }
                    } else {
                        var errorCode = httpResponse.statusCode
                        if let error = error as NSError?, error.code == URLError.cancelled.rawValue {
                            errorCode = error.code
                        }

                        connectionError = NSError(
                            domain: NetworkLayer.domain,
                            code: errorCode,
                            userInfo: [
                                NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(
                                    forStatusCode: httpResponse.statusCode)
                            ])
                    }
                }
                self.cacheOrPurgeData(data: data, path: path, cacheName: nil, cachingType: cachingType)

                if TestingManager.isInTestingMode && self.isSynchronous == false {
                    semaphore.signal()
                } else {
                    self.logError(
                        parameterType: parameterType,
                        parameters: parameters,
                        data: returnedData,
                        request: request,
                        response: returnedResponse,
                        error: connectionError as NSError?
                    )

                    if let unauthorizedRequestCallback = self.unauthorizedRequestCallback,
                        let error = connectionError as NSError?, error.code == 403 || error.code == 401 {
                        unauthorizedRequestCallback()
                    } else {
                        if let response = returnedResponse as? HTTPURLResponse {
                            completion(returnedData, response, connectionError as NSError?)
                        } else {
                            let url = try! self.getEncodedURL(with: path)
                            let errorCode = (connectionError as NSError?)?.code ?? 200
                            let response = HTTPURLResponse(url: url, statusCode: errorCode)
                            completion(returnedData, response, connectionError as NSError?)
                        }
                    }
                }
            }
            session.taskDescription = requestID
            session.resume()

            if TestingManager.isInTestingMode && isSynchronous == false {
                _ = semaphore.wait(timeout: DispatchTime.now() + 60.0)
                logError(
                    parameterType: parameterType,
                    parameters: parameters,
                    data: returnedData,
                    request: request as URLRequest,
                    response: returnedResponse,
                    error: connectionError as NSError?
                )
                if let unauthorizedRequestCallback = unauthorizedRequestCallback,
                    let error = connectionError as NSError?, error.code == 403 || error.code == 401 {
                    unauthorizedRequestCallback()
                } else {
                    if let response = returnedResponse as? HTTPURLResponse {
                        completion(returnedData, response, connectionError as NSError?)
                    } else {
                        let url = try! getEncodedURL(with: path)
                        let errorCode = (connectionError as NSError?)?.code ?? 200
                        let response = HTTPURLResponse(url: url, statusCode: errorCode)
                        completion(returnedData, response, connectionError as NSError?)
                    }
                }
            }
        }
        return requestID
    }

    func cancelRequest(_ sessionTaskType: SessionTaskType, requestType: RequestType, url: URL) {

        let semaphore = DispatchSemaphore(value: 0)
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            var sessionTasks = [URLSessionTask]()
            switch sessionTaskType {
            case .data:
                sessionTasks = dataTasks
            case .download:
                sessionTasks = downloadTasks
            case .upload:
                sessionTasks = uploadTasks
            }

            for sessionTask in sessionTasks {
                if sessionTask.originalRequest?.httpMethod == requestType.rawValue
                    && sessionTask.originalRequest?.url?.absoluteString == url.absoluteString {
                    sessionTask.cancel()
                    break
                }
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.now() + 60.0)
    }
}
