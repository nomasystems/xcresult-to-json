import Foundation
import XCResultKit

extension Output {
    init(xcresultFileUrl: URL, pathRoot: String?) {
        let xcresultFile = XCResultFile(url: xcresultFileUrl)
        self.init(xcresultFile: xcresultFile, pathRoot: pathRoot)
    }

    init(xcresultFile: XCResultFile, pathRoot: String?) {
        let issues = xcresultFile.getInvocationRecord()?.issues
        let metrics = xcresultFile.getInvocationRecord()?.metrics

        var annotations = [Annotation]()

        func appendAnnotations(issueSummaries: [IssueSummary], level: AnnotationLevel) {
            issueSummaries.forEach {
                Annotation(issueSummary: $0, level: level, pathRoot: pathRoot)
                    .map { annotations.append($0) }
            }
        }

        func appendAnnotations(issueSummaries: [TestFailureIssueSummary]) {
            issueSummaries.forEach {
                Annotation(issueSummary: $0, pathRoot: pathRoot)
                    .map { annotations.append($0) }
            }
        }

        appendAnnotations(issueSummaries: issues?.warningSummaries ?? [], level: .warning)
        appendAnnotations(issueSummaries: issues?.analyzerWarningSummaries ?? [], level: .warning)
        appendAnnotations(issueSummaries: issues?.errorSummaries ?? [], level: .failure)
        appendAnnotations(issueSummaries: issues?.testFailureSummaries ?? [])

        self.init(
            annotations: annotations,
            metrics: .init(
                errorCount: metrics?.errorCount ?? 0,
                warningCount: metrics?.warningCount ?? 0,
                analyzerWarningCount: metrics?.analyzerWarningCount ?? 0,
                testCount: metrics?.testsCount ?? 0,
                testFailedCount: metrics?.testsFailedCount ?? 0,
                testSkippedCount: metrics?.testsSkippedCount ?? 0
            )
        )
    }
}

extension Annotation {
    init?(issueSummary: IssueSummary, level: AnnotationLevel, pathRoot: String?) {
        var path: String?
        var location: SourceLocation?
        if let documentLocation = issueSummary.documentLocationInCreatingWorkspace {
            path = relativePath(path: documentLocation.url, pathRoot: pathRoot)
            location = SourceLocation(documentLocationUrl: documentLocation.url)
        }
        guard location == nil || (path != nil && location != nil) else {
            return nil
        }

        self.init(
            annotationLevel: level,
            title: issueSummary.issueType,
            message: issueSummary.message,
            path: path,
            location: location
        )
    }

    init?(issueSummary: TestFailureIssueSummary, pathRoot: String?) {
        guard
            let documentLocation = issueSummary.documentLocationInCreatingWorkspace,
            let path = relativePath(path: documentLocation.url, pathRoot: pathRoot),
            let location = SourceLocation(documentLocationUrl: documentLocation.url)
        else {
            return nil
        }
        self.init(
            annotationLevel: .failure,
            title: "Test case '\(issueSummary.testCaseName)'",
            message: issueSummary.message,
            path: path,
            location: location
        )
    }

}

extension SourceLocation {
    init?(documentLocationUrl url: String) {
        enum LocationKey: String {
            case startingLineNumber = "StartingLineNumber"
            case endingLineNumber = "EndingLineNumber"
            case startingColumnNumber = "StartingColumnNumber"
            case endingColumnNumber = "EndingColumnNumber"
        }

        func fragment(url: String) -> Substring? {
            guard let fragmentSeparatorIndex = url.firstIndex(of: "#") else {
                return nil
            }
            return url[url.index(after: fragmentSeparatorIndex)...]
        }

        func attributes(fragment: Substring) -> [LocationKey: Int] {
            fragment.components(separatedBy: "&").reduce(into: [:], { result, component in
                let keyValue = component.split(maxSplits: 1, whereSeparator: { $0 == "="})
                if keyValue.count == 2,
                    let key = LocationKey(rawValue: String(keyValue[0])),
                    let value = Int(keyValue[1]) {
                    result[key] = value
                }
            })
        }

        guard let fragment = fragment(url: url) else {
            return nil
        }
        let attributes = attributes(fragment: fragment)
        guard
            let startLine = attributes[.startingLineNumber],
            let endLine = attributes[.endingLineNumber]
        else {
            return nil
        }
        let startColumn = attributes[.startingColumnNumber]
        let endColumn = attributes[.endingColumnNumber]

        self.init(
            startLine: startLine,
            endLine: endLine,
            startColumn: startColumn,
            endColumn: endColumn
        )
    }
}

func relativePath(path: String, pathRoot: String?) -> String? {
    guard let urlComponents = URLComponents(string: path) else {
        return nil
    }
    let path = urlComponents.path
    if let pathRoot = pathRoot {
        guard path.hasPrefix(pathRoot) else {
            return nil
        }
        var path = path
        path.removeFirst(pathRoot.count)
        if path.first == "/" {
            path.removeFirst()
        }
        return path
    } else {
        return urlComponents.path
    }
}
