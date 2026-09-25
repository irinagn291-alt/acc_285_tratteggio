import Foundation

/// Role: Loupe. Generated cutouts from section 13. Empty imagesets until assets.generate.
enum LoupeArt {
    static let splash = "ttg_Splash"
    static let onboarding1 = "ttg_Onboarding1"
    static let onboarding2 = "ttg_Onboarding2"
    static let onboarding3 = "ttg_Onboarding3"
    static let emptyHome = "ttg_EmptyHome"
    static let emptyList = "ttg_EmptyList"
    static let cardBackdrop = "ttg_CardBackdrop"
    static let controlFace = "ttg_ControlFace"
    static let twistHero = "ttg_TwistHero"
    static let successMark = "ttg_SuccessMark"
    static let headerDecor = "ttg_HeaderDecor"
    static let brassLoupe = "ttg_BrassLoupe"
    static let linenShard = "ttg_LinenShard"
    static let woodCrate = "ttg_WoodCrate"
}

/// Role: Loupe. Status chrome. SHUT, FRAMED, RESTORED, MUTE, SMUDGE. Never an axis string.
enum LoupeSignInk {
    static func stamp(_ sign: LoupeSign) -> String {
        switch sign {
        case .mute: "MUTE"
        case .shut: "SHUT"
        case .framed: "FRAMED"
        case .restored: "RESTORED"
        case .smudge: "SMUDGE"
        }
    }

    static func kind(_ kind: LemmaKind) -> String {
        switch kind {
        case .maker: "MAKER"
        case .title: "TITLE"
        }
    }

    static func sentence(_ sign: LoupeSign) -> String {
        switch sign {
        case .mute: "The crate is empty."
        case .shut: "A work is shut."
        case .framed: "A shard is framed."
        case .restored: "A work is restored."
        case .smudge: "A chip is smudged."
        }
    }
}

/// Role: Loupe. Dry copy. Periods, not dashes. Home names the job and the next tap.
enum LoupeCopy {
    static let muteHeadline = "Crate empty."
    static let muteLine = "Save a work, then patch."
    static let jobName = "Patch the shard."

    static func fault(_ error: Error) -> String {
        guard let fault = error as? LoupeFault else {
            return "Write failed. Frame or Patch again."
        }
        switch fault {
        case .patchOnShut, .smudgeOnShut:
            return "Frame a crop first."
        case .patchOnRestored, .smudgeOnRestored:
            return "This work is already restored."
        case .tokenUnknown:
            return "That chip is not hanging."
        case .tokenMismatch:
            return "Wrong word. The hole stays."
        case .tokenSmudged:
            return "Already smudged."
        case .smudgeOnMatch:
            return "Patch the match. Do not smudge it."
        case .nothingToUndo:
            return "Nothing to undo."
        case .emptyObject:
            return "No object id."
        case .incompleteWork:
            return "Needs a maker and a title."
        }
    }

    static func seek(_ fault: CatalogFault) -> String {
        switch fault {
        case .cancelled:
            return "Search cancelled."
        case .missing:
            return "Search missed. The crate shelf is waiting."
        case .transport:
            return "Search failed. The crate shelf is waiting."
        case .malformed:
            return "Search could not be read. The crate shelf is waiting."
        }
    }

    static func nextTap(sign: LoupeSign) -> String {
        switch sign {
        case .mute:
            return muteLine
        case .shut:
            return "Frame a crop."
        case .framed, .smudge:
            return "Tap the missing word."
        case .restored:
            return "Frame another crop."
        }
    }

    static func prompt(_ kind: LemmaKind) -> String {
        switch kind {
        case .maker:
            return "Maker"
        case .title:
            return "Title"
        }
    }
}

/// Role: Loupe. Restored counts, SmudgeMark counts, and daykeys go through NumberFormatter. Never interpolate.
enum LoupeFigures {
    static func whole(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func daykey(_ value: Int) -> String {
        let year = value / 10_000
        let month = (value / 100) % 100
        let day = value % 100
        return "\(plain(year)).\(plain(month)).\(plain(day))"
    }

    private static func plain(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = value >= 10 || value == 0 ? 1 : 1
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
