//
//  SettingsView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Tip Preferences (persisted via @AppStorage)
    @AppStorage("tip_bad") var tipBad: Double = 15.0
    @AppStorage("tip_ok") var tipOk: Double = 20.0
    @AppStorage("tip_good") var tipGood: Double = 25.0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Tip Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Customize what each sentiment means to you")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                
                // Settings Cards
                VStack(spacing: 16) {
                    SentimentSettingRow(
                        emoji: "😢",
                        label: "Bad Service",
                        percentage: $tipBad
                    )
                    
                    SentimentSettingRow(
                        emoji: "😐",
                        label: "Ok Service",
                        percentage: $tipOk
                    )
                    
                    SentimentSettingRow(
                        emoji: "🤩",
                        label: "Great Service",
                        percentage: $tipGood
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Done Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Sentiment Setting Row
struct SentimentSettingRow: View {
    let emoji: String
    let label: String
    @Binding var percentage: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji
            Text(emoji)
                .font(.system(size: 36))
            
            // Label and Value
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(Int(percentage))% tip")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.mint)
            }
            
            Spacer()
            
            // Stepper Controls
            HStack(spacing: 12) {
                Button {
                    if percentage > 0 {
                        percentage -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.mint.opacity(percentage > 0 ? 1 : 0.3))
                }
                .disabled(percentage <= 0)
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 50)
                
                Button {
                    if percentage < 50 {
                        percentage += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.mint.opacity(percentage < 50 ? 1 : 0.3))
                }
                .disabled(percentage >= 50)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    SettingsView()
}

