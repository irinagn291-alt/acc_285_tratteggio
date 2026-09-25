import Foundation

/// Role: Loupe. Jobs for App Intents and tratteggio:// plus https://tratteggio-loupe.pro paths. Quiz stays put. No Game tab.
enum LoupeJob: String, Equatable, Sendable {
    case quiz
    case explore
    case saved
    case settings
    case frame
    case patchGuide = "patch"

    static let httpsHost = "tratteggio-loupe.pro"

    static func parse(_ url: URL) -> LoupeJob? {
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "tratteggio" {
            let host = url.host?.lowercased() ?? ""
            let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let token = host.isEmpty ? path : host
            return LoupeJob(rawValue: token)
        }
        if scheme == "https", url.host?.lowercased() == httpsHost {
            let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if path.isEmpty { return .quiz }
            if path == "contact-us" { return .settings }
            return LoupeJob(rawValue: path)
        }
        return nil
    }

    static func parse(notification: Notification) -> LoupeJob? {
        guard let raw = notification.userInfo?[LoupePost.key] as? String else { return nil }
        return LoupeJob(rawValue: raw)
    }

    var cover: LoupeCover? {
        switch self {
        case .quiz, .frame:
            return nil
        case .explore:
            return .explore
        case .saved:
            return .saved
        case .settings:
            return .settings
        case .patchGuide:
            return .patchGuide
        }
    }
}

/// Role: Loupe. Sheets over the locked Quiz loupe. Four destinations plus the frame-then-patch guide.
enum LoupeCover: String, Identifiable, Equatable, Sendable {
    case explore
    case saved
    case settings
    case patchGuide

    var id: String { rawValue }
}

extension Notification.Name {
    static let loupeJob = Notification.Name("ttg.loupe.job")
}

enum LoupePost {
    static let key = "job"

    static func broadcast(_ job: LoupeJob) {
        NotificationCenter.default.post(
            name: .loupeJob,
            object: nil,
            userInfo: [key: job.rawValue]
        )
    }
}
