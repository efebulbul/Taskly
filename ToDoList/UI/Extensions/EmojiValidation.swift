import Foundation

// MARK: - Emoji doğrulama
extension String {
    var isSingleEmoji: Bool {
        count == 1 && first?.isEmoji == true
    }
}

extension Character {
    var isEmoji: Bool {
        unicodeScalars.contains { $0.properties.isEmoji }
    }
}
