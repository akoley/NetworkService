import Foundation
import XCTest

@testable import NetworkService

class JSONModelTests: XCTestCase {

    // MARK: - Conversion to JSON
    func testConversionOfDataToJSON() {
        let expectation = self.expectation(description: "GET")

        guard let url = URL(string: "http://httpbin.org/get") else { return }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            do {
                let JSON = try data?.toJSON() as? [String: Any]
                let url = JSON?["url"] as! String
                XCTAssertEqual(url, "https://httpbin.org/get")
            } catch {
                // Handle error
            }

            expectation.fulfill()
            }.resume()

        waitForExpectations(timeout: 10, handler: nil)
    }

    // MARK: - Equatable

    func testEqualDictionary() {
        XCTAssertEqual(JSON(["hello": "value"]), JSON(["hello": "value"]))
        XCTAssertNotEqual(JSON(["hello1": "value"]), JSON(["hello2": "value"]))
    }

    func testEqualArray() {
        XCTAssertEqual(JSON([["hello": "value"]]), JSON([["hello": "value"]]))
        XCTAssertNotEqual(JSON([["hello1": "value"]]), JSON([["hello2": "value"]]))

        XCTAssertEqual(JSON([["hello2": "value"], ["hello1": "value"]]), JSON([["hello2": "value"], ["hello1": "value"]]))
        XCTAssertNotEqual(JSON([["hello1": "value"], ["hello2": "value"]]), JSON([["hello3": "value"], ["hello4": "value"]]))
    }

    func testEqualDataSet() {
        let helloData = try! JSONSerialization.data(withJSONObject: ["a": "b"], options: [])
        let byeData = try! JSONSerialization.data(withJSONObject: ["c": "d"], options: [])
        XCTAssertEqual(try! JSON(helloData), try! JSON(helloData))
        XCTAssertNotEqual(try! JSON(helloData), try! JSON(byeData))
    }

    func testEqualNone() {
        XCTAssertEqual(JSON.none, JSON.none)
        XCTAssertNotEqual(JSON.none, JSON(["hello": "value"]))
    }

    // MARK: - from

    func testArrayJSONFromFile() {
        let result = try! FileManager.json(
            from: "simple_array.json",
            bundle: Bundle(for: JSONModelTests.self)) as? [[String: Any]] ?? [[String: Any]]()
        var testArray = [["id": 1, "name": "Hi"]]

        XCTAssertEqual(testArray.count, result.count)

        let comparedKeys = Array(testArray[0].keys).sorted()
        let resultKeys = Array(result[0].keys).sorted()
        XCTAssertEqual(comparedKeys, resultKeys)
        XCTAssertEqual(testArray[0]["id"] as? Int, result[0]["id"] as? Int)
        XCTAssertEqual(testArray[0]["name"] as? String, result[0]["name"] as? String)
    }

    func testDictionaryJSONFromFileNamed() {
        let result = try! FileManager.json(
            from: "simple_dictionary.json",
            bundle: Bundle(for: JSONModelTests.self)) as? [String: Any] ?? [String: Any]()
        let compared = ["id": 1, "name": "Hi"] as [String: Any]
        XCTAssertEqual(compared.count, result.count)
        XCTAssertEqual(Array(compared.keys).sorted(), Array(result.keys).sorted())
    }

    func testFromFileNamedWithNotFoundFile() {
        var failed = false
        do {
            _ = try FileManager.json(
                from: "nonexistingfile.json",
                bundle: Bundle(for: JSONModelTests.self))
        } catch ParsingError.fileNotFound {
            failed = true
        } catch {}
        XCTAssertTrue(failed)
    }

    func testFromFileNamedWithInvalidJSON() {
        var failed = false
        do {
            _ = try FileManager.json(
                from: "invalid.json",
                bundle: Bundle(for: JSONModelTests.self))
        } catch ParsingError.failed {
            failed = true
        } catch {}
        XCTAssertTrue(failed)
    }

    // MARK: - Serializations

    func testDictionarySerialization() {
        let body = ["hello": "value"]
        let json = JSON(body)
        XCTAssertEqual(json.dictionary.debugDescription, body.debugDescription)
        XCTAssertEqual(json.array.debugDescription, [[String: Any]]().debugDescription)
    }

    func testArraySerialization() {
        let body = [["hello": "value"]]
        let json = JSON(body)
        XCTAssertEqual(json.dictionary.debugDescription, [String: Any]().debugDescription)
        XCTAssertEqual(json.array.debugDescription, body.debugDescription)
    }

    func testDataSerialization() {
        let body = ["hello": "value"]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])

        let json = try! JSON(bodyData)
        switch json {
        case let .dictionary(data, _):
            XCTAssertEqual(data.hashValue, bodyData.hashValue)
        default:
            XCTFail("Testing: data serialization failed")
        }
    }
}
