import Foundation

/// Role: Loupe. Simulator demo crate. Device never writes this. Key: ttg.demo.v1. Frames a live Shard so the opening Token can restore.
enum LoupeSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func loupe(
        now: Date = Date(),
        calendar: Calendar = .current,
        shelf: [CatalogRow] = CrateShelf.bundled.rows
    ) -> Loupe {
        let today = Daykey.stamp(now, calendar: calendar)
        func mount(_ row: CatalogRow, id: UUID, fold: LoupeFold, dayOffset: Int) -> Work {
            var work = Work.shut(
                from: row,
                id: id,
                daykey: Daykey.shifting(today, by: dayOffset, calendar: calendar)
            )
            work.fold = fold
            return work
        }

        let parasol = mount(shelf[0], id: fixed("11111111-0001-4000-8000-000000000001"), fold: .restored, dayOffset: -6)
        let watering = mount(shelf[1], id: fixed("11111111-0001-4000-8000-000000000002"), fold: .shut, dayOffset: -5)
        let boating = mount(shelf[2], id: fixed("11111111-0001-4000-8000-000000000003"), fold: .shut, dayOffset: -4)
        let ginevra = mount(shelf[3], id: fixed("11111111-0001-4000-8000-000000000004"), fold: .shut, dayOffset: -3)
        let white = mount(shelf[4], id: fixed("11111111-0001-4000-8000-000000000005"), fold: .shut, dayOffset: -2)
        let railway = mount(shelf[5], id: fixed("11111111-0001-4000-8000-000000000006"), fold: .shut, dayOffset: -1)
        let breeze = mount(shelf[6], id: fixed("11111111-0001-4000-8000-000000000007"), fold: .shut, dayOffset: 0)
        let shark = mount(shelf[7], id: fixed("11111111-0001-4000-8000-000000000008"), fold: .restored, dayOffset: -7)

        let restoredLemma = LemmaPunch.punch(
            work: parasol,
            kind: .title,
            holeIndex: 0,
            lemmaID: fixed("22222222-0001-4000-8000-000000000001")
        )
        let restoredTokens = [
            Token.hanging(id: fixed("33333333-0001-4000-8000-000000000001"), spoken: restoredLemma.hole, kind: .title, isMatch: true),
            Token.hanging(id: fixed("33333333-0001-4000-8000-000000000002"), spoken: "Boating", kind: .title, isMatch: false),
            Token.hanging(id: fixed("33333333-0001-4000-8000-000000000003"), spoken: "Railway", kind: .title, isMatch: false),
            Token.hanging(id: fixed("33333333-0001-4000-8000-000000000004"), spoken: "Symphony", kind: .title, isMatch: false),
        ]
        let restoredCard = FramedCard(
            shard: Shard.crop(work: parasol, id: fixed("44444444-0001-4000-8000-000000000001")),
            lemma: restoredLemma,
            tokens: restoredTokens
        )
        let olderLemma = LemmaPunch.punch(
            work: shark,
            kind: .maker,
            holeIndex: 0,
            lemmaID: fixed("22222222-0001-4000-8000-000000000002")
        )
        let olderCard = FramedCard(
            shard: Shard.crop(work: shark, id: fixed("44444444-0001-4000-8000-000000000002")),
            lemma: olderLemma,
            tokens: [
                Token.hanging(spoken: olderLemma.hole, kind: .maker, isMatch: true),
            ]
        )

        var loupe = Loupe(
            schemaVersion: Loupe.currentSchema,
            onboardingComplete: true,
            works: [parasol, watering, boating, ginevra, white, railway, breeze, shark],
            card: nil,
            patchMarks: [
                PatchMark(
                    id: fixed("55555555-0001-4000-8000-000000000001"),
                    workID: parasol.id,
                    lemmaID: restoredLemma.id,
                    spoken: restoredLemma.hole,
                    kind: .title,
                    daykey: parasol.daykey,
                    card: restoredCard
                ),
                PatchMark(
                    id: fixed("55555555-0001-4000-8000-000000000002"),
                    workID: shark.id,
                    lemmaID: olderLemma.id,
                    spoken: olderLemma.hole,
                    kind: .maker,
                    daykey: shark.daykey,
                    card: olderCard
                ),
            ],
            smudgeMarks: [
                SmudgeMark(
                    id: fixed("77777777-0001-4000-8000-000000000001"),
                    workID: parasol.id,
                    lemmaID: restoredLemma.id,
                    tokenID: restoredTokens[1].id,
                    spoken: restoredTokens[1].spoken,
                    daykey: parasol.daykey
                ),
                SmudgeMark(
                    id: fixed("77777777-0001-4000-8000-000000000002"),
                    workID: parasol.id,
                    lemmaID: restoredLemma.id,
                    tokenID: restoredTokens[2].id,
                    spoken: restoredTokens[2].spoken,
                    daykey: parasol.daykey
                ),
                SmudgeMark(
                    id: fixed("77777777-0001-4000-8000-000000000003"),
                    workID: shark.id,
                    lemmaID: olderLemma.id,
                    tokenID: fixed("33333333-0001-4000-8000-000000000010"),
                    spoken: "Monet",
                    daykey: shark.daykey
                ),
            ],
            markLog: [
                MarkRef(kind: .smudge, markID: fixed("77777777-0001-4000-8000-000000000001")),
                MarkRef(kind: .smudge, markID: fixed("77777777-0001-4000-8000-000000000002")),
                MarkRef(kind: .smudge, markID: fixed("77777777-0001-4000-8000-000000000003")),
                MarkRef(kind: .patch, markID: fixed("55555555-0001-4000-8000-000000000002")),
                MarkRef(kind: .patch, markID: fixed("55555555-0001-4000-8000-000000000001")),
            ],
            cachedRows: Array(shelf.prefix(8)),
            focusedWorkID: watering.id,
            mute: false
        )
        try? loupe.frameShard(
            shelf: shelf,
            pinKind: .maker,
            pinWorkID: watering.id,
            pinHoleIndex: 0,
            lemmaID: fixed("88888888-0001-4000-8000-000000000001"),
            shardID: fixed("99999999-0001-4000-8000-000000000001"),
            tokenIDs: [
                fixed("aaaaaaaa-0001-4000-8000-000000000001"),
                fixed("aaaaaaaa-0001-4000-8000-000000000002"),
                fixed("aaaaaaaa-0001-4000-8000-000000000003"),
                fixed("aaaaaaaa-0001-4000-8000-000000000004"),
            ],
            pinMatchFirst: true
        )
        return loupe
    }
}
