import SwiftUI

/// Role: Loupe. Named colours from Assets.xcassets. Hex lives only here: #FAF7F5 #FEFEFD #392818 #CC6D19 #816C5A.
enum LoupeInk {
    enum Hex {
        static let background = "#FAF7F5"
        static let surface = "#FEFEFD"
        static let ink = "#392818"
        static let accent = "#CC6D19"
        static let muted = "#816C5A"
    }

    static var background: Color { Color("background") }
    static var surface: Color { Color("surface") }
    static var ink: Color { Color("ink") }
    static var accent: Color { Color("accent") }
    static var muted: Color { Color("muted") }
}

/// Role: Loupe. SF Pro via Font.system as the hospitable short-display face. Six steps behind this accessor. Never Font.custom, never above 34pt, never below 12pt.
enum LoupeFace {
    static let face = "SF Pro"

    enum Step: CaseIterable {
        case display
        case title
        case headline
        case body
        case caption
        case micro
    }

    static func font(_ step: Step, size: DynamicTypeSize = .large) -> Font {
        switch step {
        case .display:
            if size >= .accessibility3 {
                return .system(.title2, design: .default).weight(.semibold).leading(.tight)
            }
            return .system(.title, design: .default).weight(.semibold).leading(.tight)
        case .title:
            return .system(.title3, design: .default).weight(.semibold).leading(.tight)
        case .headline:
            return .system(.headline, design: .default).weight(.semibold)
        case .body:
            return .system(.body, design: .default)
        case .caption:
            return .system(.footnote, design: .default).weight(.medium)
        case .micro:
            return .system(.caption, design: .default)
        }
    }

    static func patch(size: DynamicTypeSize) -> Font {
        if size >= .accessibility3 {
            return font(.headline, size: size)
        }
        if size >= .accessibility1 {
            return font(.title, size: size)
        }
        return font(.display, size: size)
    }
}
