//
//  SplashView.swift
//  Alluvia
//
// This is the homescreen of the Alluvia App. It contains a button to enter the model selection page and basic background

import SwiftUI

// This sets the splash screen background color to a  animated gradient
struct AnimatedGradientBackground: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.orange,
                Color(red: 0.10, green: 0.10, blue: 0.10),
                Color(red: 0.55, green: 0.45, blue: 0.35),
                Color.gray
            ]),
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animate)
        .onAppear {
            animate = true
        }
        .ignoresSafeArea()
    }
}

struct SplashView: View {
    @State private var showSelection = false

    var body: some View {
        
        // Stacks the gradient into the screen background
        // Z stack stacks layers in the z direction
        ZStack {
            // Integrates the animated vibrant background
            AnimatedGradientBackground()
            
            // Large blurred capsule
            Capsule()
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: .rect(cornerRadius: 60))
                .frame(width: 320, height: 280)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                .overlay(
                    VStack(spacing: 24) {
                        // Alluvia Logo integration
                        Image("Alluvia_Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)

                        // Integrates the enter button to enter the app
                        Button {
                            withAnimation(.easeInOut) {
                                showSelection = true
                            }
                        } label: {
                            Text("Enter")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.vertical, 10)
                                .frame(width: 180)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color.orange)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
        }
        
        // Brings the user to the model selection page
        .fullScreenCover(isPresented: $showSelection) {
            ModelSelectionView()
        }
    }
}

#Preview {
    SplashView()
}
