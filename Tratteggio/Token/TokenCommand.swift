import SwiftUI

/// Role: Token. Hanging chips under the Lemma hole, plus extras from the crate. Words wrap so every chip stays whole. Patch is a tap. A miss keeps the hole.
struct TokenCommand: View {
    enum Band {
        case chips
        case frame
        case both
    }

    @Bindable var chrome: LoupeChrome
    var band: Band = .both
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: LoupePad.gap) {
            if showsChips, let card = chrome.loupe.card {
                chipBank(card)
            }
            if showsFrame {
                frameButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var showsChips: Bool {
        band != .frame
    }

    private var showsFrame: Bool {
        band != .chips
    }

    private func chipBank(_ card: FramedCard) -> some View {
        VStack(alignment: .leading, spacing: LoupePad.inner) {
            Text("Tap a word.")
                .font(LoupeFace.font(.caption, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .lineLimit(1)
            WrapRail(spacing: LoupePad.gap) {
                ForEach(card.tokens) { token in
                    chip(token)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Word chips")
    }

    private var frameButton: some View {
        Button {
            Task { await chrome.frameShard() }
        } label: {
            HStack(spacing: LoupePad.inner) {
                Image(LoupeArt.controlFace)
                    .resizable()
                    .scaledToFit()
                    .padding(LoupePad.inner)
                    .frame(width: LoupePad.step(5), height: LoupePad.step(5))
                    .background(
                        LoupeInk.surface,
                        in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                    )
                    .accessibilityHidden(true)
                Text("Frame")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(FrameCapsuleStyle(tone: .frame, isLoading: chrome.frameBusy))
        .disabled(!chrome.frameEnabled)
        .focusable()
        .accessibilityLabel("Frame")
        .accessibilityHint(chrome.frameEnabled ? "Crops a saved work that is not restored." : "Needs a shut work.")
    }

    private func chip(_ token: Token) -> some View {
        Button {
            Task { await chrome.tapToken(token) }
        } label: {
            HStack(spacing: LoupePad.inner) {
                Text(token.spoken)
                    .font(LoupeFace.font(.body, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .strikethrough(token.isSmudged, color: LoupeInk.ink)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                if token.isSmudged {
                    Text("SMUDGE")
                        .font(LoupeFace.font(.micro, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                        .lineLimit(1)
                        .padding(.horizontal, LoupePad.inner)
                        .frame(minHeight: LoupePad.step(3))
                        .overlay(
                            RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                                .stroke(LoupeInk.ink.opacity(0.45), lineWidth: 1)
                        )
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, LoupePad.card)
            .frame(minHeight: LoupePad.hit)
            .contentShape(RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous))
        }
        .buttonStyle(
            TokenPillStyle(
                isSmudged: token.isSmudged,
                isBusy: chrome.tokenBusy == token.id
            )
        )
        .fixedSize(horizontal: true, vertical: false)
        .disabled(token.isSmudged || chrome.tokenBusy != nil || !chrome.loupe.canPatch)
        .focusable()
        .accessibilityLabel(token.isSmudged ? "\(token.spoken), smudged." : token.spoken)
        .accessibilityHint(
            token.isSmudged
                ? "Already missed."
                : "Patches the shard if this word fills the hole."
        )
    }
}
