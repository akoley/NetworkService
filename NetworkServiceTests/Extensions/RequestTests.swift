import Foundation
import XCTest

@testable import NetworkService

class RequestTests: XCTestCase {
    let baseURL = "http://httpbin.org"

    func testCreateRequest() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.createRequest(.get, path: "/get") { result in
            switch result {
            case let .success(response):
                let json = response.dictionaryBody

                guard let url = json["url"] as? String else { XCTFail(); return }
                XCTAssertEqual(url, "https://httpbin.org/get")

                guard let headers = json["headers"] as? [String: String] else { XCTFail(); return }
                let contentType = headers["Content-Type"]
                XCTAssertNil(contentType)
            case .failure:
                XCTFail()
            }
        }
    }

    func testCreateRequestWithFullPath() {
        let networkLayer = NetworkLayer()
        networkLayer.createRequest(.get, path: "http://httpbin.org/get") { result in
            switch result {
            case let .success(response):
                let json = response.dictionaryBody

                guard let url = json["url"] as? String else { XCTFail(); return }
                XCTAssertEqual(url, "https://httpbin.org/get")

                guard let headers = json["headers"] as? [String: String] else { XCTFail(); return }
                let contentType = headers["Content-Type"]
                XCTAssertNil(contentType)
            case .failure:
                XCTFail()
            }
        }
    }

    func testRequestReturnBlockInMainThread() {
        let expectation = self.expectation(description: "testRequestReturnBlockInMainThread")
        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        networkLayer.createRequest(.get, path: "/get") { _ in
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testCreateRequestWithHeaders() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.createRequest(.get, path: "/get") { result in
            switch result {
            case let .success(response):
                let json = response.dictionaryBody
                guard let url = json["url"] as? String else { XCTFail(); return }
                XCTAssertEqual(url, "https://httpbin.org/get")

                let headers = response.headers
                guard let connection = headers["Connection"] as? String else { XCTFail(); return }
                XCTAssertEqual(connection, "keep-alive")
                XCTAssertEqual(headers["Content-Type"] as? String, "application/json")
            case .failure:
                XCTFail()
            }
        }
    }

    func testCreateRequestWithInvalidPath() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.createRequest(.get, path: "/invalidpath") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                XCTAssertEqual(response.error.code, 404)
            }
        }
    }

    func testCancelRequestWithPath() {
        let expectation = self.expectation(description: "testCancelRequestWithPath")

        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        var completed = false
        networkLayer.createRequest(.get, path: "/get") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                XCTAssertTrue(completed)
                XCTAssertEqual(response.error.code, URLError.cancelled.rawValue)
                expectation.fulfill()
            }
        }
        networkLayer.cancelRequest(.get, path: "/get")
        completed = true
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testCancelRequestWithID() {
        let expectation = self.expectation(description: "testCancelRequestWithID")

        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        let requestID = networkLayer.createRequest(.get, path: "/get") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                XCTAssertEqual(response.error.code, URLError.cancelled.rawValue)
                expectation.fulfill()
            }
        }
        networkLayer.cancel(requestID)
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testStatusCodes() {
        let networkLayer = NetworkLayer(baseURL: baseURL)

        networkLayer.createRequest(.get, path: "/status/200") { result in
            switch result {
            case let .success(response):
                XCTAssertEqual(response.statusCode, 200)
            case .failure:
                XCTFail()
            }
        }

        var statusCode = 300
        networkLayer.createRequest(.get, path: "/status/\(statusCode)") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                let connectionError = NSError(
                    domain: NetworkLayer.domain,
                    code: statusCode,
                    userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(
                        forStatusCode: statusCode)])
                XCTAssertEqual(response.error, connectionError)
            }
        }

        statusCode = 400
        networkLayer.createRequest(.get, path: "/status/\(statusCode)") { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                let connectionError = NSError(
                    domain: NetworkLayer.domain,
                    code: statusCode,
                    userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(
                        forStatusCode: statusCode)])
                XCTAssertEqual(response.error, connectionError)
            }
        }
    }
}
