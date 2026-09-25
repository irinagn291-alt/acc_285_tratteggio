import XCTest
@testable import Tratteggio

final class LoupeStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar { TratteggioGMT.calendar }
    private var now: Date { TratteggioGMT.instant(2026, 9, 18) }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "ttg.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    @MainActor
    func test_roundTrip_reloadPreservesMarksAndFold() async throws {
        let store = makeStore()
        await store.load()
        for row in CrateShelf.bundled.rows.prefix(4) {
            try await store.crateShut(row, now: now, calendar: calendar)
        }
        try await store.frameShard(pinKind: .title)
        let decoy = try XCTUnwrap(store.loupe.card?.tokens.first { !$0.isMatch })
        try await store.smudgeToken(tokenID: decoy.id, now: now, calendar: calendar)
        let match = try XCTUnwrap(store.loupe.card?.tokens.first { $0.isMatch })
        try await store.patchToken(tokenID: match.id, now: now, calendar: calendar)
        await store.flush()

        let relaunched = makeStore()
        await relaunched.load()
        XCTAssertNil(relaunched.warning)
        XCTAssertEqual(relaunched.loupe.works.count, 4)
        XCTAssertEqual(relaunched.loupe.patchMarks.count, 1)
        XCTAssertEqual(relaunched.loupe.smudgeMarks.count, 1)
        XCTAssertEqual(relaunched.loupe.restoredWorks.count, 1)
        XCTAssertEqual(relaunched.loupe.sign, .restored)
        XCTAssertNotEqual(relaunched.loupe.sign, .mute)
        XCTAssertNotNil(defaults.data(forKey: LoupeKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("loupe.json").path))
        let folds = relaunched.loupe.works.map(\.fold)
        XCTAssertEqual(folds.filter { $0 == .restored }.count, 1)
        XCTAssertEqual(folds.filter { $0 == .framed }.count, 0)
        let json = String(decoding: try XCTUnwrap(defaults.data(forKey: LoupeKey.snapshot)), as: UTF8.self)
        XCTAssertTrue(json.contains("shut") || json.contains("framed") || json.contains("restored"))
        XCTAssertFalse(json.contains("isRestored"))
    }

    @MainActor
    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        await store.load()
        try await store.crateShut(CrateShelf.bundled.rows[0], now: now, calendar: calendar)
        await store.flush()
        if let good = defaults.data(forKey: LoupeKey.snapshot) {
            defaults.set(good, forKey: LoupeKey.backup)
        }
        let file = directory.appendingPathComponent("loupe.json")
        let backup = directory.appendingPathComponent("loupe.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: LoupeKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = makeStore()
        await loaded.load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.loupe.works.count, 1)
    }

    @MainActor
    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: LoupeKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("loupe.json"))
        let store = makeStore()
        await store.load()
        XCTAssertEqual(store.warning, .startedEmpty)
        XCTAssertTrue(store.loupe.works.isEmpty)
        XCTAssertFalse(store.loupe.onboardingComplete)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let loupe = LoupeSeed.loupe(now: now, calendar: calendar)
        let data = try LoupeDocument.encode(loupe)
        let decoded = try LoupeDocument.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.works.count, loupe.works.count)
        XCTAssertEqual(decoded.card?.lemma.workID, loupe.card?.lemma.workID)
        XCTAssertEqual(decoded.smudgeMarks.count, loupe.smudgeMarks.count)
        XCTAssertTrue(decoded.works.contains { $0.fold == .restored })
        XCTAssertTrue(decoded.works.contains { $0.fold == .framed })
        XCTAssertTrue(decoded.works.contains { $0.fold == .shut })
        XCTAssertFalse(decoded.mute)

        XCTAssertThrowsError(try LoupeDocument.decode(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? LoupeCodecError, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try LoupeDocument.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? LoupeCodecError, .corrupt)
        }
    }

    @MainActor
    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        await store.load()
        try await store.crateShut(CrateShelf.bundled.rows[0], now: now, calendar: calendar)
        await store.flush()
        await store.resetAllData()
        await store.load()
        XCTAssertTrue(store.loupe.works.isEmpty)
        XCTAssertFalse(store.loupe.onboardingComplete)
        XCTAssertNil(defaults.data(forKey: LoupeKey.snapshot))
        XCTAssertNil(defaults.data(forKey: LoupeKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    @MainActor
    func test_onboardingFlagDebouncesUntilFlush() async throws {
        let store = makeStore()
        await store.load()
        await store.setOnboardingComplete(true)
        await store.flush()
        let loaded = makeStore()
        await loaded.load()
        XCTAssertTrue(loaded.loupe.onboardingComplete)
    }

    #if targetEnvironment(simulator)
    @MainActor
    func test_simulatorSeedWritesOnceAndEnablesPatch() async throws {
        let store = makeStore()
        await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let firstWorks = store.loupe.works.count
        await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertEqual(store.loupe.works.count, firstWorks)
        XCTAssertTrue(store.loupe.onboardingComplete)
        XCTAssertTrue(store.loupe.canPatch)
        XCTAssertTrue(store.loupe.canFrame)
        XCTAssertEqual(store.loupe.framedWork?.fold, .framed)
        XCTAssertNotEqual(store.loupe.sign, .mute)
        XCTAssertGreaterThanOrEqual(store.loupe.works.count, 6)
        XCTAssertGreaterThanOrEqual(store.loupe.patchMarks.count, 1)
        XCTAssertGreaterThanOrEqual(store.loupe.smudgeMarks.count, 2)
        XCTAssertGreaterThanOrEqual(store.loupe.card?.tokens.filter { !$0.isSmudged }.count ?? 0, 3)
        XCTAssertTrue(store.loupe.card?.tokens.contains { $0.isMatch && !$0.isSmudged } ?? false)
        XCTAssertTrue(defaults.bool(forKey: LoupeKey.demo))
        XCTAssertNotNil(defaults.data(forKey: LoupeKey.snapshot))
    }
    #endif

    @MainActor
    func test_seekFallsBackToLocalShelf() async throws {
        let store = makeStore(client: CatalogClient(carrier: FailingCarrier()))
        await store.load()
        let rows = try await store.seek("monet")
        XCTAssertEqual(rows.first?.title, CrateShelf.bundled.rows[0].title)
        XCTAssertGreaterThanOrEqual(rows.count, 8)
        XCTAssertEqual(store.lastSeekFault, .transport)
    }

    @MainActor
    func test_emptyQueryDoesNotHitNetwork() async throws {
        let log = RequestLog()
        let store = makeStore(client: CatalogClient(carrier: LoggingCarrier(log: log)))
        let rows = try await store.seek("   ")
        XCTAssertFalse(rows.isEmpty)
        let count = await log.count
        XCTAssertEqual(count, 0)
    }

    @MainActor
    private func makeStore(client: CatalogClient = CatalogClient(carrier: FailingCarrier())) -> LoupeStore {
        LoupeStore(
            directory: directory,
            suiteName: suiteName,
            client: client,
            shelf: .bundled,
            writeDelayNanoseconds: 0,
            seekDebounceNanoseconds: 0,
            pinMatchFirst: true
        )
    }
}

actor RequestLog {
    private var urls: [URL?] = []

    @discardableResult
    func append(_ url: URL?) -> Int {
        urls.append(url)
        return urls.count
    }

    var count: Int { urls.count }
}

struct FailingCarrier: CatalogCarrying {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.timedOut)
    }
}

struct LoggingCarrier: CatalogCarrying {
    let log: RequestLog

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        await log.append(request.url)
        throw URLError(.cannotConnectToHost)
    }
}
