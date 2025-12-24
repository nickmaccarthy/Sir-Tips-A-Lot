//
//  ContentView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/21/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TipCalculatorViewModel()
    @State private var animateGradient = false
    @State private var showTipJar = false
    @State private var showAppInfo = false
    @State private var showHistory = false
    @State private var logoTapCount = 0
    @State private var showSaveConfirmation = false
    @FocusState private var isInputFocused: Bool
    
    // MARK: - Haptic Feedback
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
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
                        
                        // History Button
                        Button {
                            triggerHaptic(style: .light)
                            showHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Image("InAppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onTapGesture {
                                logoTapCount += 1
                                if logoTapCount >= 4 {
                                    logoTapCount = 0
                                    showAppInfo = true
                                }
                                // Reset tap count after 2 seconds of inactivity
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    logoTapCount = 0
                                }
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
                            }
                        }
                    }
                    
                    // Tip Selection Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Select Tip", systemImage: "percent")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(spacing: 10) {
                                ForEach([18, 20, 25], id: \.self) { percentage in
                                    TipButton(
                                        percentage: percentage,
                                        isSelected: !viewModel.isCustomTipSelected && viewModel.selectedTipPercentage == Double(percentage)
                                    ) {
                                        triggerHaptic(style: .medium)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.selectTipPercentage(Double(percentage))
                                        }
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
                        viewModel.saveBill()
                        
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
                            Text("Tip Jar")
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
            .sheet(isPresented: $showAppInfo) {
                AppInfoView()
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(viewModel: viewModel)
            }
            .onChange(of: isInputFocused) { _, newValue in
                if newValue {
                    triggerHaptic(style: .light)
                }
            }
        }
    }
}

// MARK: - Tip Jar View
struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Your payment usernames
    let venmoUsername = "NickMacCarthy"
    let cashAppUsername = "$NickMacCarthy"  // Include the $ for Cash App
    let paypalUsername = "nickmaccarthy"
    
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
                    
                    Text("Enjoying this app? Consider buying me a coffee! ☕")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Payment Options
                VStack(spacing: 16) {
                    PaymentButton(
                        title: "Venmo",
                        subtitle: "@\(venmoUsername)",
                        icon: "v.circle.fill",
                        color: Color(red: 0.2, green: 0.6, blue: 0.9)
                    ) {
                        openURL("https://venmo.com/u/\(venmoUsername)")
                    }
                    
                    PaymentButton(
                        title: "Cash App",
                        subtitle: cashAppUsername,
                        icon: "dollarsign.circle.fill",
                        color: Color(red: 0.0, green: 0.8, blue: 0.4)
                    ) {
                        openURL("https://cash.app/\(cashAppUsername)")
                    }
                    
                    PaymentButton(
                        title: "PayPal",
                        subtitle: "@\(paypalUsername)",
                        icon: "p.circle.fill",
                        color: Color(red: 0.0, green: 0.4, blue: 0.8)
                    ) {
                        openURL("https://www.paypal.com/paypalme/\(paypalUsername)")
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Close Button
                Button {
                    dismiss()
                } label: {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

// MARK: - Payment Button
struct PaymentButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
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
                Text("Made with ❤️ by Nick MacCarthy - nickmaccarthy@gmail.com")
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
                            HistoryRowView(bill: bill)
                                .listRowBackground(Color.white.opacity(0.05))
                                .listRowSeparatorTint(Color.white.opacity(0.1))
                        }
                        .onDelete(perform: viewModel.deleteBill)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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
        VStack(alignment: .leading, spacing: 12) {
            // Date
            Text(Self.dateFormatter.string(from: bill.date))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            
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
            
            // Split info (if applicable)
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
        .padding(.vertical, 8)
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

// MARK: - Tip Button
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
