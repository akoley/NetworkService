import Foundation
import XCTest

@testable import NetworkService
class StringUTFTests: XCTestCase {

    func testEncodeUTF8Success() {
        let encodedString = "TestøTesting.jpg".encodeUTF8()
        XCTAssertEqual(encodedString, "Test%C3%B8Testing.jpg")
    }

    func testEncodeUTF8WFailed() {
        let encodedString = "test~testing.jpg".encodeUTF8()
        XCTAssertNotEqual(encodedString, "test_testing.jpg")
    }
}
