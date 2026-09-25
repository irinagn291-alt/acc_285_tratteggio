import XCTest
@testable import Tratteggio

/// Architecture: Loupe ADT fold Shut | Framed | Restored. Frame writes a Shard crop and a Lemma that is artist XOR title with one Token removed. No View.
final class LoupeFoldTests: XCTestCase {
    private var calendar: Calendar { TratteggioGMT.calendar }
    private var now: Date { TratteggioGMT.instant(2026, 9, 18) }
    private var shelf: [CatalogRow] { CrateShelf.bundled.rows }

    func test_architecture_notRestoredSampling_xorPunch_patchOnShutRefuse_missKeep_undoFoldBack_restoredLeaves_duplicateFocus_mute() throws {
        var loupe = Loupe.empty
        XCTAssertEqual(foldLabel(loupe), "mute")
        try loupe.frameShard(shelf: shelf, pinMatchFirst: true)
        XCTAssertEqual(loupe.sign, .mute)
        XCTAssertTrue(loupe.mute)

        XCTAssertThrowsError(
            try loupe.patchToken(tokenID: UUID(), now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? LoupeFault, .patchOnShut)
        }

        for row in shelf.prefix(4) {
            _ = try loupe.crateShut(row, now: now, calendar: calendar)
        }
        XCTAssertEqual(foldLabel(loupe), "shut")

        try loupe.frameShard(shelf: shelf, pinKind: .maker, pinHoleIndex: 0, pinMatchFirst: true)
        XCTAssertEqual(foldLabel(loupe), "framed")
        let card = try XCTUnwrap(loupe.card)
        XCTAssertEqual(card.tokens.filter(\.isMatch).count, 1)
        XCTAssertTrue(card.tokens.allSatisfy { $0.kind == .maker })
        XCTAssertEqual(card.lemma.kind, .maker)
        XCTAssertTrue(card.lemma.holdsMaker)
        XCTAssertFalse(card.lemma.holdsTitle)
        XCTAssertEqual(card.lemma.hole, LemmaPunch.words(in: loupe.framedWork?.maker ?? "")[0])
        XCTAssertNotEqual(card.lemma.display(filled: false), loupe.framedWork?.maker)
        XCTAssertEqual(loupe.framedWork?.fold, .framed)
        XCTAssertTrue(loupe.shutWorks.allSatisfy { $0.fold == .shut })
        XCTAssertEqual(card.shard.workID, loupe.framedWork?.id)
        XCTAssertGreaterThan(card.shard.width, 0)
        XCTAssertTrue(loupe.canFrame)
        XCTAssertTrue(loupe.framePool.contains { $0.id == loupe.framedWork?.id })

        let hangingID = try XCTUnwrap(loupe.card?.lemma.workID)
        let decoy = try XCTUnwrap(loupe.card?.tokens.first { !$0.isMatch })
        try loupe.smudgeToken(tokenID: decoy.id, now: now, calendar: calendar)
        XCTAssertEqual(loupe.card?.lemma.workID, hangingID)
        XCTAssertEqual(foldLabel(loupe), "smudge")
        XCTAssertTrue(loupe.card?.tokens.contains { $0.id == decoy.id && $0.isSmudged } ?? false)
        XCTAssertEqual(loupe.framedWork?.fold, .framed)
        XCTAssertEqual(loupe.reviewableSmudges.count, 1)
        XCTAssertEqual(loupe.card?.lemma.hole.isEmpty, false)

        try loupe.undoMark()
        XCTAssertEqual(loupe.framedWork?.fold, .framed)
        XCTAssertEqual(foldLabel(loupe), "framed")
        XCTAssertFalse(loupe.card?.tokens.contains { $0.id == decoy.id && $0.isSmudged } ?? true)
        XCTAssertEqual(loupe.card?.lemma.workID, hangingID)

        try loupe.smudgeToken(tokenID: decoy.id, now: now, calendar: calendar)
        let match = try XCTUnwrap(loupe.card?.tokens.first { $0.isMatch })
        _ = try loupe.patchToken(tokenID: match.id, now: now, calendar: calendar)
        XCTAssertEqual(loupe.works.first { $0.id == hangingID }?.fold, .restored)
        XCTAssertFalse(loupe.framePool.contains { $0.id == hangingID })
        XCTAssertEqual(loupe.card?.lemma.workID, hangingID)
        XCTAssertEqual(loupe.patchMarks.count, 1)
        XCTAssertEqual(loupe.sign, .restored)

        try loupe.undoMark()
        XCTAssertEqual(loupe.works.first { $0.id == hangingID }?.fold, .framed)
        XCTAssertEqual(loupe.card?.lemma.workID, hangingID)
        XCTAssertTrue(loupe.framePool.contains { $0.id == hangingID })
        XCTAssertEqual(foldLabel(loupe), "smudge")

        let hanging = try XCTUnwrap(loupe.works.first { $0.id == hangingID })
        let sameRow = try XCTUnwrap(shelf.first { $0.objectID == hanging.objectID })
        let again = try loupe.crateShut(sameRow, now: now, calendar: calendar)
        guard case .focused(let focusedID) = again else {
            return XCTFail("expected focus")
        }
        XCTAssertEqual(focusedID, hangingID)
        XCTAssertEqual(loupe.works.filter { $0.objectID == hanging.objectID }.count, 1)
        XCTAssertEqual(loupe.works.first { $0.id == hangingID }?.fold, .framed)

        _ = try loupe.patchToken(
            tokenID: try XCTUnwrap(loupe.card?.tokens.first { $0.isMatch }?.id),
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(loupe.works.first { $0.id == hangingID }?.fold, .restored)
        try loupe.frameShard(shelf: shelf, pinMatchFirst: true)
        XCTAssertNotEqual(loupe.framedWork?.id, hangingID)
        XCTAssertEqual(loupe.framedWork?.fold, .framed)
        XCTAssertFalse(loupe.framePool.contains { $0.id == hangingID })
    }

    func test_primaryVerb_emptyPopulatedInvalid() throws {
        var loupe = Loupe.empty
        XCTAssertThrowsError(
            try loupe.patchToken(tokenID: UUID(), now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? LoupeFault, .patchOnShut)
        }

        _ = try loupe.crateShut(shelf[1], now: now, calendar: calendar)
        _ = try loupe.crateShut(shelf[2], now: now, calendar: calendar)
        try loupe.frameShard(shelf: shelf, pinKind: .title, pinMatchFirst: true)
        XCTAssertTrue(loupe.canPatch)

        XCTAssertThrowsError(
            try loupe.patchToken(tokenID: UUID(), now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? LoupeFault, .tokenUnknown)
        }

        let miss = try XCTUnwrap(loupe.card?.tokens.first { !$0.isMatch })
        XCTAssertThrowsError(
            try loupe.patchToken(tokenID: miss.id, now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? LoupeFault, .tokenMismatch)
        }
        XCTAssertEqual(loupe.framedWork?.fold, .framed)

        let match = try XCTUnwrap(loupe.card?.tokens.first { $0.isMatch })
        _ = try loupe.patchToken(tokenID: match.id, now: now, calendar: calendar)
        XCTAssertEqual(loupe.patchMarks.count, 1)
        XCTAssertEqual(loupe.restoredWorks.count, 1)
        XCTAssertFalse(loupe.canPatch)
    }

    func test_lemmaXorNeverStoresBothNamesAndPunchesOneToken() throws {
        var loupe = Loupe.empty
        _ = try loupe.crateShut(shelf[0], now: now, calendar: calendar)
        try loupe.frameShard(shelf: shelf, pinKind: .title, pinHoleIndex: 0, pinMatchFirst: true)
        let lemma = try XCTUnwrap(loupe.card?.lemma)
        XCTAssertTrue(lemma.holdsTitle)
        XCTAssertFalse(lemma.holdsMaker)
        XCTAssertEqual(lemma.words.count, LemmaPunch.words(in: shelf[0].title).count)
        XCTAssertEqual(lemma.hole, LemmaPunch.words(in: shelf[0].title)[0])
        XCTAssertNotEqual(lemma.display(filled: false), shelf[0].title)
        XCTAssertNotEqual(lemma.hole, shelf[0].maker)
        XCTAssertTrue(loupe.card?.tokens.allSatisfy { $0.kind == .title } ?? false)
        XCTAssertGreaterThanOrEqual(loupe.card?.tokens.count ?? 0, 2)

        var other = Loupe.empty
        _ = try other.crateShut(shelf[0], now: now, calendar: calendar)
        try other.frameShard(shelf: shelf, pinKind: .maker, pinHoleIndex: 0, pinMatchFirst: true)
        let makerLemma = try XCTUnwrap(other.card?.lemma)
        XCTAssertTrue(makerLemma.holdsMaker)
        XCTAssertFalse(makerLemma.holdsTitle)
        XCTAssertEqual(makerLemma.hole, LemmaPunch.words(in: shelf[0].maker)[0])
    }

    func test_emptyCrateWritesMute() throws {
        var loupe = Loupe.empty
        try loupe.frameShard(shelf: shelf, pinMatchFirst: true)
        XCTAssertTrue(loupe.mute)
        XCTAssertNil(loupe.card)
        XCTAssertEqual(loupe.sign, .mute)
    }

    func test_twist_frameThenPatch_missKeepsHole_patchOnShutRefused() throws {
        var loupe = Loupe.empty
        XCTAssertThrowsError(try loupe.patchToken(tokenID: UUID(), now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? LoupeFault, .patchOnShut)
        }
        _ = try loupe.crateShut(shelf[0], now: now, calendar: calendar)
        _ = try loupe.crateShut(shelf[1], now: now, calendar: calendar)
        try loupe.frameShard(shelf: shelf, pinKind: .title, pinMatchFirst: true)
        let hole = try XCTUnwrap(loupe.card?.lemma.hole)
        XCTAssertFalse(hole.isEmpty)
        let extras = loupe.card?.tokens.filter { !$0.isMatch } ?? []
        XCTAssertFalse(extras.isEmpty)
        try loupe.smudgeToken(tokenID: extras[0].id, now: now, calendar: calendar)
        XCTAssertEqual(loupe.framedWork?.fold, .framed)
        XCTAssertEqual(loupe.card?.lemma.hole, hole)
        let match = try XCTUnwrap(loupe.card?.tokens.first { $0.isMatch })
        _ = try loupe.patchToken(tokenID: match.id, now: now, calendar: calendar)
        XCTAssertNil(loupe.framedWork)
        XCTAssertEqual(loupe.restoredWorks.count, 1)
    }

    func test_frameSamplesNotRestoredPoolWhileFramed() throws {
        var loupe = Loupe.empty
        let first = try crate(loupe: &loupe, row: shelf[0])
        let second = try crate(loupe: &loupe, row: shelf[1])
        try loupe.frameShard(shelf: shelf, pinKind: .title, pinWorkID: first, pinMatchFirst: true)
        XCTAssertTrue(loupe.canFrame)
        XCTAssertTrue(loupe.framePool.contains { $0.id == first })
        XCTAssertTrue(loupe.framePool.contains { $0.id == second })

        try loupe.frameShard(shelf: shelf, pinKind: .maker, pinWorkID: second, pinMatchFirst: true)
        XCTAssertEqual(loupe.works.first { $0.id == first }?.fold, .framed)
        XCTAssertEqual(loupe.works.first { $0.id == second }?.fold, .framed)
        XCTAssertEqual(loupe.card?.lemma.workID, second)
        XCTAssertEqual(loupe.framedWork?.id, second)
        XCTAssertTrue(loupe.canFrame)
    }

    func test_undoPatchLeavesUnrelatedFramedWork() throws {
        var loupe = Loupe.empty
        let first = try crate(loupe: &loupe, row: shelf[0])
        let second = try crate(loupe: &loupe, row: shelf[1])
        try loupe.frameShard(shelf: shelf, pinKind: .title, pinWorkID: first, pinMatchFirst: true)
        try loupe.frameShard(shelf: shelf, pinKind: .title, pinWorkID: second, pinMatchFirst: true)
        let match = try XCTUnwrap(loupe.card?.tokens.first { $0.isMatch })
        _ = try loupe.patchToken(tokenID: match.id, now: now, calendar: calendar)
        XCTAssertEqual(loupe.works.first { $0.id == second }?.fold, .restored)
        XCTAssertEqual(loupe.works.first { $0.id == first }?.fold, .framed)

        try loupe.undoMark()
        XCTAssertEqual(loupe.works.first { $0.id == second }?.fold, .framed)
        XCTAssertEqual(loupe.works.first { $0.id == first }?.fold, .framed)
        XCTAssertEqual(loupe.card?.lemma.workID, second)
        XCTAssertTrue(loupe.framePool.contains { $0.id == first })
        XCTAssertTrue(loupe.framePool.contains { $0.id == second })
    }

    func test_seededHomeKeepsFrameEnabled() {
        let loupe = LoupeSeed.loupe(now: now, calendar: calendar)
        XCTAssertNotNil(loupe.card)
        XCTAssertEqual(loupe.framedWork?.fold, .framed)
        XCTAssertTrue(loupe.canFrame)
        XCTAssertFalse(loupe.framePool.isEmpty)
        XCTAssertTrue(loupe.framePool.contains { $0.fold == .framed })
        XCTAssertFalse(loupe.framePool.contains { $0.fold == .restored })
    }

    func test_unpinnedFrameAdvancesPastHangingWork() throws {
        var loupe = Loupe.empty
        let first = try crate(loupe: &loupe, row: shelf[0])
        let second = try crate(loupe: &loupe, row: shelf[1])
        try loupe.frameShard(shelf: shelf, pinKind: .title, pinWorkID: first, pinMatchFirst: true)
        XCTAssertEqual(loupe.card?.lemma.workID, first)

        try loupe.frameShard(shelf: shelf, pinMatchFirst: true)
        XCTAssertEqual(loupe.card?.lemma.workID, second)
        XCTAssertEqual(loupe.works.first { $0.id == first }?.fold, .framed)
        XCTAssertEqual(loupe.works.first { $0.id == second }?.fold, .framed)

        try loupe.frameShard(shelf: shelf, pinMatchFirst: true)
        XCTAssertEqual(loupe.card?.lemma.workID, first)
    }

    func test_seededUnpinnedFrameLeavesThePinnedShard() throws {
        var loupe = LoupeSeed.loupe(now: now, calendar: calendar)
        let hanging = try XCTUnwrap(loupe.card?.lemma.workID)
        try loupe.frameShard(shelf: CrateShelf.bundled.rows)
        XCTAssertNotEqual(loupe.card?.lemma.workID, hanging)
        XCTAssertEqual(loupe.works.first { $0.id == hanging }?.fold, .framed)
        XCTAssertTrue(loupe.canFrame)
    }

    private func crate(loupe: inout Loupe, row: CatalogRow) throws -> UUID {
        let focus = try loupe.crateShut(row, now: now, calendar: calendar)
        guard case .inserted(let id) = focus else {
            XCTFail("expected insert")
            return UUID()
        }
        return id
    }

    private func foldLabel(_ loupe: Loupe) -> String {
        loupe.sign.rawValue
    }
}
