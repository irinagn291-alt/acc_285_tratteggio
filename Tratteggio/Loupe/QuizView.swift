import SwiftUI

/// Role: Loupe. Locked Quiz. Frame writes a Shard. Token chips hang under the pierced Lemma. Patch and Undo fuse here. Explore, Saved, and Settings arrive as sheets.
struct QuizView: View {
    @Bindable var chrome: LoupeChrome
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if chrome.quizIsEmpty {
                idlePage
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoupeInk.background.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .medium), trigger: chrome.patchPulse)
        .animation(SnapMotion.swap(reduceMotion), value: chrome.loupe.sign)
        .animation(SnapMotion.swap(reduceMotion), value: chrome.loupe.card?.lemma.workID)
        .loupeCover(item: $chrome.cover) { cover in
            switch cover {
            case .explore:
                ExploreView(chrome: chrome)
            case .saved:
                SavedView(chrome: chrome)
            case .settings:
                SettingsView(chrome: chrome)
            case .patchGuide:
                PatchGuide(chrome: chrome)
            }
        }
    }

    private var idlePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            topChrome
            MutePage(
                art: LoupeArt.emptyHome,
                headline: chrome.recoveredNotice ? "The crate could not be read." : LoupeCopy.muteHeadline,
                line: LoupeCopy.muteLine,
                actionTitle: "Explore"
            ) {
                chrome.present(.explore)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var populated: some View {
        Group {
            if typeSize.isAccessibilitySize {
                ScrollView {
                    VStack(alignment: .leading, spacing: LoupePad.gap) {
                        loupeColumn(heroFills: false)
                        TokenCommand(chrome: chrome, band: .frame)
                        pairStrip
                    }
                    .padding(.horizontal, LoupePad.outer)
                    .padding(.top, LoupePad.inner)
                    .padding(.bottom, LoupePad.inner)
                }
                .scrollIndicators(.hidden)
            } else {
                VStack(alignment: .leading, spacing: LoupePad.gap) {
                    loupeColumn(heroFills: true)
                }
                .padding(.horizontal, LoupePad.outer)
                .padding(.top, LoupePad.inner)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .safeAreaInset(edge: .bottom, spacing: LoupePad.gap) {
                    VStack(alignment: .leading, spacing: LoupePad.gap) {
                        TokenCommand(chrome: chrome, band: .frame)
                        pairStrip
                    }
                    .padding(.horizontal, LoupePad.outer)
                    .padding(.top, LoupePad.inner)
                    .padding(.bottom, LoupePad.inner)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LoupeInk.background.ignoresSafeArea(edges: .bottom))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loupeColumn(heroFills: Bool) -> some View {
        VStack(alignment: .leading, spacing: LoupePad.gap) {
            topChrome
                .layoutPriority(1)
            if let fault = chrome.loupeFault {
                faultRule(fault)
                    .layoutPriority(1)
            }
            if chrome.recoveredNotice {
                recoverRule
                    .layoutPriority(1)
            }
            statusStrip
                .layoutPriority(1)
            ShardHero(
                shard: chrome.loupe.card?.shard,
                work: chrome.hangingWork,
                showSuccess: chrome.showSuccess
            )
            .frame(maxWidth: .infinity, minHeight: LoupePad.step(22))
            .frame(maxHeight: heroFills ? .infinity : LoupePad.step(28))
            if let card = chrome.loupe.card {
                LemmaCaption(
                    lemma: card.lemma,
                    filled: chrome.loupe.sign == .restored
                )
                .layoutPriority(1)
                TokenCommand(chrome: chrome, band: .chips)
                    .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: heroFills ? .infinity : nil, alignment: .topLeading)
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: LoupePad.gap) {
            jobStack
            sheetRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, chrome.quizIsEmpty ? LoupePad.outer : 0)
        .padding(.top, chrome.quizIsEmpty ? LoupePad.gap : 0)
    }

    private var jobStack: some View {
        HStack(alignment: .top, spacing: LoupePad.gap) {
            Image(LoupeArt.brassLoupe)
                .resizable()
                .scaledToFit()
                .frame(width: LoupePad.step(5), height: LoupePad.step(5))
                .padding(LoupePad.inner)
                .background(
                    LoupeInk.surface,
                    in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(LoupeCopy.jobName)
                    .font(LoupeFace.font(.headline, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                Text(LoupeCopy.nextTap(sign: chrome.loupe.sign))
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(LoupeFigures.daykey(chrome.dayStamp))
                    .font(LoupeFace.font(.micro, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Button {
                Task { await chrome.undoMark() }
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(LoupeFace.font(.headline, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .frame(width: LoupePad.hit, height: LoupePad.hit)
                    .background(
                        LoupeInk.surface,
                        in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous))
            }
            .buttonStyle(GlyphPressStyle())
            .disabled(!chrome.undoEnabled)
            .accessibilityLabel("Undo")
            .accessibilityHint("Drops the newest patch or miss.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sheetRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: LoupePad.gap) {
                sheetWordButton("Explore", system: "magnifyingglass") {
                    chrome.present(.explore)
                }
                sheetWordButton("Saved", system: "bookmark") {
                    chrome.present(.saved)
                }
                sheetWordButton("Settings", system: "gearshape") {
                    chrome.present(.settings)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: LoupePad.gap) {
                sheetGlyphButton("Explore", system: "magnifyingglass") {
                    chrome.present(.explore)
                }
                sheetGlyphButton("Saved", system: "bookmark") {
                    chrome.present(.saved)
                }
                sheetGlyphButton("Settings", system: "gearshape") {
                    chrome.present(.settings)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusStrip: some View {
        HStack(alignment: .center, spacing: LoupePad.gap) {
            signStamp
            Text(LoupeSignInk.sentence(chrome.loupe.sign))
                .font(LoupeFace.font(.caption, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .lineLimit(2)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(LoupePad.card)
        .frame(maxWidth: .infinity, minHeight: LoupePad.hit, alignment: .leading)
        .loupeFlat()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tallySentence)
    }

    private var signStamp: some View {
        Text(LoupeSignInk.stamp(chrome.loupe.sign))
            .font(LoupeFace.font(.micro, size: typeSize))
            .foregroundStyle(LoupeInk.ink)
            .lineLimit(1)
            .padding(.horizontal, LoupePad.inner)
            .frame(minHeight: LoupePad.hit)
            .background(
                LoupeInk.accent.opacity(0.18),
                in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
            )
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
    }

    private var pairStrip: some View {
        HStack(alignment: .top, spacing: LoupePad.gap) {
            recentRail
                .frame(maxWidth: .infinity, alignment: .leading)
            statCard
                .frame(width: LoupePad.step(13), alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tallySentence)
    }

    private var recentRail: some View {
        VStack(alignment: .leading, spacing: LoupePad.inner) {
            Text("Crate")
                .font(LoupeFace.font(.micro, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .lineLimit(1)
            if chrome.recentCrateTokens.isEmpty {
                Text("Save a painting.")
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .lineLimit(2)
            } else {
                Text(chrome.recentCrateTokens.joined(separator: ", "))
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(LoupePad.card)
        .frame(maxWidth: .infinity, minHeight: LoupePad.step(9), alignment: .leading)
        .loupeFlat()
    }

    private var statCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(chrome.primaryStatIsRestored ? "Restored" : "Misses")
                .font(LoupeFace.font(.micro, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(
                LoupeFigures.whole(
                    chrome.primaryStatIsRestored
                        ? chrome.loupe.patchMarks.count
                        : chrome.loupe.smudgeMarks.count
                )
            )
            .font(LoupeFace.font(.title, size: typeSize))
            .foregroundStyle(LoupeInk.ink)
            .monospacedDigit()
            .loupeTick(reduceMotion)
            .lineLimit(1)
            .layoutPriority(1)
        }
        .padding(LoupePad.card)
        .frame(maxWidth: .infinity, minHeight: LoupePad.step(9), alignment: .leading)
        .loupeFlat(fill: LoupeInk.accent.opacity(0.16))
    }

    private func sheetWordButton(_ label: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: LoupePad.inner) {
                Image(systemName: system)
                    .font(LoupeFace.font(.caption, size: typeSize))
                Text(label)
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(LoupeInk.ink)
            .padding(.horizontal, LoupePad.card)
            .frame(minHeight: LoupePad.hit)
            .background(
                LoupeInk.surface,
                in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous))
        }
        .buttonStyle(GlyphPressStyle())
        .accessibilityLabel(label)
    }

    private func sheetGlyphButton(_ label: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(LoupeFace.font(.headline, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .frame(width: LoupePad.hit, height: LoupePad.hit)
                .background(
                    LoupeInk.surface,
                    in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous))
        }
        .buttonStyle(GlyphPressStyle())
        .accessibilityLabel(label)
    }

    private func faultRule(_ text: String) -> some View {
        Text(text)
            .font(LoupeFace.font(.micro, size: typeSize))
            .foregroundStyle(LoupeInk.ink)
            .padding(LoupePad.inner)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: LoupePad.hit, alignment: .leading)
            .loupeFlat()
    }

    private var recoverRule: some View {
        HStack(spacing: LoupePad.gap) {
            Text("Crate restored from a spare copy.")
                .font(LoupeFace.font(.micro, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Button("Hide") {
                chrome.recoveredNotice = false
            }
            .font(LoupeFace.font(.caption, size: typeSize))
            .foregroundStyle(LoupeInk.ink)
            .loupeHit()
            .buttonStyle(GlyphPressStyle())
        }
        .padding(.horizontal, LoupePad.inner)
        .loupeFlat()
    }

    private var tallySentence: String {
        let restored = LoupeFigures.whole(chrome.loupe.patchMarks.count)
        let smudges = LoupeFigures.whole(chrome.loupe.smudgeMarks.count)
        return "\(restored) Restored. \(smudges) misses. \(LoupeSignInk.sentence(chrome.loupe.sign))"
    }
}
