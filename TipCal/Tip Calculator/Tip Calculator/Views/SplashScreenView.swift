//
//  SplashScreenView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var animateGradient = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // Animated gradient background (matching app theme)
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color(red: 0.1, green: 0.15, blue: 0.2)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }

            // Centered logo with scale-up animation
            VStack(spacing: 24) {
                Image("InAppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: Color.mint.opacity(0.3), radius: 20, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // App name with elegant typography
                VStack(spacing: 8) {
                    Text("Sir Tips-A-Lot")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("They like big tips and they cannot lie")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            // Animate logo scale and opacity on appear
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
