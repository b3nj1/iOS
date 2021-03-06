import Foundation
import Version

extension Version {
    private static func replacements() throws -> [(regex: NSRegularExpression, replacement: String)] {
        [
            (regex: try NSRegularExpression(pattern: #"\.([a-zA-Z])"#, options: []), replacement: #"-$1"#),
            (regex: try NSRegularExpression(pattern: #"([0-9])([a-zA-Z])"#, options: []), replacement: #"$1-$2"#)
        ]
    }

    init(hassVersion: String) throws {
        let sanitized = try Self.replacements().reduce(into: hassVersion) { result, pair in
            result = pair.regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(location: 0, length: result.count),
                withTemplate: pair.replacement
            )
        }

        let parser = VersionParser(strict: false)
        self = try parser.parse(string: sanitized)
    }
}
