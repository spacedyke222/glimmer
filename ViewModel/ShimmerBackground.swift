import SwiftUI

/// Soft multicolor backdrop shared by every page.
///
/// Blur-free on purpose: an earlier `.blur(radius: 80)` version re-rasterized
/// the whole screen every frame and made busy pages stutter. Radial gradients
/// are inherently soft, so they need no blur and stay cheap to draw.
///
/// Currently static. (The "freeze on Start" originally chased here turned out
/// to be RunView's hand-rolled run timer — fixed separately — not this view.
/// Gentle motion can be re-added safely without blur, e.g. via TimelineView.)
struct ShimmerBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple, Color.indigo, Color.pink.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.yellow.opacity(0.40), .clear],
                center: UnitPoint(x: 0.18, y: 0.18),
                startRadius: 0,
                endRadius: 460
            )

            RadialGradient(
                colors: [Color.orange.opacity(0.38), .clear],
                center: UnitPoint(x: 0.88, y: 0.92),
                startRadius: 0,
                endRadius: 460
            )

            RadialGradient(
                colors: [Color.cyan.opacity(0.22), .clear],
                center: UnitPoint(x: 0.85, y: 0.20),
                startRadius: 0,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}
