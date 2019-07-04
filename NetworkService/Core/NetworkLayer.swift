import Foundation

public extension Int {
    var statusCodeType: ResponseStatusCode {
        switch self {
        case URLError.cancelled.rawValue:
            return .cancelled
        case 100 ..< 200:
            return .informational
        case 200 ..< 300:
            return .success
        case 300 ..< 400:
            return .redirection
        case 400 ..< 500:
            return .clientError
        case 500 ..< 600:
            return .serverError
        default:
            return .unknown
        }
    }
}

open class NetworkLayer {
    static let domain = "com.amrita.networklayer"

    // Indicate synchronous request.
    public var isSynchronous = false

    // Disable error logging
    public var isErrorLoggingEnabled = true

    var token: String?
    private(set) var authorizationHeaderValue: String?
    private(set )var authorizationHeaderKey = "Authorization"
    fileprivate let baseURL: String
    fileprivate var configuration: URLSessionConfiguration
    var cache: NSCache<AnyObject, AnyObject>
    //The boundary used for multipart requests.
    let boundary = String(format: "com.amrita.%08x%08x", arc4random(), arc4random())

    lazy var session: URLSession = {
        URLSession(configuration: self.configuration)
    }()

    // Caching options
    public enum CachingLevel {
        case memory
        case memoryAndFile
        case none
    }

    // Base init
    public init(baseURL: String = "",
                configuration: URLSessionConfiguration = .default,
                cache: NSCache<AnyObject, AnyObject>? = nil) {
        self.baseURL = baseURL
        self.configuration = configuration
        self.cache = cache ?? NSCache()
    }

    public func setAuthorizationHeader(username: String, password: String) {
        let credentialsString = "\(username):\(password)"
        if let credentialsData = credentialsString.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString(options: [])
            let authString = "Basic \(base64Credentials)"

            authorizationHeaderKey = "Authorization"
            authorizationHeaderValue = authString
        }
    }

    public func setAuthorizationHeader(token: String) {
        self.token = token
    }

    // Sets the header fields for every HTTP call.
    public var headerFields: [String: String]?

    public func setAuthorizationHeader(headerKey: String = "Authorization", headerValue: String) {
        authorizationHeaderKey = headerKey
        authorizationHeaderValue = headerValue
    }

    // Callback used to intercept requests that return with a 403 or 401 status code.
    public var unauthorizedRequestCallback: (() -> Void)?

    public func getEncodedURL(with path: String) throws -> URL {
        let encodedPath = path.encodeUTF8() ?? path
        guard let url = URL(string: baseURL + encodedPath) else {
            throw NSError(
                domain: NetworkLayer.domain,
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Couldn't create a url using encodedPath: \(encodedPath)"])
        }
        return url
    }

    public func destinationURL(for path: String, cacheName: String? = nil) throws -> URL {
        let normalizedCacheName = cacheName?.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        )

        var resourcesPath: String
        if let normalizedCacheName = normalizedCacheName {
            resourcesPath = normalizedCacheName
        } else {
            let url = try getEncodedURL(with: path)
            resourcesPath = url.absoluteString
        }

        let normalizedResourcesPath = resourcesPath.replacingOccurrences(of: "/", with: "")
        let folderPath = NetworkLayer.domain
        let finalPath = "\(folderPath)/\(normalizedResourcesPath)"

        if let url = URL(string: finalPath) {
            let directory = FileManager.SearchPathDirectory.cachesDirectory
            if let cachesURL = FileManager.default.urls(for: directory, in: .userDomainMask).first {
                let folderURL = cachesURL.appendingPathComponent(URL(string: folderPath)!.absoluteString)

                if FileManager.default.exists(at: folderURL) == false {
                    try FileManager.default.createDirectory(
                        at: folderURL,
                        withIntermediateDirectories: false, attributes: nil)
                }

                let destinationURL = cachesURL.appendingPathComponent(url.absoluteString)
                return destinationURL
            } else {
                throw NSError(
                    domain: NetworkLayer.domain,
                    code: 9999,
                    userInfo: [NSLocalizedDescriptionKey: "Couldn't normalize url"])
            }
        } else {
            throw NSError(
                domain: NetworkLayer.domain,
                code: 9999,
                userInfo: [NSLocalizedDescriptionKey: "Couldn't create a url using replacedPath: \(finalPath)"])
        }
    }

    public func cancel(_ requestID: String) {
        let semaphore = DispatchSemaphore(value: 0)
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            var tasks = [URLSessionTask]()
            tasks.append(contentsOf: dataTasks as [URLSessionTask])
            tasks.append(contentsOf: uploadTasks as [URLSessionTask])
            tasks.append(contentsOf: downloadTasks as [URLSessionTask])

            if let task = tasks.first(where: {$0.taskDescription == requestID}) {
                task.cancel()
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.now() + 60.0)
    }

    // Cancels all the current requests.
    public func cancelAllRequests() {
        let semaphore = DispatchSemaphore(value: 0)
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            for sessionTask in dataTasks {
                sessionTask.cancel()
            }
            for sessionTask in downloadTasks {
                sessionTask.cancel()
            }
            for sessionTask in uploadTasks {
                sessionTask.cancel()
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.now() + 60.0)
    }

    // Removes the stored credentials and cached data.
    public func reset() {
        cache.removeAllObjects()
        token = nil
        headerFields = nil
        authorizationHeaderKey = "Authorization"
        authorizationHeaderValue = nil
        NetworkLayer.deleteCachedFiles()
    }

    // Deletes the downloaded/cached files.
    public static func deleteCachedFiles() {
        let directory = FileManager.SearchPathDirectory.cachesDirectory
        if let cachesURL = FileManager.default.urls(for: directory, in: .userDomainMask).first {
            let folderURL = cachesURL.appendingPathComponent(URL(string: NetworkLayer.domain)!.absoluteString)
            if FileManager.default.exists(at: folderURL) {
                _ = try? FileManager.default.remove(at: folderURL)
            }
        }
    }
}
