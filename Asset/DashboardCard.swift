import SwiftUI

struct DashboardCard<Content: View>: View {
    let minHeight: CGFloat
    let content: Content

    init(
        minHeight: CGFloat = 110,
        @ViewBuilder content: () -> Content
    ) {
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(
                maxWidth: .infinity,
                minHeight: minHeight,
                alignment: .leading
            )
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)   // lets shimmer glow through
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(0.2),
                radius: 12,
                y: 6
            )
    }
}
