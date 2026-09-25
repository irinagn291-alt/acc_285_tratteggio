import XCTest
@testable import Tratteggio

/// Family invariant: Quiz draws from saved works. Misses are reviewable. Collecting without a test is the crate clone.
final class FamilyInvariantTests: XCTestCase {
    private var calendar: Calendar { TratteggioGMT.calendar }
    private var now: Date { TratteggioGMT.instant(2026, 9, 18) }
    private var shelf: [CatalogRow] { CrateShelf.bundled.rows }

    func test_quizDrawsFromSavedWorks_missesStayReviewable_cratingIsNotPatching() throws {
        var loupe = Loupe.empty
        XCTAssertFalse(loupe.canPatch)
        XCTAssertEqual(loupe.sign, .mute)

        let row = shelf[0]
        let stocked = try loupe.crateShut(row, now: now, calendar: calendar)
        guard case .inserted(let workID) = stocked else {
            return XCTFail("expected insert")
        }
        XCTAssertEqual(loupe.works.count, 1)
        XCTAssertEqual(loupe.works[0].fold, .shut)
        XCTAssertFalse(loupe.restoredWorks.contains { $0.id == workID })
        XCTAssertTrue(loupe.shutWorks.contains { $0.id == workID })
        XCTAssertFalse(loupe.canPatch)

        XCTAssertThrowsError(
            try loupe.patchToken(tokenID: UUID(), now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? LoupeFault, .patchOnShut)
        }
        XCTAssertEqual(loupe.works[0].fold, .shut)
        XCTAssertTrue(loupe.patchMarks.isEmpty)

        try loupe.frameShard(shelf: shelf, pinKind: .title, pinWorkID: workID, pinMatchFirst: true)
        XCTAssertEqual(loupe.framedWork?.id, workID)
        XCTAssertEqual(loupe.framedWork?.title, row.title)
        XCTAssertEqual(loupe.card?.lemma.kind, .title)
        XCTAssertTrue(loupe.card?.lemma.holdsTitle ?? false)
        XCTAssertFalse(loupe.card?.lemma.holdsMaker ?? true)
        XCTAssertEqual(loupe.framedWork?.fold, .framed)
        XCTAssertEqual(loupe.card?.tokens.filter(\.isMatch).count, 1)
        XCTAssertTrue(loupe.canPatch)
        XCTAssertTrue(loupe.canFrame)
        XCTAssertTrue(loupe.framePool.contains { $0.id == workID })
        XCTAssertTrue(row.title.contains(loupe.card?.lemma.hole ?? "missing-hole"))

        let decoy = try XCTUnwrap(loupe.card?.tokens.first { !$0.isMatch })
        try loupe.smudgeToken(tokenID: decoy.id, now: now, calendar: calendar)
        XCTAssertEqual(loupe.framedWork?.id, workID)
        XCTAssertEqual(loupe.framedWork?.fold, .framed)
        XCTAssertEqual(loupe.reviewableSmudges.count, 1)
        XCTAssertEqual(loupe.reviewableSmudges.first?.workID, workID)
        XCTAssertEqual(loupe.sign, .smudge)
        XCTAssertEqual(loupe.restoredWorks.count, 0)
        XCTAssertTrue(loupe.framePool.contains { $0.id == workID })
        XCTAssertTrue(loupe.canPatch)
        XCTAssertEqual(loupe.card?.lemma.hole, loupe.card?.lemma.hole)
    }

    func test_restoredWorksLeaveTheFramePool() throws {
        var loupe = try shutAndFramed(count: 2, kind: .maker)
        let firstID = try XCTUnwrap(loupe.card?.lemma.workID)
        let match = try XCTUnwrap(loupe.card?.tokens.first { $0.isMatch })
        _ = try loupe.patchToken(tokenID: match.id, now: now, calendar: calendar)
        XCTAssertEqual(loupe.works.first { $0.id == firstID }?.fold, .restored)
        XCTAssertEqual(loupe.restoredWorks.count, 1)
        XCTAssertFalse(loupe.framePool.contains { $0.id == firstID })
        XCTAssertEqual(loupe.card?.lemma.workID, firstID)
        XCTAssertEqual(loupe.sign, .restored)
        XCTAssertFalse(loupe.canPatch)
    }

    private func shutAndFramed(count: Int, kind: LemmaKind) throws -> Loupe {
        var loupe = Loupe.empty
        for row in shelf.prefix(count) {
            _ = try loupe.crateShut(row, now: now, calendar: calendar)
        }
        try loupe.frameShard(shelf: shelf, pinKind: kind, pinMatchFirst: true)
        return loupe
    }
}
