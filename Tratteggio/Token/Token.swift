import Foundation

/// Role: Token. One word chip beside the Lemma hole. A miss smudges the chip and keeps the hole. Colour is never the only signal.
struct Token: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var spoken: String
    var kind: LemmaKind
    var isMatch: Bool
    var isSmudged: Bool

    func fills(_ lemma: Lemma) -> Bool {
        isMatch && Self.same(spoken, lemma.hole)
    }

    static func hanging(
        id: UUID = UUID(),
        spoken: String,
        kind: LemmaKind,
        isMatch: Bool
    ) -> Token {
        Token(
            id: id,
            spoken: spoken,
            kind: kind,
            isMatch: isMatch,
            isSmudged: false
        )
    }

    static func same(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(rhs.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }
}

/// Role: Token. Builds chips: one matching hole Token plus extras from the crate, then the shelf.
enum ChipCast {
    static let chipCount = 4

    static func hang(
        lemma: Lemma,
        crate: [Work],
        shelf: [CatalogRow],
        smudges: [SmudgeMark]
    ) -> [Token] {
        let hole = lemma.hole
        var tokens = [Token.hanging(spoken: hole, kind: lemma.kind, isMatch: true)]
        var seen = Set([hole.lowercased()])

        let peers = crate
            .filter { $0.id != lemma.workID }
            .sorted { lhs, rhs in
                if lhs.daykey != rhs.daykey { return lhs.daykey < rhs.daykey }
                return lhs.objectID < rhs.objectID
            }
        for peer in peers {
            for word in LemmaPunch.words(in: lemma.kind.spoken(on: peer)) {
                let key = word.lowercased()
                guard seen.insert(key).inserted else { continue }
                tokens.append(Token.hanging(spoken: word, kind: lemma.kind, isMatch: false))
                if tokens.count == chipCount { break }
            }
            if tokens.count == chipCount { break }
        }
        if tokens.count < chipCount {
            let chosenID = crate.first { $0.id == lemma.workID }?.objectID
            for row in shelf where row.objectID != chosenID {
                for word in LemmaPunch.words(in: lemma.kind.spoken(on: row)) {
                    let key = word.lowercased()
                    guard seen.insert(key).inserted else { continue }
                    tokens.append(Token.hanging(spoken: word, kind: lemma.kind, isMatch: false))
                    if tokens.count == chipCount { break }
                }
                if tokens.count == chipCount { break }
            }
        }
        applySmudges(smudges.filter { $0.workID == lemma.workID }, to: &tokens)
        return tokens
    }

    static func applySmudges(_ marks: [SmudgeMark], to tokens: inout [Token]) {
        let ids = Set(marks.map(\.tokenID))
        let spoken = Set(marks.map { $0.spoken.lowercased() })
        for index in tokens.indices where ids.contains(tokens[index].id) || spoken.contains(tokens[index].spoken.lowercased()) {
            tokens[index].isSmudged = true
        }
    }

    static func pinMatch(_ tokens: [Token]) -> [Token] {
        tokens.sorted { lhs, rhs in
            if lhs.isMatch != rhs.isMatch {
                return lhs.isMatch && !rhs.isMatch
            }
            return lhs.spoken < rhs.spoken
        }
    }

    static func spin(_ tokens: [Token], salt: Int) -> [Token] {
        guard tokens.count > 1 else { return tokens }
        var shift = abs(salt) % tokens.count
        if shift == 0 {
            shift = 1
        }
        return Array(tokens[shift...]) + Array(tokens[..<shift])
    }

    static func salt(_ id: UUID) -> Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
}
