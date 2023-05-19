import ArgumentParser
import Foundation

public func main() {
    XCResultToJson.main()
}

struct XCResultToJson: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parses an xcresult bundle and outputs a summarizing json for CI."
    )

    @Argument(help: "The input xcresult file path.", transform: URL.init(fileURLWithPath:))
    var xcresultPath: URL

    @Option(help: "If present, file paths that are relative to the specified directory are output as relative paths.")
    var pathRoot: String?

    mutating func run() throws {
        if !FileManager.default.fileExists(atPath: xcresultPath.path) {
            throw XCResultToJsonError.inputFileNotFound(xcresultPath)
        }

        let output = Output(xcresultFileUrl: xcresultPath, pathRoot: pathRoot)
        FileHandle.standardOutput.write(output.json)
    }
}

enum XCResultToJsonError: Error, CustomStringConvertible {
    case inputFileNotFound(URL)

    var description: String {
        switch self {
        case .inputFileNotFound(let url):
            return "Input file not found: \(url.path)"
        }
    }
}
