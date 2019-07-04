import Foundation
import XCTest

@testable import NetworkService

class ResultTests: XCTestCase {
    var response: HTTPURLResponse {
        let url = URL(string: "http://www.google.com")!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200)

        return urlResponse
    }

    func testJSONResultDictionary() {
        let body = ["a": 12]
        let result = JSONResult(body: body, response: response, error: nil)
        switch result {
        case let .success(value):
            XCTAssertEqual(value.dictionaryBody.debugDescription, body.debugDescription)
            XCTAssertEqual(value.arrayBody.debugDescription, [[String: Any]]().debugDescription)

            switch value.json {
            case let .dictionary(_, valueBody):
                XCTAssertEqual(body.debugDescription, valueBody.debugDescription)
            case .array, .none:
                XCTFail()
            }
        case .failure:
            XCTFail("Test JSON Result Dict - Failed")
        }
    }

    func testJSONResultArray() {
        let expectedBody = [["a": 12]]
        let result = JSONResult(body: expectedBody, response: response, error: nil)
        switch result {
        case let .success(value):
            XCTAssertEqual(value.dictionaryBody.debugDescription, [String: Any]().debugDescription)
            XCTAssertEqual(value.arrayBody.debugDescription, expectedBody.debugDescription)
            switch value.json {
            case let .array(_, valueBody):
                XCTAssertEqual(expectedBody.debugDescription, valueBody.debugDescription)
            case .dictionary, .none:
                XCTFail()
            }
        case .failure:
            XCTFail("Test JSON Result Array - Failed")
        }
    }

    func testJSONResultDictionaryData() {
        let expectedBody = ["a": 12]
        let expectedBodyData = try! JSONSerialization.data(withJSONObject: expectedBody, options: [])
        let result = JSONResult(body: expectedBodyData, response: response, error: nil)
        switch result {
        case let .success(value):
            XCTAssertEqual(value.dictionaryBody.debugDescription, expectedBody.debugDescription)
            XCTAssertEqual(value.arrayBody.debugDescription, [[String: Any]]().debugDescription)
            XCTAssertEqual(value.data.hashValue, expectedBodyData.hashValue)
            switch value.json {
            case let .dictionary(dataBody, valueBody):
                XCTAssertEqual(dataBody.hashValue, expectedBodyData.hashValue)
                XCTAssertEqual(valueBody.debugDescription, expectedBody.debugDescription)
            case .array, .none:
                XCTFail()
            }
        case .failure:
            XCTFail("Test JSON Result Data - Failed")
        }
    }

    func testJSONResultArrayData() {
        let expectedBody = [["a": 12]]
        let expectedBodyData = try! JSONSerialization.data(withJSONObject: expectedBody, options: [])
        let result = JSONResult(body: expectedBodyData, response: response, error: nil)
        switch result {
        case let .success(value):
            XCTAssertEqual(value.dictionaryBody.debugDescription, [String: Any]().debugDescription)
            XCTAssertEqual(value.arrayBody.debugDescription, expectedBody.debugDescription)
            XCTAssertEqual(value.data.hashValue, expectedBodyData.hashValue)
            switch value.json {
            case let .array(dataBody, valueBody):
                XCTAssertEqual(dataBody.hashValue, expectedBodyData.hashValue)
                XCTAssertEqual(valueBody.debugDescription, expectedBody.debugDescription)
            case .dictionary, .none:
                XCTFail("Test JSON Result for Array - Failed")
            }
        case .failure:
            XCTFail("Test JSON Result Array Data - Failed")
        }
    }

    func testJSONResultNone() {
        let result = JSONResult(body: nil, response: response, error: nil)
        switch result {
        case let .success(value):
            XCTAssertEqual(value.dictionaryBody.debugDescription, [String: Any]().debugDescription)
            XCTAssertEqual(value.arrayBody.debugDescription, [[String: Any]]().debugDescription)
            XCTAssertEqual(value.data.hashValue, Data().hashValue)
            switch value.json {
            case .dictionary, .array:
                XCTFail("Test JSON Result for Dictionary - Failed")
            case .none:
                break
            }
        case .failure:
             XCTFail("Test JSON Result None - Failed")
        }
    }

    func testJSONResponseError() {
        let body = [String: Any]()
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])

        let nilErrorResult = JSONResult(body: bodyData, response: response, error: nil)
        XCTAssertNil(nilErrorResult.error)

        let error = NSError(domain: "", code: 0, userInfo: nil)
        let errorResult = JSONResult(body: bodyData, response: response, error: error)
        XCTAssertNotNil(errorResult.error)
    }

    func testImageResultWithMalformedImage() {
        let malformedImage = "Malformed image"
        let result = ImageResult(body: malformedImage, response: response, error: nil)

        switch result {
        case .success:
            XCTFail("Testing Image result with Malformed image")
        case let .failure(result):
            XCTAssertEqual(result.error.code, URLError.cannotParseResponse.rawValue)
        }
    }

    func testDataResultWithMalformedData() {
        let malformedData = "Malformed data"
        let result = DataResult(body: malformedData, response: response, error: nil)

        switch result {
        case .success:
            XCTFail("Testing Image result with Malformed data")
        case let .failure(result):
            XCTAssertEqual(result.error.code, URLError.cannotParseResponse.rawValue)
        }
    }
}
