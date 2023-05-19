import Foundation
import XCResultKit

extension Output {
    init(xcresultFileUrl: URL, pathRoot: String?) {
        let xcresultFile = XCResultFile(url: xcresultFileUrl)
        self.init(xcresultFile: xcresultFile, pathRoot: pathRoot)
    }

    init(xcresultFile: XCResultFile, pathRoot: String?) {
        let invocationRecord = xcresultFile.getInvocationRecord()
        let issues = invocationRecord?.issues
        let metrics = invocationRecord?.metrics

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
        let warningCount = annotations.count
        let externalWarningCount = annotations.reduce(0, { result, annotation in
            pathRoot != nil && annotation.isPathRelative ? result + 1 : result
        })
        appendAnnotations(issueSummaries: issues?.analyzerWarningSummaries ?? [], level: .warning)
        appendAnnotations(issueSummaries: issues?.errorSummaries ?? [], level: .failure)
        appendAnnotations(issueSummaries: issues?.testFailureSummaries ?? [])

        self.init(
            annotations: annotations,
            metrics: .init(
                errorCount: metrics?.errorCount ?? 0,
                warningCount: warningCount,
                externalWarningCount: externalWarningCount,
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
        var path: Path?
        var location: SourceLocation?
        if let documentLocation = issueSummary.documentLocationInCreatingWorkspace {
            path = relativePath(url: documentLocation.url, pathRoot: pathRoot)
            location = SourceLocation(documentLocationUrl: documentLocation.url)
        }

        guard location == nil || (path != nil && location != nil) else {
            return nil
        }

        self.init(
            annotationLevel: level,
            title: issueSummary.issueType,
            message: issueSummary.message,
            path: path?.value,
            isPathRelative: path?.isRelative ?? false,
            location: location
        )
    }

    init?(issueSummary: TestFailureIssueSummary, pathRoot: String?) {
        guard
            let documentLocation = issueSummary.documentLocationInCreatingWorkspace,
            let path = relativePath(url: documentLocation.url, pathRoot: pathRoot),
            (path.isRelative || pathRoot == nil),
            let location = SourceLocation(documentLocationUrl: documentLocation.url)
        else {
            return nil
        }
        self.init(
            annotationLevel: .failure,
            title: "Test case '\(issueSummary.testCaseName)'",
            message: issueSummary.message,
            path: path.value,
            isPathRelative: path.isRelative,
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

struct Path: Equatable {
    let value: String
    let isRelative: Bool
}

func relativePath(url: String, pathRoot: String?) -> Path? {
    guard let urlComponents = URLComponents(string: url) else {
        return nil
    }
    let path = urlComponents.path
    if let pathRoot = pathRoot {
        guard path.hasPrefix(pathRoot) else {
            return .init(value: path, isRelative: false)
        }
        var path = path
        path.removeFirst(pathRoot.count)
        if path.first == "/" {
            path.removeFirst()
        }
        return .init(value: path, isRelative: true)
    } else {
        return .init(value: path, isRelative: false)
    }
}
