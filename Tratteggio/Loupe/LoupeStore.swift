import Foundation
import Observation

/// Role: Loupe. Observable fold owner. Memory is the source of truth. UserDefaults is the projection. Views call frameShard, patchToken, smudgeToken, and undoMark.
@MainActor
@Observable
final class LoupeStore {
    static let seekDebounceNanoseconds: UInt64 = 500_000_000

    private(set) var loupe: Loupe
    private(set) var warning: LoupeWarning?
    private(set) var lastWriteError: String?
    private(set) var lastSeekFault: CatalogFault?

    private let vault: LoupeVault
    private let client: CatalogClient
    private let shelf: CrateShelf
    private let writeDelayNanoseconds: UInt64
    private let seekDebounce: UInt64
    private let pinMatchFirst: Bool
    private var persistTask: Task<Void, Never>?
    private var seekTask: Task<[CatalogRow], Error>?

    init(
        directory: URL,
        suiteName: String? = nil,
        client: CatalogClient = CatalogClient(),
        shelf: CrateShelf = .bundled,
        writeDelayNanoseconds: UInt64 = 280_000_000,
        seekDebounceNanoseconds: UInt64 = LoupeStore.seekDebounceNanoseconds,
        pinMatchFirst: Bool = false
    ) {
        self.vault = LoupeVault(directory: directory, suiteName: suiteName)
        self.client = client
        self.shelf = shelf
        self.writeDelayNanoseconds = writeDelayNanoseconds
        self.seekDebounce = seekDebounceNanoseconds
        self.pinMatchFirst = pinMatchFirst
        self.loupe = .empty
        self.warning = nil
        self.lastWriteError = nil
        self.lastSeekFault = nil
    }

    convenience init() {
        let directory: URL
        do {
            directory = try LoupeVault.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("Tratteggio", isDirectory: true)
        }
        self.init(directory: directory)
    }

    func load() async {
        let loaded = await vault.load()
        loupe = loaded.loupe
        warning = loaded.warning
        lastWriteError = nil
        lastSeekFault = nil
    }

    func frameShard(
        pinKind: LemmaKind? = nil,
        pinWorkID: UUID? = nil,
        pinHoleIndex: Int? = nil
    ) async throws {
        var next = loupe
        try next.frameShard(
            shelf: shelf.rows,
            pinKind: pinKind,
            pinWorkID: pinWorkID,
            pinHoleIndex: pinHoleIndex,
            pinMatchFirst: pinMatchFirst
        )
        loupe = next
        await persistNow()
    }

    func patchToken(tokenID: UUID, now: Date = Date(), calendar: Calendar = .current) async throws {
        var next = loupe
        _ = try next.patchToken(tokenID: tokenID, now: now, calendar: calendar)
        loupe = next
        await persistNow()
    }

    func smudgeToken(tokenID: UUID, now: Date = Date(), calendar: Calendar = .current) async throws {
        var next = loupe
        try next.smudgeToken(tokenID: tokenID, now: now, calendar: calendar)
        loupe = next
        await persistNow()
    }

    func undoMark() async throws {
        var next = loupe
        try next.undoMark()
        loupe = next
        await persistNow()
    }

    @discardableResult
    func crateShut(_ row: CatalogRow, now: Date = Date(), calendar: Calendar = .current) async throws -> CrateFocus {
        var next = loupe
        let focus = try next.crateShut(row, now: now, calendar: calendar)
        loupe = next
        await persistNow()
        return focus
    }

    func seek(_ query: String, page: Int = 1, pageSize: Int = 8) async throws -> [CatalogRow] {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            lastSeekFault = nil
            return loupe.fallbackRows(shelf: shelf.rows)
        }
        let client = self.client
        let delay = seekDebounce
        let task = Task { () throws -> [CatalogRow] in
            if delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            try Task.checkCancellation()
            return try await client.search(query: trimmed, page: page, pageSize: pageSize)
        }
        seekTask = task
        do {
            let rows = try await task.value
            if Task.isCancelled { throw CatalogFault.cancelled }
            if rows.isEmpty {
                lastSeekFault = .missing
                return loupe.fallbackRows(shelf: shelf.rows)
            }
            var next = loupe
            next.remember(rows)
            loupe = next
            lastSeekFault = nil
            await persistNow()
            return rows
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch let fault as CatalogFault where fault == .cancelled {
            throw fault
        } catch let fault as CatalogFault {
            lastSeekFault = fault
            return loupe.fallbackRows(shelf: shelf.rows)
        } catch {
            lastSeekFault = .transport
            return loupe.fallbackRows(shelf: shelf.rows)
        }
    }

    func setOnboardingComplete(_ flag: Bool) async {
        var next = loupe
        next.setOnboardingComplete(flag)
        loupe = next
        schedulePersist()
    }

    func flush() async {
        persistTask?.cancel()
        persistTask = nil
        await persistNow()
    }

    func resetAllData() async {
        persistTask?.cancel()
        persistTask = nil
        seekTask?.cancel()
        seekTask = nil
        loupe = .empty
        warning = nil
        lastWriteError = nil
        lastSeekFault = nil
        do {
            try await vault.wipe()
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async {
        #if targetEnvironment(simulator)
        if await vault.demoPlanted() { return }
        loupe = LoupeSeed.loupe(now: now, calendar: calendar, shelf: shelf.rows)
        await vault.markDemoPlanted()
        await persistNow()
        #else
        _ = now
        _ = calendar
        #endif
    }

    private func persistNow() async {
        do {
            try await vault.save(loupe)
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let delay = writeDelayNanoseconds
        persistTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.persistNow()
        }
    }
}
