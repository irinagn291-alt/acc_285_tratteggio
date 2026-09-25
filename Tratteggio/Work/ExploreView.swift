import SwiftUI

/// Role: Work. Explore sheet. National Gallery of Art search writes a Shut Work. Local crate shelf when query is empty or search fails.
struct ExploreView: View {
    @Bindable var chrome: LoupeChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            LoupeSheetFrame {
                Group {
                    if chrome.exploreIsEmpty, chrome.seekFault != nil {
                        errorPage
                    } else if chrome.exploreIsEmpty {
                        emptyPage
                    } else {
                        populated
                    }
                }
                .background(LoupeInk.background.ignoresSafeArea())
            }
            .navigationTitle("Explore")
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
            .safeAreaInset(edge: .top, spacing: LoupePad.gap) {
                searchField
            }
            .loupeKeyboardDone(focused: $searchFocused)
            .scrollDismissesKeyboard(.immediately)
        }
        .loupeSheetChrome()
        .task {
            if chrome.seekHits.isEmpty {
                chrome.scheduleSeek()
            }
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: LoupePad.inner) {
            Text("National Gallery of Art")
                .font(LoupeFace.font(.micro, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .padding(.horizontal, LoupePad.outer)
            HStack(spacing: LoupePad.gap) {
                TextField("Search a work", text: $chrome.query)
                    .font(LoupeFace.font(.body, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onChange(of: chrome.query) { _, _ in
                        chrome.scheduleSeek()
                    }
                    .onSubmit {
                        searchFocused = false
                    }
                if chrome.isSeeking {
                    ProgressView()
                        .tint(LoupeInk.ink)
                        .frame(width: LoupePad.hit, height: LoupePad.hit)
                }
            }
            .padding(LoupePad.card)
            .frame(minHeight: LoupePad.hit)
            .loupeFlat()
            .padding(.horizontal, LoupePad.outer)
            if let note = chrome.crateNote {
                Text(note)
                    .font(LoupeFace.font(.micro, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .padding(.horizontal, LoupePad.outer)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let fault = chrome.seekFault, !chrome.seekHits.isEmpty {
                HStack(alignment: .center, spacing: LoupePad.gap) {
                    Text(fault)
                        .font(LoupeFace.font(.micro, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Retry") {
                        chrome.scheduleSeek()
                    }
                    .font(LoupeFace.font(.caption, size: typeSize))
                    .foregroundStyle(LoupeInk.ink)
                    .loupeHit()
                    .buttonStyle(GlyphPressStyle())
                    .accessibilityLabel("Retry search")
                }
                .padding(LoupePad.inner)
                .frame(maxWidth: .infinity, alignment: .leading)
                .loupeFlat()
                .padding(.horizontal, LoupePad.outer)
            }
        }
        .padding(.bottom, LoupePad.gap)
        .background(LoupeInk.background)
    }

    private var populated: some View {
        List {
            Section {
                ForEach(chrome.seekHits) { row in
                    Button {
                        searchFocused = false
                        Task { await chrome.crateShut(row) }
                    } label: {
                        HStack(alignment: .center, spacing: LoupePad.gap) {
                            thumb(row)
                            VStack(alignment: .leading, spacing: LoupePad.inner) {
                                Text(row.title)
                                    .font(LoupeFace.font(.body, size: typeSize))
                                    .foregroundStyle(LoupeInk.ink)
                                    .lineLimit(2)
                                Text(row.maker)
                                    .font(LoupeFace.font(.caption, size: typeSize))
                                    .foregroundStyle(LoupeInk.ink)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: LoupePad.gap)
                            crateMark(for: row)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(CrateRowStyle())
                    .disabled(chrome.stockingObjectID != nil)
                    .listRowBackground(LoupeInk.surface)
                    .listRowSeparatorTint(LoupeInk.muted.opacity(0.35))
                    .listRowInsets(
                        EdgeInsets(
                            top: LoupePad.gap,
                            leading: LoupePad.outer,
                            bottom: LoupePad.gap,
                            trailing: LoupePad.outer
                        )
                    )
                    .accessibilityLabel("\(row.title), \(row.maker)")
                    .accessibilityHint("Saves this work as Shut.")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, LoupePad.outer)
        .simultaneousGesture(
            TapGesture().onEnded { searchFocused = false }
        )
    }

    private func thumb(_ row: CatalogRow) -> some View {
        Group {
            if let url = row.thumbURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        LoupeInk.surface
                    }
                }
            } else {
                LoupeInk.surface
            }
        }
        .frame(width: LoupePad.hit, height: LoupePad.hit)
        .clipShape(RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous))
        .clipped()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func crateMark(for row: CatalogRow) -> some View {
        if chrome.stockingObjectID == row.objectID {
            ProgressView()
                .tint(LoupeInk.ink)
                .frame(width: LoupePad.hit, height: LoupePad.hit)
                .background(
                    LoupeInk.accent.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                )
        } else {
            Text("Save")
                .font(LoupeFace.font(.caption, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .padding(.horizontal, LoupePad.inner)
                .frame(minWidth: LoupePad.hit, minHeight: LoupePad.hit)
                .background(
                    LoupeInk.accent.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                )
        }
    }

    private var emptyPage: some View {
        MutePage(
            art: LoupeArt.emptyList,
            headline: "Shelf quiet.",
            line: "Search the National Gallery of Art, or save from the local shelf.",
            actionTitle: "Show shelf"
        ) {
            chrome.query = ""
            chrome.scheduleSeek()
        }
    }

    private var errorPage: some View {
        MutePage(
            art: LoupeArt.emptyList,
            headline: "Search failed.",
            line: chrome.seekFault ?? "Try again, or save from the local shelf.",
            actionTitle: "Retry"
        ) {
            chrome.scheduleSeek()
        }
    }
}
