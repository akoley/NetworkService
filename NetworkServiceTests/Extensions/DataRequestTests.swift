import Foundation
import XCTest

@testable import NetworkService
class DataRequestTests: XCTestCase {
    let baseURL = "http://httpbin.org"

    func testDownloadData() {
        var synchronous = true
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "/image/png"
        try! TestUtil.removeFileIfNeeded(networkLayer, path: path)
        networkLayer.downloadData(path) { result in
            switch result {
            case let .success(response):
                synchronous = true
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(response.data.count, 8090)
            case .failure:
                XCTFail()
            }
        }
        XCTAssertTrue(synchronous)
    }

    func testDataFromCache() {
        let cache = NSCache<AnyObject, AnyObject>()
        let networkLayer = NetworkLayer(baseURL: "http://", cache: cache)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"

        networkLayer.downloadData(path) { result in
            switch result {
            case let .success(response):
                if let cacheData = networkLayer.getDataFromCache(path) {
                    XCTAssert(response.data == cacheData)
                } else {
                    XCTFail()
                }
            case .failure:
                XCTFail()
            }
        }
    }
}
