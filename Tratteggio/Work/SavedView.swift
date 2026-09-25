import SwiftUI

/// Role: Work. Saved sheet of Restored pieces and SmudgeMarks. Collecting without a test is the crate clone. Misses stay reviewable.
struct SavedView: View {
    @Bindable var chrome: LoupeChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        NavigationStack {
            LoupeSheetFrame {
                Group {
                    if chrome.savedIsEmpty {
                        emptyPage
                    } else if let fault = chrome.loupeFault, chrome.loupe.restoredWorks.isEmpty, chrome.loupe.reviewableSmudges.isEmpty {
                        MutePage(
                            art: LoupeArt.emptyList,
                            headline: "Saved could not load.",
                            line: fault,
                            actionTitle: "Close"
                        ) {
                            dismiss()
                        }
                    } else {
                        populated
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LoupeInk.background)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoupeInk.background.ignoresSafeArea())
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(LoupeInk.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoupeInk.background.ignoresSafeArea())
        .loupeSheetChrome()
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            if sizeClass == .regular {
                Text("Close")
                    .font(LoupeFace.font(.headline, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .padding(.horizontal, LoupePad.card)
                    .frame(minHeight: LoupePad.hit)
                    .contentShape(Rectangle())
            } else {
                Image(systemName: "xmark")
                    .font(LoupeFace.font(.headline, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .loupeHit()
            }
        }
        .buttonStyle(GlyphPressStyle())
        .accessibilityLabel("Close")
    }

    private var emptyPage: some View {
        MutePage(
            art: LoupeArt.emptyList,
            headline: "Nothing restored.",
            line: "Patch a framed crop.",
            actionTitle: "Patch"
        ) {
            dismiss()
        }
    }

    private var populated: some View {
        List {
            Section {
                tally
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(LoupeInk.background)
                    .listRowSeparator(.hidden)
            }
            if let fault = chrome.loupeFault {
                Section {
                    Text(fault)
                        .font(LoupeFace.font(.micro, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                        .loupeLeading()
                        .listRowBackground(LoupeInk.surface)
                    Button("Return to the crop") {
                        dismiss()
                    }
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .frame(maxWidth: .infinity, minHeight: LoupePad.hit, alignment: .leading)
                    .contentShape(Rectangle())
                    .buttonStyle(CrateRowStyle())
                    .listRowBackground(LoupeInk.surface)
                    .accessibilityHint("Closes Saved and returns to Quiz.")
                }
            }
            if !chrome.loupe.restoredWorks.isEmpty {
                Section {
                    ForEach(chrome.loupe.restoredWorks) { work in
                        restoredRow(work)
                    }
                } header: {
                    Text("Restored")
                        .font(LoupeFace.font(.caption, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                }
            }
            if !chrome.loupe.reviewableSmudges.isEmpty {
                Section {
                    ForEach(chrome.loupe.reviewableSmudges) { smudge in
                        smudgeRow(smudge)
                    }
                } header: {
                    Text("Misses")
                        .font(LoupeFace.font(.caption, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, LoupePad.outer)
    }

    private var tally: some View {
        HStack(alignment: .top, spacing: LoupePad.gap) {
            VStack(alignment: .leading, spacing: LoupePad.inner) {
                Text("Restored")
                    .font(LoupeFace.font(.micro, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                Text(LoupeFigures.whole(chrome.loupe.patchMarks.count))
                    .font(LoupeFace.font(.display, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .monospacedDigit()
                    .loupeTick(reduceMotion)
            }
            .padding(LoupePad.card)
            .frame(maxWidth: .infinity, minHeight: LoupePad.step(11), alignment: .leading)
            .loupeFlat(fill: LoupeInk.accent.opacity(0.16))
            VStack(alignment: .leading, spacing: LoupePad.inner) {
                Text("Misses")
                    .font(LoupeFace.font(.micro, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                Text(LoupeFigures.whole(chrome.loupe.smudgeMarks.count))
                    .font(LoupeFace.font(.title, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .monospacedDigit()
                    .loupeTick(reduceMotion)
            }
            .padding(LoupePad.card)
            .frame(width: LoupePad.step(14), alignment: .leading)
            .frame(minHeight: LoupePad.step(11))
            .loupeFlat()
        }
        .padding(.horizontal, LoupePad.outer)
        .padding(.vertical, LoupePad.gap)
        .animation(SnapMotion.swap(reduceMotion), value: chrome.loupe.patchMarks.count)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(LoupeFigures.whole(chrome.loupe.patchMarks.count)) Restored. \(LoupeFigures.whole(chrome.loupe.smudgeMarks.count)) misses."
        )
    }

    private func restoredRow(_ work: Work) -> some View {
        VStack(alignment: .leading, spacing: LoupePad.inner) {
            Text(work.title)
                .font(LoupeFace.font(.body, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .lineLimit(2)
            HStack {
                Text(work.maker)
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .lineLimit(1)
                Spacer(minLength: LoupePad.gap)
                Text(LoupeFigures.daykey(work.daykey))
                    .font(LoupeFace.font(.micro, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .padding(.vertical, LoupePad.inner)
        .frame(maxWidth: .infinity, minHeight: LoupePad.hit, alignment: .leading)
        .listRowBackground(LoupeInk.surface)
        .listRowSeparatorTint(LoupeInk.muted.opacity(0.35))
        .accessibilityElement(children: .combine)
    }

    private func smudgeRow(_ smudge: SmudgeMark) -> some View {
        let work = chrome.work(for: smudge)
        return VStack(alignment: .leading, spacing: LoupePad.inner) {
            Text(smudge.spoken)
                .font(LoupeFace.font(.body, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .strikethrough(true, color: LoupeInk.ink)
                .lineLimit(2)
            HStack {
                Text("SMUDGE")
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .padding(.horizontal, LoupePad.inner)
                    .frame(minHeight: LoupePad.step(3))
                    .overlay(
                        RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                            .stroke(LoupeInk.ink.opacity(0.35), lineWidth: 1)
                    )
                Text(work?.title ?? "Unknown painting")
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .lineLimit(1)
                Spacer(minLength: LoupePad.gap)
                Text(LoupeFigures.daykey(smudge.daykey))
                    .font(LoupeFace.font(.micro, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .padding(.vertical, LoupePad.inner)
        .frame(maxWidth: .infinity, minHeight: LoupePad.hit, alignment: .leading)
        .listRowBackground(LoupeInk.surface)
        .listRowSeparatorTint(LoupeInk.muted.opacity(0.35))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Miss \(smudge.spoken)")
    }
}
