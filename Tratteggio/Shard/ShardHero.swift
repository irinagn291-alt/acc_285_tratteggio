import SwiftUI

/// Role: Shard. Quiz hero. Shape, Path, and one Material live only on this magnified crop. Soft shadow only here. Caption sits under the tile.
struct ShardHero: View {
    let shard: Shard?
    let work: Work?
    var showSuccess: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(LoupeArt.cardBackdrop)
                    .loupeClippedFill()
                    .opacity(0.28)
                    .accessibilityHidden(true)
                crop(in: geo.size)
                    .clipShape(RoundedRectangle(cornerRadius: LoupeCurve.card, style: .continuous))
                loupeGlass(in: geo.size)
                if showSuccess {
                    Image(LoupeArt.successMark)
                        .resizable()
                        .scaledToFit()
                        .frame(width: LoupePad.step(10), height: LoupePad.step(10))
                        .padding(LoupePad.card)
                        .background(
                            LoupeInk.surface.opacity(0.92),
                            in: RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                        )
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: LoupeCurve.card, style: .continuous))
        .shadow(color: LoupeLift.plate, radius: LoupeLift.radius, y: LoupeLift.y)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessLabel)
    }

    @ViewBuilder
    private func crop(in size: CGSize) -> some View {
        Color.clear
            .overlay {
                if let url = shard?.thumbURL ?? work?.thumbURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            magnified(image, in: size)
                        default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .clipped()
    }

    private func magnified(_ image: Image, in size: CGSize) -> some View {
        let nx = shard?.originX ?? 0.18
        let ny = shard?.originY ?? 0.18
        let nw = max(shard?.width ?? 0.48, 0.2)
        let nh = max(shard?.height ?? 0.48, 0.2)
        let fullW = size.width / nw
        let fullH = size.height / nh
        return image
            .resizable()
            .scaledToFill()
            .frame(width: fullW, height: fullH)
            .offset(
                x: size.width / 2 - (nx + nw / 2) * fullW,
                y: size.height / 2 - (ny + nh / 2) * fullH
            )
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func loupeGlass(in size: CGSize) -> some View {
        let side = min(size.width, size.height) * 0.72
        return ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: side, height: side)
                .allowsHitTesting(false)
            ShardLoupeRim()
                .stroke(LoupeInk.ink.opacity(0.28), lineWidth: 2)
                .frame(width: side, height: side)
            ShardHatch()
                .stroke(LoupeInk.accent.opacity(0.55), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .frame(width: side, height: side)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private var placeholder: some View {
        Image(LoupeArt.linenShard)
            .resizable()
            .scaledToFit()
            .padding(LoupePad.card)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoupeInk.surface)
    }

    private var accessLabel: String {
        if shard == nil {
            return "Loupe. No shard."
        }
        return "Magnified crop."
    }
}

/// Role: Shard. Circular glass rim for the magnified crop. Custom Path confined to Quiz.
struct ShardLoupeRim: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.insetBy(dx: 3, dy: 3)
        path.addEllipse(in: inset)
        let handle = CGRect(
            x: inset.maxX - inset.width * 0.08,
            y: inset.maxY - inset.height * 0.08,
            width: inset.width * 0.22,
            height: inset.height * 0.22
        )
        path.addEllipse(in: handle)
        return path
    }
}

/// Role: Shard. Tratteggio hatch across the loupe glass. Custom Path confined to Quiz.
struct ShardHatch: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.22)
        var x = inset.minX
        while x < inset.maxX {
            path.move(to: CGPoint(x: x, y: inset.minY))
            path.addLine(to: CGPoint(x: x + inset.width * 0.08, y: inset.maxY))
            x += inset.width * 0.14
        }
        return path
    }
}
