import Foundation
import XCTest

@testable import NetworkService

class NetworkLayerPrivateFunctionsTests: XCTestCase {
    let baseURL = "http://httpbin.org"

    func testURLForPath() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let url = try! networkLayer.getEncodedURL(with: "/hello")
        XCTAssertEqual(url.absoluteString, "http://httpbin.org/hello")
    }

    func testURLForPathWithFullPath() {
        let networkLayer = NetworkLayer()
        let url = try! networkLayer.getEncodedURL(with: "http://httpbin.org/hello")
        XCTAssertEqual(url.absoluteString, "http://httpbin.org/hello")
    }

    func testSkipTestMode() {
        let expectation = self.expectation(description: "testSkipTestMode")

        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        var synchronous = false

        networkLayer.createRequest(.get, path: "/get") { _ in
            synchronous = true
            XCTAssertTrue(synchronous)
            expectation.fulfill()
        }
        XCTAssertFalse(synchronous)
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testDestinationURL() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "/image/png"
        guard let destinationURL = try? networkLayer.destinationURL(for: path) else {
            XCTFail(); return
        }
        XCTAssertEqual(destinationURL.lastPathComponent, "http:httpbin.orgimagepng")
    }

    func testDestinationURLWithAbsolutePath() {
        let networkLayer = NetworkLayer()
        let path = "http://httpbin.org/image/png"
        guard let destinationURL = try? networkLayer.destinationURL(for: path) else { XCTFail(); return }
        XCTAssertEqual(destinationURL.lastPathComponent, "http:httpbin.orgimagepng")
    }

    func testDestinationURLWithSpecialCharactersInPath() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "/h�testing.jpg"
        guard let destinationURL = try? networkLayer.destinationURL(for: path) else { XCTFail(); return }
        XCTAssertEqual(destinationURL.lastPathComponent, "http:httpbin.orgh%EF%BF%BDtesting.jpg")
    }

    func testDestinationURLWithSpecialCharactersInCacheName() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "/the-url-doesnt-really-matter"
        guard let destinationURL = try? networkLayer.destinationURL(
            for: path,
            cacheName: "h�testing.jpg-25-03/small") else { XCTFail(); return }
        XCTAssertEqual(destinationURL.lastPathComponent, "h%EF%BF%BDtesting.jpg-25-03small")
    }

    func testDestinationURLCache() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "/image/png"
        let cacheName = "png/png"
        guard let destinationURL = try? networkLayer.destinationURL(
            for: path,
            cacheName: cacheName) else { XCTFail(); return }
        XCTAssertEqual(destinationURL.lastPathComponent, "pngpng")
    }

    func testStatusCodeType() {
        XCTAssertEqual((URLError.cancelled.rawValue).statusCodeType, ResponseStatusCode.cancelled)
        XCTAssertEqual(99.statusCodeType, ResponseStatusCode.unknown)
        XCTAssertEqual(100.statusCodeType, ResponseStatusCode.informational)
        XCTAssertEqual(199.statusCodeType, ResponseStatusCode.informational)
        XCTAssertEqual(200.statusCodeType, ResponseStatusCode.success)
        XCTAssertEqual(299.statusCodeType, ResponseStatusCode.success)
        XCTAssertEqual(300.statusCodeType, ResponseStatusCode.redirection)
        XCTAssertEqual(399.statusCodeType, ResponseStatusCode.redirection)
        XCTAssertEqual(400.statusCodeType, ResponseStatusCode.clientError)
        XCTAssertEqual(499.statusCodeType, ResponseStatusCode.clientError)
        XCTAssertEqual(500.statusCodeType, ResponseStatusCode.serverError)
        XCTAssertEqual(599.statusCodeType, ResponseStatusCode.serverError)
        XCTAssertEqual(600.statusCodeType, ResponseStatusCode.unknown)
    }

    func testCancelWithRequestID() {
        let expectation = self.expectation(description: "testCancelAllRequests")
        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        var cancelledRequest = false

        let requestID = networkLayer.createRequest(.get, path: "/get") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                cancelledRequest = response.error.code == URLError.cancelled.rawValue
                XCTAssertTrue(cancelledRequest)

                if cancelledRequest {
                    expectation.fulfill()
                }
            }
        }
        networkLayer.cancel(requestID)
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testCancelAllRequests() {
        let expectation = self.expectation(description: "testCancelAllRequests")
        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        var cancelledGET = false
        var cancelledPOST = false

        networkLayer.createRequest(.get, path: "/get") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                cancelledGET = response.error.code == URLError.cancelled.rawValue
                XCTAssertTrue(cancelledGET)

                if cancelledGET && cancelledPOST {
                    expectation.fulfill()
                }
            }
        }

        networkLayer.createRequest(.post, path: "/post") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                cancelledPOST = response.error.code == URLError.cancelled.rawValue
                XCTAssertTrue(cancelledPOST)

                if cancelledGET && cancelledPOST {
                    expectation.fulfill()
                }
            }
        }

        networkLayer.cancelAllRequests()

        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testCancelRequestsReturnInMainThread() {
        let expectation = self.expectation(description: "testCancelRequestsReturnInMainThread")
        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        networkLayer.createRequest(.get, path: "/get") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(response.error.code, URLError.cancelled.rawValue)
                expectation.fulfill()
            }
        }
        networkLayer.cancelAllRequests()
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testReset() {
        let networkLayer = NetworkLayer(baseURL: baseURL)

        networkLayer.setAuthorizationHeader(username: "user", password: "passwd")
        networkLayer.setAuthorizationHeader(token: "token")
        networkLayer.headerFields = ["HeaderKey": "HeaderValue"]

        XCTAssertEqual(networkLayer.token, "token")
        XCTAssertEqual(networkLayer.authorizationHeaderKey, "Authorization")
        XCTAssertEqual(networkLayer.authorizationHeaderValue, "Basic dXNlcjpwYXNzd2Q=")

        networkLayer.reset()

        XCTAssertNil(networkLayer.token)
        XCTAssertEqual(networkLayer.authorizationHeaderKey, "Authorization")
        XCTAssertNil(networkLayer.authorizationHeaderValue)
    }

    func testDeleteCachedFiles() {
        let directory = FileManager.SearchPathDirectory.cachesDirectory
        let cachesURL = FileManager.default.urls(
            for: directory,
            in: .userDomainMask).first!
        let folderURL = cachesURL.appendingPathComponent(
            URL(string: NetworkLayer.domain)!.absoluteString)

        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.getImage("/image/png") { _ in
            let image = Image.find(
                named: "testSample.jpg",
                inBundle: Bundle(for: NetworkLayerPrivateFunctionsTests.self))
            let data = image.jpgData()
            let filename = cachesURL.appendingPathComponent("sample.jpg")
            ((try? data?.write(to: filename)) as ()??)

            XCTAssertTrue(FileManager.default.exists(at: cachesURL))
            XCTAssertTrue(FileManager.default.exists(at: folderURL))
            XCTAssertTrue(FileManager.default.exists(at: filename))
            NetworkLayer.deleteCachedFiles()
            XCTAssertTrue(FileManager.default.exists(at: cachesURL))
            XCTAssertFalse(FileManager.default.exists(at: folderURL))
            XCTAssertTrue(FileManager.default.exists(at: filename))
        }
    }
}
