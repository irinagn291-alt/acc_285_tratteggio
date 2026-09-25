import Foundation

/// Role: PatchMark. The tapped Token filled the Lemma hole. Framed folds to Restored and leaves the frame pool for Saved.
struct PatchMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var lemmaID: UUID
    var spoken: String
    var kind: LemmaKind
    var daykey: Int
    var card: FramedCard
}
