import SwiftUI

/// Role: Loupe. Primary Frame is a full-width filled capsule. Default, pressed, disabled, loading. Undo is not the wipe tone.
struct FrameCapsuleStyle: ButtonStyle {
    enum Tone {
        case frame
        case undo
        case wipe
    }

    var tone: Tone = .frame
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        FrameCapsuleBody(configuration: configuration, tone: tone, isLoading: isLoading)
    }
}

private struct FrameCapsuleBody: View {
    let configuration: ButtonStyle.Configuration
    let tone: FrameCapsuleStyle.Tone
    let isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        HStack(spacing: LoupePad.inner) {
            if isLoading {
                ProgressView()
                    .tint(labelInk)
            }
            configuration.label
        }
        .font(tone == .frame ? LoupeFace.patch(size: typeSize) : LoupeFace.font(.headline, size: typeSize))
        .foregroundStyle(labelInk)
        .frame(maxWidth: .infinity)
        .frame(minHeight: LoupePad.hit)
        .padding(.horizontal, LoupePad.card)
        .background(capsuleFill)
        .overlay(
            Capsule(style: .continuous)
                .stroke(LoupeInk.ink, lineWidth: isFocused ? 2 : 0)
        )
        .contentShape(Capsule(style: .continuous))
        .scaleEffect(pressed && isEnabled && !reduceMotion ? 0.97 : 1)
        .opacity(visualOpacity(pressed: pressed))
        .animation(SnapMotion.swap(reduceMotion), value: pressed)
        .animation(SnapMotion.swap(reduceMotion), value: isEnabled)
        .animation(SnapMotion.swap(reduceMotion), value: isLoading)
        .animation(SnapMotion.swap(reduceMotion), value: isFocused)
    }

    @ViewBuilder
    private var capsuleFill: some View {
        let shape = Capsule(style: .continuous)
        switch tone {
        case .frame:
            shape.fill(LoupeInk.accent.opacity(isEnabled ? 1 : 0.35))
        case .undo:
            shape.fill(LoupeInk.surface)
            .overlay(shape.stroke(LoupeInk.muted.opacity(0.45), lineWidth: 1))
        case .wipe:
            shape.fill(LoupeInk.ink)
        }
    }

    private var labelInk: Color {
        switch tone {
        case .frame:
            return LoupeInk.surface
        case .undo:
            return LoupeInk.ink
        case .wipe:
            return LoupeInk.surface
        }
    }

    private func visualOpacity(pressed: Bool) -> Double {
        if !isEnabled { return 0.48 }
        if isLoading { return 0.7 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: Token. Native chip at radius_small. A miss strikes and stamps SMUDGE. Colour is never the only signal.
struct TokenPillStyle: ButtonStyle {
    var isSmudged: Bool
    var isBusy: Bool

    func makeBody(configuration: Configuration) -> some View {
        TokenPillBody(configuration: configuration, isSmudged: isSmudged, isBusy: isBusy)
    }
}

private struct TokenPillBody: View {
    let configuration: ButtonStyle.Configuration
    let isSmudged: Bool
    let isBusy: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .overlay(alignment: .trailing) {
                if isBusy {
                    ProgressView()
                        .tint(LoupeInk.ink)
                        .padding(.trailing, LoupePad.inner)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                    .fill(isSmudged ? LoupeInk.surface : LoupeInk.accent.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                    .stroke(stroke, lineWidth: strokeWidth)
            )
            .contentShape(RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous))
            .scaleEffect(pressed && isEnabled && !reduceMotion ? 0.97 : 1)
            .opacity(tileOpacity(pressed: pressed))
            .animation(SnapMotion.swap(reduceMotion), value: pressed)
            .animation(SnapMotion.swap(reduceMotion), value: isSmudged)
            .animation(SnapMotion.swap(reduceMotion), value: isFocused)
            .animation(SnapMotion.swap(reduceMotion), value: isEnabled)
    }

    private var stroke: Color {
        if isFocused { return LoupeInk.ink }
        if isSmudged { return LoupeInk.ink.opacity(0.55) }
        return LoupeInk.ink.opacity(0.12)
    }

    private var strokeWidth: CGFloat {
        if isFocused { return 2 }
        return 1
    }

    private func tileOpacity(pressed: Bool) -> Double {
        if isSmudged { return 0.55 }
        if !isEnabled { return 0.5 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: Loupe. Pressed and disabled chrome for icon-only sheet controls. Never .plain.
struct GlyphPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        GlyphPressBody(configuration: configuration)
    }
}

private struct GlyphPressBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                    .stroke(LoupeInk.ink, lineWidth: isFocused ? 2 : 0)
            )
            .scaleEffect(pressed && isEnabled && !reduceMotion ? 0.97 : 1)
            .opacity(glyphOpacity(pressed: pressed))
            .animation(SnapMotion.swap(reduceMotion), value: pressed)
            .animation(SnapMotion.swap(reduceMotion), value: isEnabled)
            .animation(SnapMotion.swap(reduceMotion), value: isFocused)
    }

    private func glyphOpacity(pressed: Bool) -> Double {
        if !isEnabled { return 0.42 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: Work. Pressed row for Explore save and Form rows.
struct CrateRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CrateRowBody(configuration: configuration)
    }
}

private struct CrateRowBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .scaleEffect(pressed && isEnabled && !reduceMotion ? 0.97 : 1)
            .opacity(!isEnabled ? 0.55 : (pressed ? 0.88 : 1))
            .animation(SnapMotion.swap(reduceMotion), value: pressed)
            .animation(SnapMotion.swap(reduceMotion), value: isEnabled)
    }
}
