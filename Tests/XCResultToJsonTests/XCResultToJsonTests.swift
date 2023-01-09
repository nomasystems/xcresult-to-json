import Foundation
@testable import XCResultToJsonLib
import XCTest

final class XCResultToJsonTests: XCTestCase {
    func testCommandParse() throws {
        let inputPath = Bundle.module.path(forResource: "xcresult/build", ofType: "xcresult")
        _ = try XCResultToJson.parse([XCTUnwrap(inputPath), "--path-root", "/"])
    }
}
