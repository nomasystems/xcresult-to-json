@testable import XCResultToJsonLib
import XCTest

final class OutputTests: XCTestCase {
    func testRelativePath() {
        XCTAssertEqual(relativePath(path: "/abc/def", pathRoot: nil), "/abc/def")
        XCTAssertEqual(relativePath(path: "/abc/def", pathRoot: "/abc"), "def")
        XCTAssertEqual(relativePath(path: "/abc/def", pathRoot: "/abc/"), "def")
        XCTAssertNil(relativePath(path: "/ghi/abc", pathRoot: "/abc"))
    }

    func testSourceLocationFromDocumentLocationUrl() throws {
        let url = "/abc/def" +
            "#StartingColumnNumber=1" +
            "&StartingLineNumber=2" +
            "&EndingColumnNumber=3" +
            "&EndingLineNumber=2" +
            "&SomeOtherKey=foo"
        let sourceLocation = try XCTUnwrap(SourceLocation(documentLocationUrl: url))

        XCTAssertEqual(sourceLocation.startLine, 2)
        XCTAssertEqual(sourceLocation.endLine, 2)
        XCTAssertEqual(sourceLocation.startColumn, 1)
        XCTAssertEqual(sourceLocation.endColumn, 3)
    }

    func testFromBuildXCResult() throws {
        let inputPath = try XCTUnwrap(Bundle.module.url(forResource: "xcresult/build", withExtension: "xcresult"))
        let output = Output(xcresultFileUrl: inputPath, pathRoot: nil)

        XCTAssertEqual(output.metrics.warningCount, 1)
        XCTAssertEqual(output.annotations.count, 1)
        let warningAnnotation = try XCTUnwrap(output.annotations.first)
        let expectedLocation = SourceLocation(startLine: 2, endLine: 2, startColumn: 10, endColumn: 10)
        XCTAssertEqual(warningAnnotation.location, expectedLocation)
        let path = try XCTUnwrap(warningAnnotation.path)
        XCTAssertTrue(path.hasSuffix("Sample/File.swift"), "'\(path)' does not refer to the expected file")
    }

    func testFromTestXCResult() throws {
        let inputPath = try XCTUnwrap(Bundle.module.url(forResource: "xcresult/test", withExtension: "xcresult"))
        let output = Output(xcresultFileUrl: inputPath, pathRoot: nil)

        XCTAssertEqual(output.metrics.testFailedCount, 1)
        XCTAssertEqual(output.annotations.count, 2)
        let testFailureAnnotation = try XCTUnwrap(output.annotations.first { $0.annotationLevel == .failure })
        let path = try XCTUnwrap(testFailureAnnotation.path)
        XCTAssertTrue(path.hasSuffix("SampleTests/SampleTests.swift"), "'\(path)' does not refer to the expected file")
        let expectedLocation = SourceLocation(startLine: 6, endLine: 6, startColumn: nil, endColumn: nil)
        XCTAssertEqual(testFailureAnnotation.location, expectedLocation)
    }
}

// MARK: - Helpers
extension SourceLocation: Equatable {
    public static func == (lhs: SourceLocation, rhs: SourceLocation) -> Bool {
        lhs.startLine == rhs.startLine &&
            lhs.endLine == rhs.endLine &&
            lhs.startColumn == lhs.startColumn &&
            lhs.endColumn == rhs.endColumn
    }
}
