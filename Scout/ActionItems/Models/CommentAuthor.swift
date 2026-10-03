import Foundation

/// The author handle in a comment line, `  - <handle>: <text>`. The app's
/// parser and the engine's both accept only `[A-Za-z][A-Za-z0-9._-]*` there,
/// so the name from Settings is folded into that shape: accents dropped,
/// spaces turned into dashes, anything else removed, leading digits skipped.
/// An empty result falls back to "user", the Settings default.
nonisolated enum CommentAuthor {
    static let fallback = "user"

    static func handle(_ name: String) -> String {
        let folded = name.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        var out = ""
        var pendingDash = false
        for scalar in folded.unicodeScalars {
            if scalar.properties.isWhitespace {
                pendingDash = !out.isEmpty
                continue
            }
            let v = scalar.value
            let isLetter = (65...90).contains(v) || (97...122).contains(v)
            let isDigit = (48...57).contains(v)
            let isMark = v == 46 || v == 95 || v == 45   // . _ -
            guard isLetter || isDigit || isMark else { continue }
            if out.isEmpty && !isLetter { continue }
            if pendingDash {
                out.append("-")
                pendingDash = false
            }
            out.unicodeScalars.append(scalar)
        }
        return out.isEmpty ? fallback : out
    }

    /// Whether a parsed comment was written by this user.
    static func isOwn(commentAuthor: String, userName: String) -> Bool {
        commentAuthor.lowercased() == handle(userName).lowercased()
    }
}
