import SwiftUI

/// Role: Loupe. Full-page empty or error. Cutout, one headline, one line, bottom full-width CTA. Never a crumb in a Spacer.
struct MutePage: View {
    let art: String
    let headline: String
    let line: String
    let actionTitle: String
    var isLoading: Bool = false
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: LoupePad.step(2)) {
            ViewThatFits(in: .vertical) {
                copyStack(showsSpacer: true)
                ScrollView {
                    copyStack(showsSpacer: false)
                }
                .scrollIndicators(.hidden)
            }
            Button(actionTitle, action: action)
                .buttonStyle(FrameCapsuleStyle(tone: .frame, isLoading: isLoading))
                .loupeHit()
        }
        .padding(.horizontal, LoupePad.outer)
        .padding(.top, LoupePad.card)
        .padding(.bottom, LoupePad.outer)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(LoupeInk.background)
    }

    private func copyStack(showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: LoupePad.step(2)) {
            Image(art)
                .loupeCutout(maxWidth: .infinity, maxHeight: LoupePad.step(22))
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
    }
}
