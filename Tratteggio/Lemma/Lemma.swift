import Foundation

/// Role: Lemma. Artist XOR title, never both. Frame punches one Token so the caption is a hole.
enum LemmaKind: String, Codable, Sendable, Equatable {
    case maker
    case title

    static func xorPick(objectID: Int) -> LemmaKind {
        objectID.isMultiple(of: 2) ? .maker : .title
    }

    func spoken(on work: Work) -> String {
        switch self {
        case .maker:
            return work.maker
        case .title:
            return work.title
        }
    }

    func spoken(on row: CatalogRow) -> String {
        switch self {
        case .maker:
            return row.maker
        case .title:
            return row.title
        }
    }
}

/// Role: Lemma. Pierced caption under the Shard. The hole is one Token from maker or title.
struct Lemma: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var kind: LemmaKind
    var words: [String]
    var holeIndex: Int

    var hole: String {
        guard words.indices.contains(holeIndex) else { return "" }
        return words[holeIndex]
    }

    var holdsMaker: Bool { kind == .maker }
    var holdsTitle: Bool { kind == .title }

    func display(filled: Bool) -> String {
        guard !words.isEmpty else { return "" }
        return words.enumerated().map { index, word in
            if index == holeIndex, !filled {
                return ""
            }
            return word
        }.joined(separator: " ")
    }
}

/// Role: Lemma. Splits maker or title and punches one Token. Named punchLemma in the loupe lexicon.
enum LemmaPunch {
    static func words(in text: String) -> [String] {
        let pieces = text.split(whereSeparator: { $0.isWhitespace || $0 == "/" })
        var words: [String] = []
        for piece in pieces {
            let trimmed = piece.trimmingCharacters(in: Self.edgeMarks)
            if !trimmed.isEmpty {
                words.append(String(trimmed))
            }
        }
        if words.isEmpty {
            let fallback = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !fallback.isEmpty {
                words.append(fallback)
            }
        }
        return words
    }

    static func punch(
        work: Work,
        kind: LemmaKind,
        holeIndex: Int? = nil,
        lemmaID: UUID = UUID()
    ) -> Lemma {
        let source = kind.spoken(on: work)
        let words = words(in: source)
        let count = max(words.count, 1)
        let index: Int
        if let holeIndex {
            index = abs(holeIndex) % count
        } else {
            index = abs(work.objectID) % count
        }
        let resolved = words.isEmpty ? [source] : words
        return Lemma(
            id: lemmaID,
            workID: work.id,
            kind: kind,
            words: resolved,
            holeIndex: min(index, resolved.count - 1)
        )
    }

    private static let edgeMarks = CharacterSet.punctuationCharacters
        .union(.symbols)
        .subtracting(CharacterSet(charactersIn: "'’"))
}
