import SwiftUI

struct SimpleGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.95),
                Color(red: 0.10, green: 0.12, blue: 0.16),
                Color(red: 0.12, green: 0.14, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    SimpleGradientBackground()
}
