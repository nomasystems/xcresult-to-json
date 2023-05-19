import Foundation

struct Output: Codable {
    let annotations: [Annotation]
    let metrics: Metrics
}

struct Annotation: Codable {
    let annotationLevel: AnnotationLevel
    let title: String?
    let message: String
    let path: String?
    let isPathRelative: Bool
    let location: SourceLocation?
}

enum AnnotationLevel: String, Codable {
    case failure
    case notice
    case warning
}

struct SourceLocation: Codable {
    let startLine: Int
    let endLine: Int
    let startColumn: Int?
    let endColumn: Int?
}

struct Metrics: Codable {
    let errorCount: Int
    let warningCount: Int
    let externalWarningCount: Int
    let analyzerWarningCount: Int
    let testCount: Int
    let testFailedCount: Int
    let testSkippedCount: Int
}
