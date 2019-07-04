import Foundation
import XCTest

@testable import NetworkService

 // swiftlint:disable:next type_body_length
class ImageRequestTests: XCTestCase {
    let baseURL = "http://"

    func testGetImage() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"

        try! TestUtil.removeFileIfNeeded(networkLayer, path: path)
        networkLayer.getImage(path) { result in
            switch result {
            case let .success(response):
                let sampleImage = Image.find(
                    named: "testSample.jpg",
                    inBundle: Bundle(for: ImageRequestTests.self))
                let sampleImageData = sampleImage.jpgData()
                let imageData = response.image.jpgData()
                XCTAssertEqual(sampleImageData, imageData)
            case .failure:
                XCTFail()
            }
        }
    }

    func testGetImageReturnBlockInMainThread() {
        let expectation = self.expectation(description: "testGetImageReturnBlockInMainThread")
        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        networkLayer.getImage("i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg") { _ in
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testGetImageInFile() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"

        try! TestUtil.removeFileIfNeeded(networkLayer, path: path)

        networkLayer.getImage(path) { _ in
            guard let destinationURL = try? networkLayer.destinationURL(
                for: path) else { XCTFail(); return }
            XCTAssertTrue(FileManager.default.exists(at: destinationURL))
            let path = destinationURL.path
            let data = FileManager.default.contents(atPath: path)
            XCTAssertEqual(data?.count, 7001)
        }
    }

    func testGetImageInFileUsingCustomName() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"
        let cacheName = "jpg/jpg"

        try! TestUtil.removeFileIfNeeded(
            networkLayer,
            path: path,
            cacheName: cacheName
        )

        networkLayer.getImage(path, cacheName: cacheName) { _ in
            guard let destinationURL = try? networkLayer.destinationURL(
                for: path, cacheName: cacheName) else { XCTFail(); return }
            XCTAssertTrue(FileManager.default.exists(at: destinationURL))
            let path = destinationURL.path
            let data = FileManager.default.contents(atPath: path)
            XCTAssertEqual(data?.count, 7001)
        }
    }

    func testGetImageInCache() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"

        try! TestUtil.removeFileIfNeeded(networkLayer, path: path)

        networkLayer.getImage(path) { result in
            switch result {
            case .success:
                guard let destinationURL = try? networkLayer.destinationURL(
                    for: path) else { XCTFail(); return }
                let absoluteString = destinationURL.absoluteString
                guard let image = networkLayer.cache.object(
                    forKey: absoluteString as AnyObject) as? Image else { XCTFail(); return }
                let sampleImage = Image.find(named: "testSample.jpg",
                                          inBundle: Bundle(for: ImageRequestTests.self)
                )
                let sampleImageData = sampleImage.jpgData()
                let imageData = image.jpgData()
                XCTAssertEqual(sampleImageData, imageData)
            case .failure:
                XCTFail()
            }
        }
    }

    func testGetImageInCacheUsingCustomName() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"
        let cacheName = "jpg/jpg"

        try! TestUtil.removeFileIfNeeded(networkLayer,
                                       path: path,
                                       cacheName: cacheName)

        networkLayer.getImage(path, cacheName: cacheName) { result in
            switch result {
            case .success:
                guard let destinationURL = try? networkLayer.destinationURL(
                    for: path, cacheName: cacheName) else { XCTFail(); return }
                let absoluteString = destinationURL.absoluteString
                guard let image = networkLayer.cache.object(
                    forKey: absoluteString as AnyObject) as? Image else { XCTFail(); return }
                let sampleImage = Image.find(named: "testSample.jpg",
                                          inBundle: Bundle(for: ImageRequestTests.self))
                let sampleImageData = sampleImage.jpgData()
                let imageData = image.jpgData()
                XCTAssertEqual(sampleImageData, imageData)
            case .failure:
                XCTFail()
            }
        }
    }

    func testCancelImageRequest() {
        let expectation = self.expectation(description: "testCancelImageRequest")

        let networkLayer = NetworkLayer(baseURL: baseURL)
        networkLayer.isSynchronous = true
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"

        try! TestUtil.removeFileIfNeeded(networkLayer, path: path)

        networkLayer.getImage(path) { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(response):
                XCTAssertEqual(response.error.code, URLError.cancelled.rawValue)
                expectation.fulfill()
            }
        }
        networkLayer.cancelImageRequest("i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg")
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    // Test `imageFromCache` using path, expecting image from Cache
    func testImageFromCacheForPathInCache() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"
        NetworkLayer.deleteCachedFiles()
        networkLayer.getImage(path) { result in
            switch result {
            case .success:
                guard let image = networkLayer.getImageFromCache(path) else { XCTFail(); return }
                let sampleImage = Image.find(named: "testSample.jpg",
                                             inBundle: Bundle(for: ImageRequestTests.self))
                let sampleImageData = sampleImage.jpgData()
                let imageData = image.jpgData()
                XCTAssertEqual(sampleImageData, imageData)
            case .failure:
                XCTFail()
            }
        }
    }

    // Test `imageFromCache` using cacheName instead of path, expecting image from Cache
    func testImageFromCacheForCustomCacheNameInCache() {
        let networkLayer = NetworkLayer(baseURL: baseURL)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"
        let cacheName = "hello"
        try! TestUtil.removeFileIfNeeded(networkLayer,
                                       path: path, cacheName: cacheName)
        networkLayer.getImage(path, cacheName: cacheName) { _ in
            let image = networkLayer.getImageFromCache(path, cacheName: cacheName)
            let sampleImage = Image.find(named: "testSample.jpg",
                                      inBundle: Bundle(for: ImageRequestTests.self))
            let sampleImageData = sampleImage.jpgData()
            let imageData = image?.jpgData()
            XCTAssertEqual(sampleImageData, imageData)
        }
    }

    // Test `imageFromCache` using path, expecting image from file
    func testImageFromCacheForPathInFile() {
        let cache = NSCache<AnyObject, AnyObject>()
        let networkLayer = NetworkLayer(baseURL: baseURL, cache: cache)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"
        try! TestUtil.removeFileIfNeeded(networkLayer, path: path)
        networkLayer.getImage(path) { result in
            switch result {
            case .success:
                guard let destinationURL = try? networkLayer.destinationURL(
                    for: path) else { XCTFail(); return }
                let absoluteString = destinationURL.absoluteString
                cache.removeObject(forKey: absoluteString as AnyObject)
                guard let image = networkLayer.getImageFromCache(path) else { XCTFail(); return }
                let sampleImage = Image.find(named: "testSample.jpg",
                                          inBundle: Bundle(for: ImageRequestTests.self))
                let sampleImageData = sampleImage.jpgData()
                let imageData = image.jpgData()
                XCTAssertEqual(sampleImageData, imageData)
            case .failure:
                XCTFail()
            }
        }
    }

    // Test `imageFromCache` using cacheName instead of path, expecting image from file
    func testImageFromCacheForCustomCacheNameInFile() {
        let cache = NSCache<AnyObject, AnyObject>()
        let networkLayer = NetworkLayer(baseURL: baseURL, cache: cache)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"
        let cacheName = "hello"
        try! TestUtil.removeFileIfNeeded(networkLayer, path: path, cacheName: cacheName)
        networkLayer.getImage(path, cacheName: cacheName) { result in
            switch result {
            case .success:
                guard let destinationURL = try? networkLayer.destinationURL(
                    for: path,
                    cacheName: cacheName) else { XCTFail(); return }
                let absoluteString = destinationURL.absoluteString
                cache.removeObject(forKey: absoluteString as AnyObject)
                guard let image = networkLayer.getImageFromCache(
                    path,
                    cacheName: cacheName) else { XCTFail(); return }
                let sampleImage = Image.find(
                    named: "testSample.jpg",
                    inBundle: Bundle(for: ImageRequestTests.self))
                let sampleImageData = sampleImage.jpgData()
                let imageData = image.jpgData()
                XCTAssertEqual(sampleImageData, imageData)
            case .failure:
                XCTFail()
            }
        }
    }

    // Test `imageFromCache` using path, but then clearing cache, and removing files, expecting nil
    func testImageFromCacheNilImage() {
        let cache = NSCache<AnyObject, AnyObject>()
        let networkLayer = NetworkLayer(baseURL: baseURL, cache: cache)
        let path = "i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/~jYAAOSwW8ZdB-Np/$_2.jpg"
        try! TestUtil.removeFileIfNeeded(networkLayer, path: path)
        networkLayer.getImage(path) { result in
            switch result {
            case .success:
                guard let destinationURL = try? networkLayer.destinationURL(for: path) else { XCTFail(); return }
                let absoluteString = destinationURL.absoluteString
                cache.removeObject(forKey: absoluteString as AnyObject)
                try! TestUtil.removeFileIfNeeded(networkLayer, path: path)
                let image = networkLayer.getImageFromCache(path)
                XCTAssertNil(image)
            case .failure:
                XCTFail()
            }
        }
    }
}
