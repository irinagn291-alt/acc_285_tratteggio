import Foundation

/// Role: Loupe. Closed algebraic fold Shut | Framed | Restored. A fourth case is a defect. Mute is a loupe write, never a fold case.
enum LoupeFold: String, Codable, Sendable, Equatable {
    case shut
    case framed
    case restored
}

/// Role: Loupe. Live status on Quiz. Smudge overlays Framed. Mute is not stored on Work.
enum LoupeSign: String, Sendable, Equatable {
    case mute
    case shut
    case framed
    case restored
    case smudge
}

/// Role: Loupe. Typed refusals. Patch on Shut is refused. Frame samples the not-Restored pool and is not refused while Framed.
enum LoupeFault: Error, Equatable, Sendable {
    case patchOnShut
    case smudgeOnShut
    case patchOnRestored
    case smudgeOnRestored
    case tokenUnknown
    case tokenMismatch
    case tokenSmudged
    case smudgeOnMatch
    case nothingToUndo
    case emptyObject
    case incompleteWork
}

/// Role: Loupe. Explore crate outcome. A repeated objectid focuses and does not reset the fold.
enum CrateFocus: Equatable, Sendable {
    case inserted(UUID)
    case focused(UUID)
}

/// Role: Loupe. Recoverable load outcome. Never crash on a corrupt snapshot.
enum LoupeWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Loupe. Ordered undo stack. Undo drops the newest PatchMark or SmudgeMark.
enum MarkKind: String, Codable, Sendable {
    case patch
    case smudge
}

struct MarkRef: Equatable, Sendable, Codable {
    var kind: MarkKind
    var markID: UUID
}

/// Role: Loupe. QuizCard. Magnified Shard, pierced Lemma, and Token chips hanging beside the hole.
struct FramedCard: Equatable, Sendable, Codable {
    var shard: Shard
    var lemma: Lemma
    var tokens: [Token]

    var matchToken: Token? {
        tokens.first(where: \.isMatch)
    }
}

/// Role: Loupe. In-memory fold over Works. Views call frameShard, patchToken, smudgeToken, and undoMark. Never a second plaque enum.
struct Loupe: Equatable, Sendable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var works: [Work]
    var card: FramedCard?
    var patchMarks: [PatchMark]
    var smudgeMarks: [SmudgeMark]
    var markLog: [MarkRef]
    var cachedRows: [CatalogRow]
    var focusedWorkID: UUID?
    var mute: Bool

    static let currentSchema = 1

    static let empty = Loupe(
        schemaVersion: currentSchema,
        onboardingComplete: false,
        works: [],
        card: nil,
        patchMarks: [],
        smudgeMarks: [],
        markLog: [],
        cachedRows: [],
        focusedWorkID: nil,
        mute: false
    )

    var shutWorks: [Work] {
        works.filter { $0.fold == .shut }
    }

    var framedWork: Work? {
        if let id = card?.lemma.workID,
           let hanging = works.first(where: { $0.id == id }),
           hanging.fold == .framed {
            return hanging
        }
        return works.first { $0.fold == .framed }
    }

    var restoredWorks: [Work] {
        works.filter { $0.fold == .restored }
    }

    var framePool: [Work] {
        works.filter { $0.fold != .restored }
    }

    var reviewableSmudges: [SmudgeMark] {
        smudgeMarks
    }

    var canPatch: Bool {
        switch sign {
        case .framed, .smudge:
            return card?.tokens.contains { $0.isMatch && !$0.isSmudged } == true
        case .mute, .shut, .restored:
            return false
        }
    }

    var canFrame: Bool {
        !framePool.isEmpty
    }

    var sign: LoupeSign {
        if let card, let work = works.first(where: { $0.id == card.lemma.workID }) {
            if work.fold == .restored {
                return .restored
            }
            if work.fold == .framed {
                if card.tokens.contains(where: \.isSmudged) {
                    return .smudge
                }
                return .framed
            }
        }
        if mute {
            return .mute
        }
        if framedWork != nil {
            return .framed
        }
        if !shutWorks.isEmpty {
            return .shut
        }
        return .mute
    }

    mutating func frameShard(
        shelf: [CatalogRow],
        pinKind: LemmaKind? = nil,
        pinWorkID: UUID? = nil,
        pinHoleIndex: Int? = nil,
        lemmaID: UUID = UUID(),
        shardID: UUID = UUID(),
        tokenIDs: [UUID]? = nil,
        pinMatchFirst: Bool = false
    ) throws {
        let ranked = framePool.sorted { lhs, rhs in
            if lhs.daykey != rhs.daykey { return lhs.daykey < rhs.daykey }
            if lhs.objectID != rhs.objectID { return lhs.objectID < rhs.objectID }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        let hangingID = pinWorkID == nil ? card?.lemma.workID : nil
        let pool: [Work]
        if let hangingID {
            let rest = ranked.filter { $0.id != hangingID }
            pool = rest.isEmpty ? ranked : rest
        } else {
            pool = ranked
        }
        let chosen: Work?
        if let pinWorkID {
            chosen = ranked.first { $0.id == pinWorkID }
        } else {
            chosen = pool.first
        }
        guard let chosen, let index = works.firstIndex(where: { $0.id == chosen.id }) else {
            mute = true
            card = nil
            return
        }
        let kind = pinKind ?? LemmaKind.xorPick(objectID: chosen.objectID)
        let lemma = LemmaPunch.punch(
            work: works[index],
            kind: kind,
            holeIndex: pinHoleIndex,
            lemmaID: lemmaID
        )
        let shard = Shard.crop(work: works[index], id: shardID)
        var tokens = ChipCast.hang(
            lemma: lemma,
            crate: works,
            shelf: shelf,
            smudges: smudgeMarks
        )
        if let tokenIDs, tokenIDs.count >= tokens.count {
            for index in tokens.indices {
                tokens[index].id = tokenIDs[index]
            }
        }
        tokens = pinMatchFirst ? ChipCast.pinMatch(tokens) : ChipCast.spin(tokens, salt: ChipCast.salt(chosen.id))
        ChipCast.applySmudges(smudgeMarks.filter { $0.workID == chosen.id }, to: &tokens)
        works[index].fold = .framed
        mute = false
        focusedWorkID = chosen.id
        card = FramedCard(shard: shard, lemma: lemma, tokens: tokens)
    }

    @discardableResult
    mutating func patchToken(
        tokenID: UUID,
        markID: UUID = UUID(),
        now: Date,
        calendar: Calendar
    ) throws -> PatchMark {
        guard let card else {
            throw LoupeFault.patchOnShut
        }
        guard let workIndex = works.firstIndex(where: { $0.id == card.lemma.workID }) else {
            throw LoupeFault.patchOnShut
        }
        switch works[workIndex].fold {
        case .shut:
            throw LoupeFault.patchOnShut
        case .restored:
            throw LoupeFault.patchOnRestored
        case .framed:
            break
        }
        guard let token = card.tokens.first(where: { $0.id == tokenID }) else {
            throw LoupeFault.tokenUnknown
        }
        if token.isSmudged {
            throw LoupeFault.tokenSmudged
        }
        guard token.isMatch, token.fills(card.lemma) else {
            throw LoupeFault.tokenMismatch
        }
        works[workIndex].fold = .restored
        let mark = PatchMark(
            id: markID,
            workID: card.lemma.workID,
            lemmaID: card.lemma.id,
            spoken: card.lemma.hole,
            kind: card.lemma.kind,
            daykey: Daykey.stamp(now, calendar: calendar),
            card: card
        )
        patchMarks.append(mark)
        markLog.append(MarkRef(kind: .patch, markID: markID))
        focusedWorkID = card.lemma.workID
        mute = false
        return mark
    }

    mutating func smudgeToken(
        tokenID: UUID,
        markID: UUID = UUID(),
        now: Date,
        calendar: Calendar
    ) throws {
        guard var card else {
            throw LoupeFault.smudgeOnShut
        }
        guard let work = works.first(where: { $0.id == card.lemma.workID }) else {
            throw LoupeFault.smudgeOnShut
        }
        switch work.fold {
        case .shut:
            throw LoupeFault.smudgeOnShut
        case .restored:
            throw LoupeFault.smudgeOnRestored
        case .framed:
            break
        }
        guard let index = card.tokens.firstIndex(where: { $0.id == tokenID }) else {
            throw LoupeFault.tokenUnknown
        }
        if card.tokens[index].isMatch {
            throw LoupeFault.smudgeOnMatch
        }
        if card.tokens[index].isSmudged {
            throw LoupeFault.tokenSmudged
        }
        card.tokens[index].isSmudged = true
        let mark = SmudgeMark(
            id: markID,
            workID: card.lemma.workID,
            lemmaID: card.lemma.id,
            tokenID: tokenID,
            spoken: card.tokens[index].spoken,
            daykey: Daykey.stamp(now, calendar: calendar)
        )
        smudgeMarks.append(mark)
        markLog.append(MarkRef(kind: .smudge, markID: markID))
        self.card = card
        focusedWorkID = work.id
    }

    mutating func undoMark() throws {
        guard let last = markLog.popLast() else {
            throw LoupeFault.nothingToUndo
        }
        switch last.kind {
        case .patch:
            undoPatch(markID: last.markID)
        case .smudge:
            undoSmudge(markID: last.markID)
        }
    }

    @discardableResult
    mutating func crateShut(
        _ row: CatalogRow,
        now: Date,
        calendar: Calendar,
        id: UUID = UUID()
    ) throws -> CrateFocus {
        guard row.objectID > 0 else {
            throw LoupeFault.emptyObject
        }
        let maker = row.maker.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !maker.isEmpty, !title.isEmpty else {
            throw LoupeFault.incompleteWork
        }
        if let existing = works.first(where: { $0.objectID == row.objectID }) {
            focusedWorkID = existing.id
            return .focused(existing.id)
        }
        var incoming = row
        incoming.maker = maker
        incoming.title = title
        let work = Work.shut(from: incoming, id: id, daykey: Daykey.stamp(now, calendar: calendar))
        works.append(work)
        remember(incoming)
        focusedWorkID = work.id
        if mute, framedWork == nil {
            mute = false
        }
        return .inserted(work.id)
    }

    mutating func remember(_ rows: [CatalogRow]) {
        for row in rows {
            remember(row)
        }
    }

    mutating func remember(_ row: CatalogRow) {
        guard row.objectID > 0 else { return }
        var stored = row
        stored.maker = row.maker.trimmingCharacters(in: .whitespacesAndNewlines)
        stored.title = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = cachedRows.firstIndex(where: { $0.objectID == stored.objectID }) {
            cachedRows[index] = stored
        } else {
            cachedRows.append(stored)
        }
    }

    mutating func setOnboardingComplete(_ flag: Bool) {
        onboardingComplete = flag
    }

    mutating func resetAllData() {
        self = .empty
    }

    func fallbackRows(shelf: [CatalogRow]) -> [CatalogRow] {
        var seen = Set<Int>()
        var merged: [CatalogRow] = []
        for row in cachedRows + shelf {
            if seen.insert(row.objectID).inserted {
                merged.append(row)
            }
        }
        return merged
    }

    private mutating func undoPatch(markID: UUID) {
        guard let index = patchMarks.firstIndex(where: { $0.id == markID }) else { return }
        let mark = patchMarks.remove(at: index)
        if let workIndex = works.firstIndex(where: { $0.id == mark.workID }) {
            works[workIndex].fold = .framed
        }
        card = mark.card
        mute = false
        focusedWorkID = mark.workID
    }

    private mutating func undoSmudge(markID: UUID) {
        guard let index = smudgeMarks.firstIndex(where: { $0.id == markID }) else { return }
        let mark = smudgeMarks.remove(at: index)
        guard var card else {
            focusedWorkID = mark.workID
            return
        }
        if let tokenIndex = card.tokens.firstIndex(where: { $0.id == mark.tokenID || $0.spoken == mark.spoken }) {
            card.tokens[tokenIndex].isSmudged = false
        }
        self.card = card
        focusedWorkID = mark.workID
    }
}
