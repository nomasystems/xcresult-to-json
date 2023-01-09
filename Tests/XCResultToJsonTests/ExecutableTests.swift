import Foundation
@testable import XCResultToJsonLib
import XCTest

final class ExecutableTests: XCTestCase {
    func testExecutableOutput() throws {
        let executableUrl = buildOutputExecutableUrl(executableName: "xcresult-to-json")
        let inputPath = try XCTUnwrap(Bundle.module.path(forResource: "xcresult/build", ofType: "xcresult"))
        let result = try run(executableURL: executableUrl, arguments: [inputPath])

        XCTAssertEqual(result.terminationStatus, 0)
        XCTAssertEqual(result.standardError, Data())
        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(Output.self, from: result.standardOutput))
    }
}

// MARK: - Helpers
private extension ExecutableTests {
    func buildOutputExecutableUrl(executableName: String) -> URL {
        // This is a bit hacky, but in a swift package there doesn't seem to be a better way
        // to get to the tested executables path
        let testBundleUrl = Bundle(for: type(of: self)).bundleURL
        let buildDirUrl = testBundleUrl.deletingLastPathComponent()
        return buildDirUrl.appendingPathComponent(executableName)
    }

    func run(
        executableURL: URL,
        arguments: [String]
    ) throws -> (terminationStatus: Int32, standardOutput: Data, standardError: Data) {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        let standardOutput = Pipe()
        process.standardOutput = standardOutput
        let standardError = Pipe()
        process.standardError = standardError
        try process.run()
        process.waitUntilExit()
        return (
            process.terminationStatus,
            standardOutput.fileHandleForReading.readDataToEndOfFile(),
            standardError.fileHandleForReading.readDataToEndOfFile()
        )
    }
}
