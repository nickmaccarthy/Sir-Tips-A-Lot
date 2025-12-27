//
//  ContentView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/21/25.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @StateObject private var viewModel = TipCalculatorViewModel()
    @State private var animateGradient = false
    @State private var showTipJar = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showSaveConfirmation = false
    @State private var historyButtonHighlight = false
    @State private var isShowingScanner = false
    @State private var isNoteExpanded = false
    @FocusState private var isInputFocused: Bool
    @FocusState private var isNoteFocused: Bool

    // MARK: - Tip Preferences (read from @AppStorage)
    @AppStorage("tip_bad") private var tipBad: Double = 15.0
    @AppStorage("tip_ok") private var tipOk: Double = 20.0
    @AppStorage("tip_good") private var tipGood: Double = 25.0

    // MARK: - Custom Emojis (read from @AppStorage)
    @AppStorage("emoji_bad") private var emojiBad: String = "😢"
    @AppStorage("emoji_ok") private var emojiOk: String = "😐"
    @AppStorage("emoji_good") private var emojiGood: String = "🤩"

    // MARK: - Haptic Feedback
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }

    // MARK: - Sentiment Emoji Helper
    private func getCurrentSentimentEmoji() -> String? {
        guard let sentiment = viewModel.selectedSentiment else { return nil }

        switch sentiment {
        case "bad": return emojiBad
        case "ok": return emojiOk
        case "good": return emojiGood
        default: return nil
        }
    }

    // MARK: - Tip Selection Card (extracted to help type checker)
    @ViewBuilder
    private var tipSelectionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("How was the service?", systemImage: "face.smiling")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 10) {
                    // Bad Service
                    SentimentButton(
                        emoji: emojiBad,
                        percentage: Int(tipBad),
                        isSelected: !viewModel.isCustomTipSelected && viewModel.selectedSentiment == "bad"
                    ) {
                        triggerHaptic(style: .medium)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectTipWithSentiment(tipBad, sentiment: "bad")
                        }
                    }

                    // Ok Service
                    SentimentButton(
                        emoji: emojiOk,
                        percentage: Int(tipOk),
                        isSelected: !viewModel.isCustomTipSelected && viewModel.selectedSentiment == "ok"
                    ) {
                        triggerHaptic(style: .medium)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectTipWithSentiment(tipOk, sentiment: "ok")
                        }
                    }

                    // Great Service
                    SentimentButton(
                        emoji: emojiGood,
                        percentage: Int(tipGood),
                        isSelected: !viewModel.isCustomTipSelected && viewModel.selectedSentiment == "good"
                    ) {
                        triggerHaptic(style: .medium)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectTipWithSentiment(tipGood, sentiment: "good")
                        }
                    }

                    // Custom Tip Button
                    CustomTipButton(
                        isSelected: viewModel.isCustomTipSelected
                    ) {
                        triggerHaptic(style: .medium)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectCustomTip()
                        }
                    }
                }

                // Custom Tip Input (shown when custom is selected)
                if viewModel.isCustomTipSelected {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .foregroundColor(.mint)

                        TextField("0", text: $viewModel.customTipString)
                            .focused($isInputFocused)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)

                        Text("%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.mint)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.mint.opacity(0.5), lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
    }

    // MARK: - Share Text Generator
    private var shareText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        let bill = formatter.string(from: NSNumber(value: viewModel.billValue)) ?? "$0.00"
        let tip = formatter.string(from: NSNumber(value: viewModel.tipAmount)) ?? "$0.00"
        let total = formatter.string(from: NSNumber(value: viewModel.totalAmount)) ?? "$0.00"
        let perPerson = formatter.string(from: NSNumber(value: viewModel.amountPerPerson)) ?? "$0.00"

        if viewModel.numberOfPeopleValue > 1 {
            return "Bill: \(bill) | Tip: \(tip) (\(Int(viewModel.effectiveTipPercentage))%) | Total: \(total) | You owe: \(perPerson) — via Sir Tips-A-Lot"
        } else {
            return "Bill: \(bill) | Tip: \(tip) (\(Int(viewModel.effectiveTipPercentage))%) | Total: \(total) — via Sir Tips-A-Lot"
        }
    }

    var body: some View {
        ZStack {
            // Animated gradient background
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

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sir Tips-A-Lot")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("They like big tips and they cannot lie 🍸")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()

                        // Reset Button
                        Button {
                            triggerHaptic(style: .medium)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.resetAll()
                                // Also update to "Ok" tip percentage
                                viewModel.selectedTipPercentage = tipOk
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .opacity(viewModel.billValue > 0 ? 1 : 0.4)
                        .disabled(viewModel.billValue <= 0)

                        // History Button
                        Button {
                            triggerHaptic(style: .light)
                            showHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(historyButtonHighlight ? .mint : .white.opacity(0.7))
                                .frame(width: 44, height: 44)
                                .background(historyButtonHighlight ? Color.mint.opacity(0.3) : Color.white.opacity(0.1))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.mint, lineWidth: historyButtonHighlight ? 2 : 0)
                                )
                                .scaleEffect(historyButtonHighlight ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: historyButtonHighlight)
                        }

                        Image("InAppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onTapGesture {
                                triggerHaptic(style: .light)
                                showSettings = true
                            }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Bill Amount Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Bill Amount", systemImage: "receipt")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.7))

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$")
                                    .font(.system(size: 36, weight: .light, design: .rounded))
                                    .foregroundColor(.mint)

                                TextField("0.00", text: $viewModel.billAmountString)
                                    .focused($isInputFocused)
                                    #if os(iOS)
                                    .keyboardType(.decimalPad)
                                    #endif
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                // Scanner button
                                Button {
                                    triggerHaptic(style: .light)
                                    isShowingScanner = true
                                } label: {
                                    Image(systemName: "text.viewfinder")
                                        .font(.title2)
                                        .foregroundColor(.mint)
                                        .padding(10)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    // Tip Selection Card (Sentiment-based)
                    tipSelectionCard

                    // Options Card
                    GlassCard {
                        VStack(spacing: 20) {
                            // Round Up Toggle
                            HStack {
                                Label("Round Up Tip", systemImage: "arrow.up.circle")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                Toggle("", isOn: $viewModel.roundUp)
                                    .tint(.mint)
                                    .labelsHidden()
                                    .onChange(of: viewModel.roundUp) { _, _ in
                                        triggerHaptic(style: .light)
                                    }
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            // Split Check
                            HStack {
                                Label("Split Between", systemImage: "person.2")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                HStack(spacing: 16) {
                                    Button {
                                        triggerHaptic(style: .light)
                                        let current = Int(viewModel.numberOfPeopleString) ?? 1
                                        if current > 1 {
                                            viewModel.numberOfPeopleString = String(current - 1)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.mint.opacity(viewModel.numberOfPeopleValue > 1 ? 1 : 0.3))
                                    }
                                    .disabled(viewModel.numberOfPeopleValue <= 1)

                                    Text("\(viewModel.numberOfPeopleValue)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 40)

                                    Button {
                                        triggerHaptic(style: .light)
                                        let current = Int(viewModel.numberOfPeopleString) ?? 1
                                        viewModel.numberOfPeopleString = String(current + 1)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.mint)
                                    }
                                }
                            }
                        }
                    }

                    // Results Card
                    VStack(spacing: 0) {
                        // Tip Amount
                        ResultRow(
                            icon: "hand.thumbsup.fill",
                            label: "Tip (\(Int(viewModel.effectiveTipPercentage))%)",
                            amount: viewModel.tipAmount,
                            style: .regular
                        )

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 12)

                        // Subtotal
                        ResultRow(
                            icon: "plus.circle.fill",
                            label: "Subtotal",
                            amount: viewModel.billValue,
                            style: .regular
                        )

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 12)

                        // Total
                        ResultRow(
                            icon: "creditcard.fill",
                            label: "Total",
                            amount: viewModel.totalAmount,
                            style: .total
                        )

                        // Per Person (if splitting)
                        if viewModel.numberOfPeopleValue > 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.vertical, 12)

                            ResultRow(
                                icon: "person.fill",
                                label: "Per Person",
                                amount: viewModel.amountPerPerson,
                                style: .highlight
                            )
                        }

                        // Share Button
                        ShareLink(item: shareText) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Split")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    colors: [Color.mint, Color.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 16)

                        // Notes Section
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 12)

                        if isNoteExpanded {
                            // Expanded note text field
                            HStack(spacing: 12) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mint)

                                TextField("Add a note about this bill...", text: $viewModel.noteText, axis: .vertical)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .focused($isNoteFocused)
                                    .lineLimit(1...3)

                                Button {
                                    triggerHaptic(style: .light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isNoteExpanded = false
                                        isNoteFocused = false
                                        viewModel.isEditingNote = false
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            // Add Note button
                            Button {
                                triggerHaptic(style: .light)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isNoteExpanded = true
                                    viewModel.isEditingNote = true
                                }
                                // Focus the text field after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isNoteFocused = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: viewModel.noteText.isEmpty ? "plus.circle" : "note.text")
                                        .font(.system(size: 14))
                                    Text(viewModel.noteText.isEmpty ? "Add Note" : "Edit Note")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.mint.opacity(0.8))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.mint.opacity(0.2),
                                Color.teal.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.mint.opacity(0.5), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal, 20)

                    // Save Button
                    Button {
                        triggerHaptic(style: .medium)

                        // Get current sentiment emoji
                        let sentimentEmoji = getCurrentSentimentEmoji()

                        // Collapse notes field and stop editing mode
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isNoteExpanded = false
                            isNoteFocused = false
                            viewModel.isEditingNote = false
                        }

                        // Save with async location fetch
                        Task {
                            let locationName = await viewModel.locationManager.fetchCurrentLocationName()
                            viewModel.saveBill(locationName: locationName, sentimentEmoji: sentimentEmoji)
                        }

                        // Show confirmation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSaveConfirmation = true
                        }

                        // Reset after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showSaveConfirmation = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showSaveConfirmation ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace))
                            Text(showSaveConfirmation ? "Saved!" : "Save to History")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .contentTransition(.numericText())
                        }
                        .foregroundColor(showSaveConfirmation ? .white : .black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            Group {
                                if showSaveConfirmation {
                                    Color.green
                                } else {
                                    LinearGradient(
                                        colors: [Color.mint, Color.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 16)
                    .opacity(viewModel.billValue > 0 ? 1 : 0.4)
                    .disabled(viewModel.billValue <= 0 || showSaveConfirmation)

                    // Tip Jar Button
                    Button {
                        showTipJar = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                            Text("Tip the Developer")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .onTapGesture {
                isInputFocused = false
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isInputFocused = false
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color.mint, Color.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showTipJar) {
                TipJarView()
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingScanner) {
                ScannerContainerView { scannedAmount in
                    viewModel.billAmountString = String(format: "%.2f", scannedAmount)
                }
            }
            .onAppear {
                // Initialize tip percentage based on default sentiment (Good)
                if viewModel.selectedSentiment == "good" {
                    viewModel.selectedTipPercentage = tipGood
                }
                // Note: Location permission is requested via LocationOnboardingView on first run
            }
            .onChange(of: tipGood) { _, newValue in
                // Update tip percentage if Great sentiment is currently selected
                if viewModel.selectedSentiment == "good" {
                    viewModel.selectedTipPercentage = newValue
                }
            }
            .onChange(of: tipOk) { _, newValue in
                // Update tip percentage if Ok sentiment is currently selected
                if viewModel.selectedSentiment == "ok" {
                    viewModel.selectedTipPercentage = newValue
                }
            }
            .onChange(of: tipBad) { _, newValue in
                // Update tip percentage if Bad sentiment is currently selected
                if viewModel.selectedSentiment == "bad" {
                    viewModel.selectedTipPercentage = newValue
                }
            }
            .onChange(of: isInputFocused) { _, newValue in
                if newValue {
                    triggerHaptic(style: .light)
                }
            }
            .onChange(of: viewModel.didAutoSave) { _, didSave in
                if didSave {
                    // Animate history button highlight
                    withAnimation(.easeInOut(duration: 0.3)) {
                        historyButtonHighlight = true
                    }

                    // Fade out after a moment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            historyButtonHighlight = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Tip Jar View (StoreKit IAP)
struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager()
    @State private var showThankYou = false

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
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pink, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Tip Jar")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Enjoying the app? Your support\nis much appreciated! ☕")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)

                Spacer()

                // Tip Options
                if storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .mint))
                        .scaleEffect(1.5)
                } else if let error = storeManager.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await storeManager.loadProducts() }
                        }
                        .foregroundColor(.mint)
                    }
                    .padding()
                } else if showThankYou {
                    // Thank you state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Thank You!")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Your support means the world to me! 💚")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Product buttons
                    VStack(spacing: 16) {
                        ForEach(storeManager.products, id: \.id) { product in
                            TipProductButton(
                                product: product,
                                tipProduct: storeManager.tipProduct(for: product),
                                isLoading: storeManager.purchaseState == .purchasing
                            ) {
                                Task {
                                    await storeManager.purchase(product)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                }

                Spacer()

                // Close Button
                Button {
                    dismiss()
                } label: {
                    Text(showThankYou ? "Done" : "Maybe Later")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onChange(of: storeManager.purchaseState) { _, newState in
            if newState == .purchased {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showThankYou = true
                }
                // Auto-dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Tip Product Button
struct TipProductButton: View {
    let product: Product
    let tipProduct: TipProduct?
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji
                Text(tipProduct?.emoji ?? "💰")
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 2) {
                    Text(tipProduct?.displayName ?? product.displayName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(product.displayPrice)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.mint)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.mint.opacity(0.3), Color.teal.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.mint.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - App Info View
struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

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
                Spacer()

                // App Icon
                Image("InAppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

                // App Name
                Text("Sir Tips-A-Lot")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Version Info
                VStack(spacing: 12) {
                    InfoRow(label: "Version", value: appVersion)
                    InfoRow(label: "Build", value: buildNumber)
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 40)

                Spacer()

                // Footer
                Text("Made with ❤️ by Nick MacCarthy in Rhode Island, USA")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))

                // Close Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.mint)
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TipCalculatorViewModel
    @State private var expandedBillId: UUID? = nil

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

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bill History")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Your recent calculations")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    if !viewModel.recentBills.isEmpty {
                        Button {
                            viewModel.clearHistory()
                        } label: {
                            Text("Clear All")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                if viewModel.recentBills.isEmpty {
                    // Empty State
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))

                        Text("No History Yet")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))

                        Text("Save a calculation to see it here")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()
                } else {
                    // Bill List
                    List {
                        ForEach(viewModel.recentBills) { bill in
                            HistoryRowView(
                                bill: bill,
                                isExpanded: expandedBillId == bill.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if expandedBillId == bill.id {
                                            expandedBillId = nil
                                        } else {
                                            expandedBillId = bill.id
                                        }
                                    }
                                }
                            )
                            .listRowBackground(Color.white.opacity(0.05))
                            .listRowSeparatorTint(Color.white.opacity(0.1))
                        }
                        .onDelete(perform: viewModel.deleteBill)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    // Summary Footer Card
                    HistorySummaryCard(
                        lifetimeTips: viewModel.lifetimeTips,
                        lifetimeSpend: viewModel.lifetimeSpend
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }

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
                .padding(.vertical, 20)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let bill: SavedBill
    let isExpanded: Bool
    let onTap: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    private func formatCurrency(_ amount: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Emoji + Location or Date + Chevron
                HStack(spacing: 8) {
                    // Sentiment emoji (if available)
                    if let sentiment = bill.sentiment {
                        Text(sentiment)
                            .font(.system(size: 20))
                    }

                    // Location name or date
                    if let locationName = bill.locationName {
                        Text(locationName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Date (smaller, on the right)
                    Text(Self.dateFormatter.string(from: bill.date))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))

                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }

                // Main info row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bill")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Text(formatCurrency(bill.billAmount))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 4) {
                        Text("Tip")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(Int(bill.tipPercentage))%")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.mint)
                        Text(formatCurrency(bill.tipAmount))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Text(formatCurrency(bill.totalAmount))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                // Expanded Details
                if isExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                            .padding(.vertical, 4)

                        // Tip Amount
                        HStack {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.mint.opacity(0.7))
                            Text("Tip Amount")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(formatCurrency(bill.tipAmount))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.mint)
                        }

                        // Split info (if applicable)
                        if bill.numberOfPeople > 1 {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mint.opacity(0.7))
                                Text("Split \(bill.numberOfPeople) ways")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("\(formatCurrency(bill.amountPerPerson)) each")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.mint)
                            }
                        }

                        // Notes (if available)
                        if let notes = bill.notes, !notes.isEmpty {
                            HStack(alignment: .top) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mint.opacity(0.7))
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(notes)
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .italic()
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    // Show split info in collapsed state
                    if bill.numberOfPeople > 1 {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.mint.opacity(0.7))

                            Text("Split \(bill.numberOfPeople) ways: \(formatCurrency(bill.amountPerPerson)) each")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.mint)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - History Summary Card
struct HistorySummaryCard: View {
    let lifetimeTips: Double
    let lifetimeSpend: Double

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    private func formatCurrency(_ amount: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    var body: some View {
        VStack(spacing: 16) {
            // Primary Metric: Total Tips (highlighted)
            HStack(spacing: 12) {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.mint, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Tips Given")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    Text(formatCurrency(lifetimeTips))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            // Secondary Metric: Total Spent
            HStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Spent")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))

                    Text(formatCurrency(lifetimeSpend))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Glass Card Component
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 20)
    }
}

// MARK: - Sentiment Button
struct SentimentButton: View {
    let emoji: String
    let percentage: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 28))
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Text("\(percentage)%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.mint, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.mint.opacity(0.8) : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.mint.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Tip Button (Legacy - kept for reference)
struct TipButton: View {
    let percentage: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(percentage)%")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.white.opacity(0.1)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Custom Tip Button
struct CustomTipButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.white.opacity(0.1)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Result Row
enum ResultRowStyle {
    case regular, total, highlight
}

struct ResultRow: View {
    let icon: String
    let label: String
    let amount: Double
    let style: ResultRowStyle

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: style == .total ? 18 : 14))
                    .foregroundColor(iconColor)

                Text(label)
                    .font(labelFont)
                    .foregroundColor(textColor)
            }

            Spacer()

            Text(formatCurrency(amount))
                .font(amountFont)
                .foregroundColor(amountColor)
        }
    }

    private var iconColor: Color {
        switch style {
        case .regular: return .white.opacity(0.5)
        case .total: return .mint
        case .highlight: return .mint
        }
    }

    private var textColor: Color {
        switch style {
        case .regular: return .white.opacity(0.7)
        case .total: return .white
        case .highlight: return .mint
        }
    }

    private var labelFont: Font {
        switch style {
        case .regular: return .subheadline
        case .total: return .headline
        case .highlight: return .subheadline.weight(.semibold)
        }
    }

    private var amountFont: Font {
        switch style {
        case .regular: return .system(size: 18, weight: .semibold, design: .rounded)
        case .total: return .system(size: 32, weight: .bold, design: .rounded)
        case .highlight: return .system(size: 24, weight: .bold, design: .rounded)
        }
    }

    private var amountColor: Color {
        switch style {
        case .regular: return .white.opacity(0.9)
        case .total: return .white
        case .highlight: return .mint
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

#Preview {
    ContentView()
}
