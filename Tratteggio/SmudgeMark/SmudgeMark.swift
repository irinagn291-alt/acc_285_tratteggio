import Foundation

/// Role: SmudgeMark. A miss on a Token chip. The Shard and the hole stay. Reviewable on Saved.
struct SmudgeMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var lemmaID: UUID
    var tokenID: UUID
    var spoken: String
    var daykey: Int
}
