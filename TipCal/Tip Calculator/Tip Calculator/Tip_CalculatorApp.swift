//
//  Tip_CalculatorApp.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/21/25.
//

import SwiftUI
import CoreLocation

@main
struct Tip_CalculatorApp: App {
    @State private var isShowingSplash = true
    @State private var isShowingLocationOnboarding = false
    @AppStorage("hasSeenLocationOnboarding") private var hasSeenLocationOnboarding = false

    // Shared location manager for onboarding
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                // Location onboarding overlay (shown after splash if needed)
                if isShowingLocationOnboarding {
                    LocationOnboardingView(
                        locationManager: locationManager,
                        onComplete: {
                            withAnimation(.easeOut(duration: 0.4)) {
                                isShowingLocationOnboarding = false
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }

                // Splash screen overlay (shown on top of everything)
                if isShowingSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .onAppear {
                // Dismiss splash after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        isShowingSplash = false
                    }

                    // After splash fades, check if we need to show location onboarding
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        checkLocationOnboarding()
                    }
                }
            }
        }
    }

    /// Checks if location onboarding should be shown
    private func checkLocationOnboarding() {
        // Only show if user hasn't seen it AND permission is not determined
        if !hasSeenLocationOnboarding && locationManager.authorizationStatus == .notDetermined {
            withAnimation(.easeIn(duration: 0.3)) {
                isShowingLocationOnboarding = true
            }
        }
    }
}
