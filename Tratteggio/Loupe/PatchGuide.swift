import SwiftUI

/// Role: Loupe. Twist screen. Frame-then-patch is the fold. Home already shows the shard and chips. This sheet names the job.
struct PatchGuide: View {
    @Bindable var chrome: LoupeChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            LoupeSheetFrame {
                VStack(alignment: .leading, spacing: LoupePad.step(2)) {
                    Image(LoupeArt.twistHero)
                        .loupeCutout(maxWidth: .infinity, maxHeight: LoupePad.step(20))
                    Text("Frame, then patch.")
                        .font(LoupeFace.font(.display, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                        .lineLimit(2)
                    Text("Frame samples a saved painting that is not restored. One chip is punched from maker or title. Chips hang under the crop. A match files Restored. A miss keeps the hole.")
                        .font(LoupeFace.font(.body, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                        .loupeLeading()
                        .lineLimit(6)
                    HStack(alignment: .firstTextBaseline, spacing: LoupePad.step(2)) {
                        VStack(alignment: .leading, spacing: LoupePad.inner) {
                            Text("Restored")
                                .font(LoupeFace.font(.micro, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                            Text(LoupeFigures.whole(chrome.loupe.patchMarks.count))
                                .font(LoupeFace.font(.title, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                                .monospacedDigit()
                                .loupeTick(reduceMotion)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: LoupePad.inner) {
                            Text("Misses")
                                .font(LoupeFace.font(.micro, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                            Text(LoupeFigures.whole(chrome.loupe.smudgeMarks.count))
                                .font(LoupeFace.font(.headline, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                                .monospacedDigit()
                                .loupeTick(reduceMotion)
                        }
                        .frame(width: LoupePad.step(12), alignment: .leading)
                    }
                    .padding(LoupePad.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .loupeFlat()
                    VStack(alignment: .leading, spacing: LoupePad.gap) {
                        Text(LoupeSignInk.stamp(chrome.loupe.sign))
                            .font(LoupeFace.font(.caption, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                            .padding(.horizontal, LoupePad.inner)
                            .frame(minHeight: LoupePad.hit)
                            .background(
                                LoupeInk.surface,
                                in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                            )
                        Text(LoupeCopy.nextTap(sign: chrome.loupe.sign))
                            .font(LoupeFace.font(.body, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                            .loupeLeading()
                            .lineLimit(3)
                    }
                    .padding(LoupePad.card)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .loupeFlat()
                    Button(ctaTitle) {
                        switch chrome.loupe.sign {
                        case .framed, .smudge, .restored:
                            dismiss()
                        case .shut:
                            dismiss()
                            Task { await chrome.frameShard() }
                        case .mute:
                            chrome.present(.explore)
                        }
                    }
                    .buttonStyle(FrameCapsuleStyle(tone: .frame, isLoading: chrome.frameBusy))
                    .disabled(chrome.loupe.sign == .shut && !chrome.frameEnabled)
                    .loupeHit()
                }
                .padding(LoupePad.outer)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(LoupeInk.background)
            }
            .navigationTitle("Frame then patch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(LoupeFace.font(.headline, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                            .loupeHit()
                    }
                    .buttonStyle(GlyphPressStyle())
                    .accessibilityLabel("Close")
                }
            }
        }
        .loupeSheetChrome()
    }

    private var ctaTitle: String {
        switch chrome.loupe.sign {
        case .framed, .smudge, .restored:
            return "Patch"
        case .shut:
            return "Frame"
        case .mute:
            return "Explore"
        }
    }
}
