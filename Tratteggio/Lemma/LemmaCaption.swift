import SwiftUI

/// Role: Lemma. Pierced caption under the shard tile. The hole is one Token. Filled after a PatchMark. Never sits on the photo.
struct LemmaCaption: View {
    let lemma: Lemma
    var filled: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: LoupePad.inner) {
            Text(LoupeCopy.prompt(lemma.kind))
                .font(LoupeFace.font(.caption, size: typeSize))
                .foregroundStyle(LoupeInk.ink)
                .lineLimit(1)
            wrapping
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessLabel)
    }

    private var wrapping: some View {
        WrapRail(spacing: LoupePad.inner) {
            ForEach(Array(lemma.words.enumerated()), id: \.offset) { index, word in
                if index == lemma.holeIndex, !filled {
                    holeChip
                } else {
                    Text(word)
                        .font(LoupeFace.font(.body, size: typeSize))
                        .foregroundStyle(LoupeInk.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var holeChip: some View {
        Text(lemma.hole.isEmpty ? " " : "     ")
            .font(LoupeFace.font(.body, size: typeSize))
            .foregroundStyle(LoupeInk.ink)
            .padding(.horizontal, LoupePad.inner)
            .frame(minWidth: LoupePad.step(8), minHeight: LoupePad.step(4))
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                    .fill(LoupeInk.accent)
                    .frame(height: 2)
                    .padding(.horizontal, LoupePad.inner)
                    .padding(.bottom, 2)
            }
            .overlay(
                RoundedRectangle(cornerRadius: LoupeCurve.chip, style: .continuous)
                    .stroke(LoupeInk.ink.opacity(0.28), lineWidth: 1)
            )
            .accessibilityLabel("Missing word")
    }

    private var accessLabel: String {
        if filled {
            return lemma.display(filled: true)
        }
        return "\(LoupeCopy.prompt(lemma.kind)). Missing word."
    }
}

/// Role: Lemma. Flows pierced words onto the next line. Confined to the caption under the shard.
struct WrapRail: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, origin) in result.origins.enumerated() where subviews.indices.contains(index) {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint], sizes: [CGSize]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0
        for sub in subviews {
            let size = fitted(sub, maxWidth: maxWidth)
            if x > 0, maxWidth.isFinite, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            width = max(width, x - spacing)
        }
        let height = y + rowHeight
        let capped = maxWidth.isFinite ? min(width, maxWidth) : width
        return (CGSize(width: capped, height: height), origins, sizes)
    }

    private func fitted(_ sub: LayoutSubview, maxWidth: CGFloat) -> CGSize {
        var size = sub.sizeThatFits(.unspecified)
        guard maxWidth.isFinite, size.width > maxWidth else { return size }
        size = sub.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
        size.width = min(size.width, maxWidth)
        return size
    }
}
