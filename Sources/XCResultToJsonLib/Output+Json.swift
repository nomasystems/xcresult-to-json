import Foundation

extension Output {
    var json: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try! encoder.encode(self)
    }
}
