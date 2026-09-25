import SwiftUI
import UIKit

/// Role: Loupe. One 8pt grid. Hits are 44pt. Views never pick a stray padding.
enum LoupePad {
    static let unit: CGFloat = 8

    static func step(_ n: Int) -> CGFloat {
        unit * CGFloat(n)
    }

    static var hit: CGFloat { 44 }
    static var outer: CGFloat { step(3) }
    static var card: CGFloat { step(2) }
    static var inner: CGFloat { step(1) }
    static var gap: CGFloat { step(1) }
}

/// Role: Loupe. Cards and sheets 20pt. Chips 12pt. Never a second radius language.
enum LoupeCurve {
    static let card: CGFloat = 20
    static let chip: CGFloat = 12
}

/// Role: Loupe. One soft drop-shadow token. Home uses it only on the shard hero. Every other surface is flat fill.
enum LoupeLift {
    static var plate: Color { Color.black.opacity(0.12) }
    static var radius: CGFloat { 18 }
    static var y: CGFloat { 8 }
}

/// Role: Loupe. Snap motion. Press 0.97 in 160ms ease-out. Sheets 0.96 to 1 plus fade. Reduce Motion is opacity only.
enum SnapMotion {
    static let duration: TimeInterval = 0.16

    static func swap(_ reduceMotion: Bool) -> Animation {
        .easeOut(duration: reduceMotion ? 0.2 : duration)
    }
}

extension View {
    func loupeHit() -> some View {
        frame(minWidth: LoupePad.hit, minHeight: LoupePad.hit)
            .contentShape(Rectangle())
    }

    func loupeFlat(_ radius: CGFloat = LoupeCurve.card, fill: Color = LoupeInk.surface) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func loupeLeading() -> some View {
        lineSpacing(LoupePad.inner)
    }

    @ViewBuilder
    func loupeTick(_ reduceMotion: Bool) -> some View {
        if reduceMotion {
            self
        } else {
            self.contentTransition(.numericText())
        }
    }

    func loupeKeyboardDone(focused: FocusState<Bool>.Binding) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused.wrappedValue = false }
                    .font(LoupeFace.font(.caption))
                    .foregroundStyle(LoupeInk.ink)
                    .loupeHit()
                    .accessibilityLabel("Done")
            }
        }
    }

    func loupeSheetChrome() -> some View {
        self
            .preferredColorScheme(.light)
            .tint(LoupeInk.ink)
            .presentationBackground(LoupeInk.background)
            .presentationCornerRadius(LoupeCurve.card)
            .presentationDragIndicator(.visible)
    }

    func loupeCover<Item: Identifiable, Pane: View>(
        item: Binding<Item?>,
        @ViewBuilder pane: @escaping (Item) -> Pane
    ) -> some View {
        modifier(LoupeCoverModifier(item: item, pane: pane))
    }
}

extension Image {
    func loupeCutout(maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        self
            .resizable()
            .scaledToFit()
            .padding(LoupePad.card)
            .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .leading)
            .background(
                LoupeInk.surface,
                in: RoundedRectangle(cornerRadius: LoupeCurve.card, style: .continuous)
            )
            .accessibilityHidden(true)
    }

    func loupeClippedFill() -> some View {
        Color.clear
            .overlay {
                self
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }
}

/// Role: Loupe. Explore, Saved, and Settings fill the device. iPad uses a page cover so the shard is not a stub around a card.
@MainActor
private struct LoupeCoverModifier<Item: Identifiable, Pane: View>: ViewModifier {
    @Binding var item: Item?
    @Environment(\.horizontalSizeClass) private var sizeClass
    var pane: (Item) -> Pane

    func body(content: Content) -> some View {
        content
            .sheet(item: compactItem, content: compactPane)
            .fullScreenCover(item: regularItem, content: pane)
    }

    private var fillsCanvas: Bool {
        sizeClass == .regular || UIDevice.current.userInterfaceIdiom == .pad
    }

    private var compactItem: Binding<Item?> {
        Binding(
            get: { fillsCanvas ? nil : item },
            set: { if !fillsCanvas { item = $0 } }
        )
    }

    private var regularItem: Binding<Item?> {
        Binding(
            get: { fillsCanvas ? item : nil },
            set: { if fillsCanvas { item = $0 } }
        )
    }

    private func compactPane(_ value: Item) -> some View {
        pane(value)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(LoupeInk.background)
            .presentationCornerRadius(LoupeCurve.card)
    }
}

/// Role: Loupe. Sheet entry. Scale 0.96 to 1 plus fade. Reduce Motion is opacity only.
struct LoupeSheetFrame<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.96))
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation(SnapMotion.swap(reduceMotion)) {
                    shown = true
                }
            }
    }
}
