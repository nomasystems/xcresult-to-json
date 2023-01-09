@testable import Sample
import XCTest

final class SampleTests: XCTestCase {
    func testThatFails() {
        Sample.foo()
        XCTAssertTrue(false)
    }
}
