import SwiftUI

/// Two-thumb slider (Material `RangeSlider`). Dragging moves whichever thumb is closest.
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    var tint: Color = Palette.accent

    private enum Thumb { case lower, upper }

    @State private var activeThumb: Thumb?
    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let track = max(geo.size.width - thumbSize, 1)
            let lowerX = position(of: range.lowerBound, track: track)
            let upperX = position(of: range.upperBound, track: track)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.25))
                    .frame(height: 4)
                    .padding(.horizontal, thumbSize / 2)
                Capsule()
                    .fill(tint)
                    .frame(width: max(upperX - lowerX, 0), height: 4)
                    .offset(x: lowerX + thumbSize / 2)
                thumb.offset(x: lowerX)
                thumb.offset(x: upperX)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let value = self.value(at: drag.location.x, track: track)
                        let thumb = activeThumb ?? closestThumb(to: value)
                        activeThumb = thumb
                        switch thumb {
                        case .lower: range = min(value, range.upperBound)...range.upperBound
                        case .upper: range = range.lowerBound...max(value, range.lowerBound)
                        }
                    }
                    .onEnded { _ in activeThumb = nil }
            )
        }
        .frame(height: thumbSize + 12)
        .accessibilityElement()
        .accessibilityLabel("Price range")
        .accessibilityValue("\(Int(range.lowerBound.rounded())) to \(Int(range.upperBound.rounded()))")
    }

    private var thumb: some View {
        Circle()
            .fill(tint)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }

    private var span: Double { bounds.upperBound - bounds.lowerBound }

    private func position(of value: Double, track: CGFloat) -> CGFloat {
        guard span > 0 else { return 0 }
        return CGFloat((value - bounds.lowerBound) / span) * track
    }

    private func value(at x: CGFloat, track: CGFloat) -> Double {
        let fraction = min(max((x - thumbSize / 2) / track, 0), 1)
        return bounds.lowerBound + Double(fraction) * span
    }

    private func closestThumb(to value: Double) -> Thumb {
        let toLower = abs(value - range.lowerBound)
        let toUpper = abs(value - range.upperBound)
        if toLower == toUpper {
            // Thumbs overlap: pick by drag direction so they can be pulled apart.
            return value < range.lowerBound ? .lower : .upper
        }
        return toLower < toUpper ? .lower : .upper
    }
}
