import SwiftUI

/// Role: Loupe. Settings Form. National Gallery of Art credit, Undo, contact URL, re-run onboarding, confirmed resetAllData.
struct SettingsView: View {
    @Bindable var chrome: LoupeChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            LoupeSheetFrame {
                Form {
                    if chrome.settingsIsEmpty {
                        Section {
                            Text(LoupeCopy.muteHeadline)
                                .font(LoupeFace.font(.body, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                            Text(LoupeCopy.muteLine)
                                .font(LoupeFace.font(.caption, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                            Button("Explore") {
                                chrome.present(.explore)
                            }
                            .buttonStyle(FrameCapsuleStyle(tone: .frame, isLoading: false))
                            .listRowInsets(supportInsets)
                            .listRowBackground(LoupeInk.background)
                        }
                    } else {
                        Section {
                            HStack(alignment: .center, spacing: LoupePad.gap) {
                                crateTally(title: "Restored", value: chrome.loupe.patchMarks.count)
                                crateTally(title: "Misses", value: chrome.loupe.smudgeMarks.count)
                            }
                            .frame(maxWidth: .infinity, minHeight: LoupePad.hit)
                        } header: {
                            Text("Crate")
                                .font(LoupeFace.font(.caption, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                        }
                    }

                    if let fault = chrome.loupeFault {
                        Section {
                            Text(fault)
                                .font(LoupeFace.font(.body, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                                .loupeLeading()
                            Button("Return to the crop") {
                                dismiss()
                            }
                            .font(LoupeFace.font(.body, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                            .frame(maxWidth: .infinity, minHeight: LoupePad.hit, alignment: .leading)
                            .contentShape(Rectangle())
                            .buttonStyle(CrateRowStyle())
                        } header: {
                            Text("Write")
                                .font(LoupeFace.font(.caption, size: typeSize))
                                .foregroundStyle(LoupeInk.ink)
                        }
                    }

                    Section {
                        Link(destination: CatalogClient.ngaHomeURL) {
                            settingsRow(title: "National Gallery of Art", detail: "nga.gov")
                        }
                        Link(destination: CatalogClient.ngaOpenAccessURL) {
                            settingsRow(title: "Open access images", detail: "nga.gov/open-access-images")
                        }
                    } header: {
                        Text("Collection")
                            .font(LoupeFace.font(.caption, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                    } footer: {
                        Text("Public-domain paintings come from the National Gallery of Art.")
                            .font(LoupeFace.font(.micro, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Section {
                        Link(destination: CatalogClient.contactURL) {
                            settingsRow(title: "Contact", detail: "tratteggio-loupe.pro/contact-us")
                        }
                        Button("Reset the crate") {
                            confirmReset = true
                        }
                        .buttonStyle(FrameCapsuleStyle(tone: .wipe, isLoading: false))
                        .listRowInsets(supportInsets)
                        .listRowBackground(LoupeInk.background)
                        .listRowSeparator(.hidden)
                        .accessibilityLabel("Reset the crate")
                        .accessibilityHint("Removes works and marks on this device.")
                    } header: {
                        Text("Support")
                            .font(LoupeFace.font(.caption, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                    }

                    Section {
                        Button {
                            chrome.present(.patchGuide)
                        } label: {
                            settingsRow(
                                title: "Frame then patch",
                                detail: "Frame punches one word. Patch files Restored."
                            )
                        }
                        .buttonStyle(CrateRowStyle())
                    } header: {
                            Text("Guide")
                            .font(LoupeFace.font(.caption, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                    }

                    Section {
                        Button {
                            Task { await chrome.undoMark() }
                        } label: {
                            HStack {
                                Text("Undo")
                                    .font(LoupeFace.font(.body, size: typeSize))
                                    .foregroundStyle(LoupeInk.ink)
                                Spacer()
                                if chrome.undoBusy {
                                    ProgressView()
                                        .tint(LoupeInk.ink)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: LoupePad.hit, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(CrateRowStyle())
                        .disabled(!chrome.undoEnabled)
                        Button("Re-run onboarding") {
                            chrome.replayOnboarding()
                        }
                        .font(LoupeFace.font(.body, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                        .frame(maxWidth: .infinity, minHeight: LoupePad.hit, alignment: .leading)
                        .contentShape(Rectangle())
                        .buttonStyle(CrateRowStyle())
                    } footer: {
                        Text("Undo drops the newest patch or miss. Reset removes the crate on this device.")
                            .font(LoupeFace.font(.micro, size: typeSize))
                            .foregroundStyle(LoupeInk.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(LoupeInk.background)
                .tint(LoupeInk.ink)
                .listSectionSpacing(LoupePad.gap)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoupeInk.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(LoupeInk.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
            .alert("Reset the crate?", isPresented: $confirmReset) {
                Button("Keep", role: .cancel) {}
                Button("Reset the crate", role: .destructive) {
                    Task { await chrome.resetAllData() }
                }
            } message: {
                Text("This removes works, patches, and misses on this device. It cannot be undone.")
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

    private var supportInsets: EdgeInsets {
        EdgeInsets(
            top: LoupePad.gap,
            leading: LoupePad.outer,
            bottom: LoupePad.gap,
            trailing: LoupePad.outer
        )
    }

    private func crateTally(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(LoupeFace.font(.micro, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(LoupeFigures.whole(value))
                .font(LoupeFace.font(.headline, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .monospacedDigit()
                .lineLimit(1)
                .layoutPriority(1)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    private func settingsRow(title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: LoupePad.gap) {
            VStack(alignment: .leading, spacing: LoupePad.inner) {
                Text(title)
                    .font(LoupeFace.font(.body, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(LoupeFace.font(.micro, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Image(systemName: "arrow.up.right")
                .font(LoupeFace.font(.caption, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .accessibilityHidden(true)
        }
        .padding(.vertical, LoupePad.inner)
        .contentShape(Rectangle())
        .loupeHit()
    }
}
