import Foundation

// MARK: API requests
public extension NetworkLayer {

    @discardableResult
    func createRequest(_ requestType: RequestType,
                       path: String,
                       parameters: Any? = nil,
                       cachingType: CachingType = .none,
                       completion: @escaping (_ result: JSONResult) -> Void) -> String {

        let parameterType: ParameterType = parameters != nil ? .formURLEncoded : .none

        return handleJSONRequest(requestType,
                                 path: path,
                                 cacheName: nil,
                                 parameterType: parameterType,
                                 parameters: parameters,
                                 responseType: .json,
                                 cachingType: cachingType,
                                 completion: completion)
    }

    func cancelRequest(_ requestType: RequestType, path: String) {
        let url = try! getEncodedURL(with: path)
        cancelRequest(.data, requestType: requestType, url: url)
    }
}

// MARK: Image requests

public extension NetworkLayer {

    @discardableResult
    func getImage(_ path: String,
                  cacheName: String? = nil,
                  cachingType: CachingType = .memoryAndFile,
                  completion: @escaping (_ result: ImageResult) -> Void) -> String {
        return handleImageRequest(.get,
                                  path: path,
                                  cacheName: cacheName,
                                  cachingType: cachingType,
                                  responseType: .image,
                                  completion: completion)
    }

    func cancelImageRequest(_ path: String) {
        let url = try! getEncodedURL(with: path)
        cancelRequest(.data, requestType: .get, url: url)
    }

    func getImageFromCache(_ path: String,
                           cacheName: String? = nil) -> Image? {
        let object = objectFromCache(for: path,
                                     cacheName: cacheName,
                                     cachingType: .memoryAndFile,
                                     responseType: .image)

        return object as? Image
    }
}

// MARK: Data requests

public extension NetworkLayer {

    @discardableResult
    func downloadData(_ path: String,
                      cacheName: String? = nil,
                      cachingType: CachingType = .memoryAndFile,
                      completion: @escaping (_ result: DataResult) -> Void) -> String {

        return handleDataRequest(.get,
                                 path: path,
                                 cacheName: cacheName,
                                 cachingType: cachingType,
                                 responseType: .data,
                                 completion: completion)
    }

    func getDataFromCache(_ path: String, cacheName: String? = nil) -> Data? {
        let object = objectFromCache(for: path,
                                     cacheName: cacheName,
                                     cachingType: .memoryAndFile,
                                     responseType: .data)

        return object as? Data
    }
}
