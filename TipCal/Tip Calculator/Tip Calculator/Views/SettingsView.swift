//
//  SettingsView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAppInfo = false
    @State private var showTipJar = false

    // MARK: - Tip Preferences (persisted via @AppStorage)
    @AppStorage("tip_bad") var tipBad: Double = 15.0
    @AppStorage("tip_ok") var tipOk: Double = 20.0
    @AppStorage("tip_good") var tipGood: Double = 25.0

    // MARK: - Custom Emojis (persisted via @AppStorage)
    @AppStorage("emoji_bad") var emojiBad: String = "😢"
    @AppStorage("emoji_ok") var emojiOk: String = "😐"
    @AppStorage("emoji_good") var emojiGood: String = "🤩"

    // MARK: - Location Settings
    @AppStorage("locationEnabled") var locationEnabled: Bool = true
    @State private var locationManager = LocationManager()

    // MARK: - Scanner Settings (hidden for now, still in development)
    @AppStorage("enhancedScannerEnabled") var enhancedScannerEnabled: Bool = false

    // MARK: - Tip Options
    @AppStorage("roundUpByDefault") var roundUpByDefault: Bool = false

    // MARK: - Currency
    @AppStorage("selectedCurrency") var selectedCurrency: String = "usd"

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

            ScrollView {
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
                    .padding(.top, 32)

                // Tip Settings Cards
                VStack(spacing: 16) {
                    SentimentSettingRow(
                        emoji: $emojiBad,
                        label: "Meh Service",
                        percentage: $tipBad
                    )

                    SentimentSettingRow(
                        emoji: $emojiOk,
                        label: "Ok Service",
                        percentage: $tipOk
                    )

                    SentimentSettingRow(
                        emoji: $emojiGood,
                        label: "Great Service",
                        percentage: $tipGood
                    )
                }
                .padding(.horizontal, 20)

                // Location Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 4)

                    LocationSettingRow(
                        locationEnabled: $locationEnabled,
                        authorizationStatus: locationManager.authorizationStatus,
                        locationManager: locationManager
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // NOTE: Scanner Settings Section hidden for now (enhanced scanner still in development)
                // Uncomment when ready to expose to users:
                // VStack(alignment: .leading, spacing: 12) {
                //     Text("Scanner")
                //         .font(.system(size: 14, weight: .semibold, design: .rounded))
                //         .foregroundColor(.white.opacity(0.5))
                //         .padding(.leading, 4)
                //
                //     ScannerSettingRow(enhancedScannerEnabled: $enhancedScannerEnabled)
                // }
                // .padding(.horizontal, 20)
                // .padding(.top, 8)

                // Currency Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Currency")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 4)

                    CurrencySettingRow(selectedCurrency: $selectedCurrency)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Tip Options Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tip Options")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 4)

                    RoundUpSettingRow(roundUpByDefault: $roundUpByDefault)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 4)

                    Button {
                        showAppInfo = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.mint, Color.teal],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .background(Color.mint.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("About Sir Tips-A-Lot")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Version info and credits")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
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
                    .buttonStyle(ScaleButtonStyle())

                    // Tip Developer Button
                    Button {
                        showTipJar = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.pink, Color.red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .background(Color.pink.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tip the Developer")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Support future development")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
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
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

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
                .padding(.top, 16)
                .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showAppInfo) {
            AppInfoView()
        }
        .sheet(isPresented: $showTipJar) {
            TipJarView()
        }
    }
}

// MARK: - Emoji TextField (UIViewRepresentable for emoji keyboard)
struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 36)
        textField.backgroundColor = .clear
        textField.tintColor = .clear // Hide cursor
        textField.text = text
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField

        init(_ parent: EmojiTextField) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Only allow emoji characters
            if string.isEmpty {
                return true // Allow backspace
            }

            // Check if the string contains an emoji
            if string.unicodeScalars.contains(where: { $0.properties.isEmoji && $0.properties.isEmojiPresentation }) {
                // Take only the first emoji
                if let firstEmoji = string.first {
                    parent.text = String(firstEmoji)
                    textField.resignFirstResponder()
                    parent.onCommit()
                }
            }
            return false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            parent.onCommit()
            return true
        }
    }
}

// MARK: - Sentiment Setting Row
struct SentimentSettingRow: View {
    @Binding var emoji: String
    let label: String
    @Binding var percentage: Double
    @State private var isEditingEmoji = false
    @FocusState private var emojiFieldFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Tappable Emoji with edit hint
            ZStack {
                if isEditingEmoji {
                    EmojiTextField(text: $emoji) {
                        isEditingEmoji = false
                    }
                    .frame(width: 50, height: 50)
                } else {
                    Text(emoji)
                        .font(.system(size: 36))
                }

                // Edit indicator
                if !isEditingEmoji {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.mint)
                        .offset(x: 18, y: -18)
                }
            }
            .frame(width: 50, height: 50)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isEditingEmoji = true
                }
            }

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

// MARK: - Location Setting Row
struct LocationSettingRow: View {
    @Binding var locationEnabled: Bool
    let authorizationStatus: CLAuthorizationStatus
    let locationManager: LocationManager

    private var isSystemPermissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    private var isNotDetermined: Bool {
        authorizationStatus == .notDetermined
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Location icon
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.mint, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .background(Color.mint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Label and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text("Save Restaurant Location")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Attach venue names to your bill history")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: {
                        // Show OFF if system permission is denied, regardless of user preference
                        if isSystemPermissionDenied {
                            return false
                        }
                        return locationEnabled
                    },
                    set: { newValue in
                        locationEnabled = newValue
                        // If turning ON and permission not yet requested, request it
                        if newValue && isNotDetermined {
                            locationManager.requestPermission()
                        }
                    }
                ))
                    .tint(.mint)
                    .labelsHidden()
                    .disabled(isSystemPermissionDenied)
            }

            // Warning and settings button if system permission denied
            if isSystemPermissionDenied {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)

                        Text("Location access is denied in System Settings")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.orange.opacity(0.9))

                        Spacer()
                    }

                    // Open System Settings button
                    Button {
                        openSystemSettings()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                                .font(.system(size: 14, weight: .medium))
                            Text("Open System Settings")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.top, 4)
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

    /// Opens the app's settings page in System Settings
    private func openSystemSettings() {
        #if os(iOS)
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
        #endif
    }
}

// MARK: - Scanner Setting Row
struct ScannerSettingRow: View {
    @Binding var enhancedScannerEnabled: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Scanner icon
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.mint, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .background(Color.mint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Label and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enhanced Scanner")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(enhancedScannerEnabled ? "Document mode with better accuracy" : "Live camera mode")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Toggle
                Toggle("", isOn: $enhancedScannerEnabled)
                    .tint(.mint)
                    .labelsHidden()
            }

            // Explanation text
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.mint.opacity(0.7))

                Text(enhancedScannerEnabled
                     ? "Scans receipt as a document for better text recognition"
                     : "Uses live camera with real-time detection")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
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

// MARK: - Round Up Setting Row
struct RoundUpSettingRow: View {
    @Binding var roundUpByDefault: Bool
    @AppStorage("selectedCurrency") private var selectedCurrency: String = "usd"

    private var currency: Currency { Currency.from(selectedCurrency) }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Round up icon
                Image(systemName: "arrow.up.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.mint, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .background(Color.mint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Label and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text("Round Up Tip")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Round tip to nearest \(currency.symbol)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Toggle
                Toggle("", isOn: $roundUpByDefault)
                    .tint(.mint)
                    .labelsHidden()
            }

            // Explanation text
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.mint.opacity(0.7))

                Text("When enabled, tips will be rounded up by default")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
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

// MARK: - Currency Setting Row
struct CurrencySettingRow: View {
    @Binding var selectedCurrency: String
    @State private var showingPicker = false

    private var currency: Currency { Currency.from(selectedCurrency) }

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 14) {
                // Currency icon
                Text(currency.symbol)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.mint)
                    .frame(width: 36, height: 36)
                    .background(Color.mint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Label and current selection
                VStack(alignment: .leading, spacing: 2) {
                    Text("Currency")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(currency.displayName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
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
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showingPicker) {
            CurrencyPickerView(selectedCurrency: $selectedCurrency)
        }
    }
}

// MARK: - Currency Picker View
struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCurrency: String

    var body: some View {
        NavigationView {
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

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Currency.allCases) { currency in
                            CurrencyOptionRow(
                                currency: currency,
                                isSelected: selectedCurrency == currency.rawValue
                            ) {
                                selectedCurrency = currency.rawValue
                                dismiss()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.mint)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(red: 0.1, green: 0.1, blue: 0.2), for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Currency Option Row
struct CurrencyOptionRow: View {
    let currency: Currency
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Currency symbol
                Text(currency.symbol)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .black : .mint)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.mint : Color.mint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Currency details
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(currency.code)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.mint)
                }
            }
            .padding(14)
            .background(isSelected ? Color.mint.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.mint.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    SettingsView()
}
