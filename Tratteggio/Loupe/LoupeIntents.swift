import AppIntents
import Foundation

/// Role: Loupe. App Intents open Quiz, Explore, Saved, or Settings, or fire frameShard in place.
struct OpenQuizIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Quiz" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LoupePost.broadcast(.quiz)
        return .result()
    }
}

struct OpenExploreIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Explore" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LoupePost.broadcast(.explore)
        return .result()
    }
}

struct OpenSavedIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Saved" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LoupePost.broadcast(.saved)
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Settings" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LoupePost.broadcast(.settings)
        return .result()
    }
}

struct FrameShardIntent: AppIntent {
    static var title: LocalizedStringResource { "Frame a shard" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LoupePost.broadcast(.frame)
        return .result()
    }
}

struct OpenPatchGuideIntent: AppIntent {
    static var title: LocalizedStringResource { "Open frame then patch" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LoupePost.broadcast(.patchGuide)
        return .result()
    }
}

struct TratteggioShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenQuizIntent(),
            phrases: [
                "Open Quiz in \(.applicationName)",
                "Patch the shard in \(.applicationName)",
            ],
            shortTitle: "Quiz",
            systemImageName: "viewfinder"
        )
        AppShortcut(
            intent: OpenExploreIntent(),
            phrases: [
                "Open Explore in \(.applicationName)",
            ],
            shortTitle: "Explore",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: OpenSavedIntent(),
            phrases: [
                "Open Saved in \(.applicationName)",
            ],
            shortTitle: "Saved",
            systemImageName: "bookmark"
        )
        AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open Settings in \(.applicationName)",
            ],
            shortTitle: "Settings",
            systemImageName: "gearshape"
        )
        AppShortcut(
            intent: FrameShardIntent(),
            phrases: [
                "Frame a shard in \(.applicationName)",
            ],
            shortTitle: "Frame",
            systemImageName: "crop"
        )
        AppShortcut(
            intent: OpenPatchGuideIntent(),
            phrases: [
                "Open frame then patch in \(.applicationName)",
            ],
            shortTitle: "Patch",
            systemImageName: "rectangle.badge.plus"
        )
    }
}
