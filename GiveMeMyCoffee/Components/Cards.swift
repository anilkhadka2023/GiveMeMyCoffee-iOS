import SwiftUI

/// White rounded card with a thin border, used by the order and profile screens.
struct OutlinedCard<Content: View>: View {
    var padding: EdgeInsets = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
    var alignment: HorizontalAlignment = .leading
    private let content: Content

    init(
        padding: EdgeInsets = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14),
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.cardBorder, lineWidth: 1))
    }
}

struct HDivider: View {
    var color: Color = Palette.divider

    var body: some View {
        Rectangle().fill(color).frame(height: 1)
    }
}

/// Green "Taking orders" pill with a status dot.
struct TakingOrdersPill: View {
    let text: String
    var fontSize: CGFloat = 12
    var dotSize: CGFloat = 7
    var horizontalPadding: CGFloat = 10

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Palette.statusGreen).frame(width: dotSize, height: dotSize)
            Text(text)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(Palette.statusGreen)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 6)
        .background(Palette.statusGreenBackground, in: Capsule())
    }
}
