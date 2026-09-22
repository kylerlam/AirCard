import Foundation

struct WalletCachedCard: Codable, Identifiable {
    let id: String
    let name: String
    let source: String
}

struct WalletCatalog: Codable {
    var paymentStatus: String
    var payments: [WalletCachedCard]
    var memberships: [WalletCachedCard]
    var warnings: [String]
    var cacheUpdatedAt: String?

    static let empty = WalletCatalog(paymentStatus: "unavailable", payments: [], memberships: [], warnings: [], cacheUpdatedAt: nil)

    func name(for id: String) -> String? {
        (payments + memberships).first(where: { $0.id == id })?.name
    }

    func pending(confirmedIDs: Set<String>, source: String) -> [WalletCachedCard] {
        let entries = source == "payment" ? payments : memberships
        var seen = Set<String>()
        return entries.filter { !confirmedIDs.contains($0.id) && seen.insert($0.id).inserted }
    }
}

struct WalletSavedCard: Codable, Equatable {
    let id: String
    var confirmed: Bool = false
    var imagePath: String? = nil
    var selected: Bool = true

    static func unique(_ entries: [WalletSavedCard]) -> [WalletSavedCard] {
        var result: [WalletSavedCard] = []
        var indices: [String: Int] = [:]
        for entry in entries {
            if let index = indices[entry.id] {
                result[index].confirmed = result[index].confirmed || entry.confirmed
                if result[index].imagePath == nil { result[index].imagePath = entry.imagePath }
            } else {
                indices[entry.id] = result.count
                result.append(entry)
            }
        }
        return result
    }
}

// A bare base64-like token in a Wallet log is not proof of a card.
// Require a pass/cache path, and preserve first appearance across the line.
enum WalletScanParser {
    static let path = try! NSRegularExpression(pattern: #"/([-A-Za-z0-9_+=]{20,64})\.(?:pkpass|cache|pkcache)(?=[/\s\"'\),]|$)"#)
    static let placeholders: Set<String> = ["M6nDwZrkYbFlsodLgCbvyFZQ1cc=", "kJL-D0rr-SZhbj2c8nK-OQ9hCMY=", "hwAtAmHKYwsQrJbT5cTNDsaxVME="]

    static func cardIDs(in line: String) -> [String] {
        var seen = Set<String>()
        return path.matches(in: line, range: NSRange(line.startIndex..., in: line)).compactMap { match in
            guard let range = Range(match.range(at: 1), in: line) else { return nil }
            let id = String(line[range])
            guard !placeholders.contains(id), seen.insert(id).inserted else { return nil }
            return id
        }
    }
}
