import Foundation
import Observation
import SwiftUI

/// Role: Loupe. Presentation fold over LoupeStore. Views call frameShard, patchToken, smudgeToken, and undoMark and never keep a second plaque enum.
@MainActor
@Observable
final class LoupeChrome {
    let store: LoupeStore
    private(set) var loupe: Loupe
    var isBooting: Bool
    var showsOnboarding: Bool
    var cover: LoupeCover?
    var recoveredNotice: Bool
    var isFraming: Bool
    var frameBusy: Bool
    var isUndoing: Bool
    var undoBusy: Bool
    var tokenBusy: UUID?
    var isSeeking: Bool
    var query: String
    var seekHits: [CatalogRow]
    var seekFault: String?
    var loupeFault: String?
    var crateNote: String?
    var stockingObjectID: Int?
    var patchPulse: Int
    var showSuccess: Bool
    var dayStamp: Int
    private var cueConsumed: Bool
    private var seekTask: Task<Void, Never>?
    private var successTask: Task<Void, Never>?

    init(store: LoupeStore, isBooting: Bool = true) {
        self.store = store
        self.loupe = store.loupe
        self.isBooting = isBooting
        self.showsOnboarding = false
        self.cover = nil
        self.recoveredNotice = false
        self.isFraming = false
        self.frameBusy = false
        self.isUndoing = false
        self.undoBusy = false
        self.tokenBusy = nil
        self.isSeeking = false
        self.query = ""
        self.seekHits = []
        self.seekFault = nil
        self.loupeFault = nil
        self.crateNote = nil
        self.stockingObjectID = nil
        self.patchPulse = 0
        self.showSuccess = false
        self.dayStamp = Daykey.stamp(Date(), calendar: .current)
        self.cueConsumed = false
    }

    static func live() -> LoupeChrome {
        LoupeChrome(store: LoupeStore())
    }

    func boot() async {
        guard isBooting else { return }
        await store.load()
        await store.seedDemoIfNeeded()
        sync()
        recoveredNotice = store.warning != nil
        showsOnboarding = !loupe.onboardingComplete
        isBooting = false
        if query.isEmpty {
            seekHits = loupe.fallbackRows(shelf: CrateShelf.bundled.rows)
        }
        if !showsOnboarding {
            consumeCue()
        }
    }

    func flush() async {
        await store.flush()
        sync()
    }

    func refreshDay() {
        dayStamp = Daykey.stamp(Date(), calendar: .current)
    }

    func handle(phase: ScenePhase) async {
        switch phase {
        case .inactive, .background:
            await flush()
        case .active:
            refreshDay()
        @unknown default:
            break
        }
    }

    func finishOnboarding() async {
        await store.setOnboardingComplete(true)
        await store.flush()
        sync()
        showsOnboarding = false
        consumeCue()
    }

    func replayOnboarding() {
        cover = nil
        showsOnboarding = true
        Task {
            await store.setOnboardingComplete(false)
            await store.flush()
            sync()
        }
    }

    func present(_ cover: LoupeCover) {
        self.cover = cover
    }

    func handle(_ job: LoupeJob) {
        switch job {
        case .quiz:
            cover = nil
        case .frame:
            cover = nil
            Task { await frameShard() }
        case .explore, .saved, .settings, .patchGuide:
            cover = job.cover
        }
    }

    func handle(url: URL) {
        guard let job = LoupeJob.parse(url) else { return }
        handle(job)
    }

    func apply(_ sheet: LoupeSheet) {
        switch sheet {
        case .quiz:
            cover = nil
        case .explore:
            cover = .explore
        case .saved:
            cover = .saved
        case .settings:
            cover = .settings
        }
    }

    func frameShard() async {
        guard !isFraming else { return }
        isFraming = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { frameBusy = true }
        }
        do {
            try await store.frameShard()
            showSuccess = false
            sync()
            if store.lastWriteError == nil {
                loupeFault = nil
            }
        } catch {
            loupeFault = LoupeCopy.fault(error)
            sync()
        }
        pulse.cancel()
        frameBusy = false
        isFraming = false
        sync()
    }

    func tapToken(_ token: Token) async {
        guard tokenBusy == nil else { return }
        guard loupe.canPatch else {
            loupeFault = LoupeCopy.fault(LoupeFault.patchOnShut)
            return
        }
        if token.isSmudged {
            loupeFault = LoupeCopy.fault(LoupeFault.tokenSmudged)
            return
        }
        tokenBusy = token.id
        defer { tokenBusy = nil }
        do {
            if token.isMatch {
                try await store.patchToken(tokenID: token.id)
                patchPulse += 1
                flashSuccess()
                sync()
            } else {
                try await store.smudgeToken(tokenID: token.id)
                sync()
            }
            if store.lastWriteError == nil {
                loupeFault = nil
            }
        } catch {
            loupeFault = LoupeCopy.fault(error)
            sync()
        }
    }

    func undoMark() async {
        guard !isUndoing else { return }
        isUndoing = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { undoBusy = true }
        }
        do {
            try await store.undoMark()
            showSuccess = false
            sync()
            if store.lastWriteError == nil {
                loupeFault = nil
            }
        } catch {
            loupeFault = LoupeCopy.fault(error)
            sync()
        }
        pulse.cancel()
        undoBusy = false
        isUndoing = false
        sync()
    }

    func crateShut(_ row: CatalogRow) async {
        guard stockingObjectID == nil else { return }
        stockingObjectID = row.objectID
        do {
            let focus = try await store.crateShut(row)
            sync()
            switch focus {
            case .inserted:
                crateNote = "Saved."
            case .focused:
                crateNote = "Already in the crate."
            }
            loupeFault = nil
        } catch {
            crateNote = LoupeCopy.fault(error)
        }
        stockingObjectID = nil
        if store.lastWriteError != nil {
            loupeFault = "Write failed. Frame or Patch again."
        }
    }

    func scheduleSeek() {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        seekTask = Task { await seek(trimmed) }
    }

    func resetAllData() async {
        seekTask?.cancel()
        successTask?.cancel()
        await store.resetAllData()
        sync()
        cover = nil
        query = ""
        seekHits = loupe.fallbackRows(shelf: CrateShelf.bundled.rows)
        seekFault = nil
        loupeFault = nil
        crateNote = nil
        recoveredNotice = false
        showSuccess = false
        showsOnboarding = true
        cueConsumed = true
    }

    func work(for id: UUID?) -> Work? {
        guard let id else { return nil }
        return loupe.works.first { $0.id == id }
    }

    func work(for smudge: SmudgeMark) -> Work? {
        work(for: smudge.workID)
    }

    var hangingWork: Work? {
        if let id = loupe.card?.lemma.workID {
            return loupe.works.first { $0.id == id }
        }
        return loupe.framedWork
    }

    var frameEnabled: Bool {
        loupe.canFrame && !isFraming
    }

    var undoEnabled: Bool {
        !loupe.markLog.isEmpty && !isUndoing
    }

    var quizIsEmpty: Bool {
        loupe.sign == .mute
    }

    var savedIsEmpty: Bool {
        loupe.restoredWorks.isEmpty && loupe.reviewableSmudges.isEmpty
    }

    var exploreIsEmpty: Bool {
        seekHits.isEmpty && !isSeeking
    }

    var settingsIsEmpty: Bool {
        loupe.works.isEmpty && loupe.patchMarks.isEmpty && loupe.smudgeMarks.isEmpty
    }

    var recentCrateTokens: [String] {
        var seen = Set<String>()
        var tokens: [String] = []
        for work in loupe.works.reversed() {
            for word in LemmaPunch.words(in: work.title).prefix(1) {
                let key = word.lowercased()
                guard seen.insert(key).inserted else { continue }
                tokens.append(word)
                if tokens.count == 6 { return tokens }
            }
        }
        return tokens
    }

    var primaryStatIsRestored: Bool {
        !loupe.patchMarks.isEmpty
    }

    private func seek(_ trimmed: String) async {
        if trimmed.isEmpty {
            isSeeking = false
            seekFault = nil
            seekHits = loupe.fallbackRows(shelf: CrateShelf.bundled.rows)
            return
        }
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { isSeeking = true }
        }
        defer {
            pulse.cancel()
            isSeeking = false
        }
        do {
            let hits = try await store.seek(trimmed)
            if Task.isCancelled { return }
            sync()
            seekHits = hits
            if let fault = store.lastSeekFault {
                seekFault = LoupeCopy.seek(fault)
            } else {
                seekFault = nil
            }
        } catch is CancellationError {
            return
        } catch let fault as CatalogFault where fault == .cancelled {
            return
        } catch let fault as CatalogFault {
            if Task.isCancelled { return }
            sync()
            seekHits = loupe.fallbackRows(shelf: CrateShelf.bundled.rows)
            seekFault = LoupeCopy.seek(fault)
        } catch {
            if Task.isCancelled { return }
            sync()
            seekHits = loupe.fallbackRows(shelf: CrateShelf.bundled.rows)
            seekFault = LoupeCopy.seek(.transport)
        }
    }

    private func flashSuccess() {
        successTask?.cancel()
        showSuccess = true
        successTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            if !Task.isCancelled {
                showSuccess = false
            }
        }
    }

    private func sync() {
        loupe = store.loupe
        if let write = store.lastWriteError, !write.isEmpty {
            loupeFault = "Write failed. Frame or Patch again."
        }
    }

    private func consumeCue() {
        if let hook = LoupeLinks.consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboardingComplete: loupe.onboardingComplete,
            consumed: &cueConsumed
        ) {
            apply(hook.sheet)
        }
    }
}
