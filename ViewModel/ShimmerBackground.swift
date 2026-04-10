import SwiftUI

struct ShimmerBackground: View {
    @State private var animate = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.purple,
                Color.indigo,
                Color.yellow.opacity(0.6),
                Color.orange.opacity(0.6),
                Color.pink
            ],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .blur(radius: 80)
        .animation(
            .easeInOut(duration: 6)
            .repeatForever(autoreverses: true),
            value: animate
        )
        .onAppear {
            animate.toggle()
        }
    }
}
