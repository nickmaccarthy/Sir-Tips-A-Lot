//
//  LocationOnboardingView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import SwiftUI
import CoreLocation

struct LocationOnboardingView: View {
    @State private var animateGradient = false
    @State private var iconScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0

    let locationManager: LocationManager
    let onComplete: () -> Void

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
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }

            VStack(spacing: 32) {
                Spacer()

                // Location Icon
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.mint.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Icon
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.mint.opacity(0.4), radius: 15, x: 0, y: 5)
                }
                .scaleEffect(iconScale)

                // Title and Description
                VStack(spacing: 16) {
                    Text("Help Us Remember Where You Dined")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Sir Tips-A-Lot can save the restaurant name with your bills. Your location data stays on your device — we never collect or share it.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    // Primary: Enable Location
                    Button {
                        triggerHaptic(style: .medium)
                        locationManager.requestPermission()
                        // Small delay to allow system dialog to appear, then complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            markOnboardingComplete()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Enable Location")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.mint.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // Secondary: Maybe Later
                    Button {
                        triggerHaptic(style: .light)
                        markOnboardingComplete()
                    } label: {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            // Animate content appearance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                iconScale = 1.0
                contentOpacity = 1.0
            }
        }
    }

    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "hasSeenLocationOnboarding")
        withAnimation(.easeOut(duration: 0.3)) {
            onComplete()
        }
    }

    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
}

// Reuse existing ScaleButtonStyle if available, otherwise define locally
// This is already defined in ContentView.swift, but we need to reference it here

#Preview {
    LocationOnboardingView(
        locationManager: LocationManager(),
        onComplete: {}
    )
}
