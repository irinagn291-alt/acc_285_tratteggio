import SwiftUI

/// Role: Loupe. One-shot cover. Three pages. Continue full width at the bottom. Skip writes defaults. Re-runnable from Settings.
struct OnboardingCover: View {
    var onSkip: () -> Void
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                if page < 2 {
                    Button("Skip", action: onSkip)
                        .font(LoupeFace.font(.caption, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                        .loupeHit()
                        .buttonStyle(GlyphPressStyle())
                        .accessibilityLabel("Skip onboarding")
                }
            }
            .padding(.horizontal, LoupePad.outer)

            ViewThatFits(in: .vertical) {
                pageSwitch(showsSpacer: true)
                ScrollView {
                    pageSwitch(showsSpacer: false)
                }
                .scrollIndicators(.hidden)
            }
            .id(page)
            .animation(SnapMotion.swap(reduceMotion), value: page)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            HStack(spacing: LoupePad.gap) {
                ForEach(0 ..< 3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                        .fill(index == page ? LoupeInk.accent : LoupeInk.surface)
                        .frame(
                            width: index == page ? LoupePad.step(3) : LoupePad.inner,
                            height: LoupePad.inner
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, LoupePad.outer)
            .padding(.bottom, LoupePad.inner)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Page \(LoupeFigures.whole(page + 1)) of \(LoupeFigures.whole(3))"
            )

            Button("Continue") {
                if page < 2 {
                    page += 1
                } else {
                    onFinish()
                }
            }
            .buttonStyle(FrameCapsuleStyle(tone: .frame, isLoading: false))
            .padding(.horizontal, LoupePad.outer)
            .padding(.bottom, LoupePad.outer)
        }
        .background(LoupeInk.background.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func pageSwitch(showsSpacer: Bool) -> some View {
        switch page {
        case 0:
            pageBody(
                art: LoupeArt.onboarding1,
                headline: "Know it from a crop.",
                line: "Finish the label from works you already saved, on this device.",
                showsSpacer: showsSpacer
            )
        case 1:
            pageBody(
                art: LoupeArt.onboarding2,
                headline: "Frame, then patch.",
                line: "Frame crops a saved work. One word is missing. Tap the chip that fills it.",
                showsSpacer: showsSpacer
            )
        default:
            pageBody(
                art: LoupeArt.onboarding3,
                headline: "Restored stays here.",
                line: "A miss stays reviewable. Saved keeps Restored pieces and misses.",
                showsSpacer: showsSpacer
            )
        }
    }

    private func pageBody(art: String, headline: String, line: String, showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: LoupePad.step(2)) {
            Image(art)
                .loupeCutout(maxWidth: .infinity, maxHeight: LoupePad.step(36))
            Text(headline)
                .font(LoupeFace.font(.display, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .lineLimit(3)
            Text(line)
                .font(LoupeFace.font(.body, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .loupeLeading()
                .lineLimit(4)
            if showsSpacer {
                Spacer(minLength: LoupePad.gap)
            }
        }
        .padding(.horizontal, LoupePad.outer)
        .padding(.top, LoupePad.card)
    }
}
