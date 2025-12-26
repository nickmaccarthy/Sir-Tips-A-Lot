//
//  TipCalculatorViewModel.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Foundation
import SwiftUI
import Combine

class TipCalculatorViewModel: ObservableObject {
    @Published var billAmountString: String = ""
    @Published var selectedTipPercentage: Double = 20.0
    @Published var roundUp: Bool = false
    @Published var numberOfPeopleString: String = "1"
    @Published var isCustomTipSelected: Bool = false
    @Published var customTipString: String = ""
    @Published var selectedSentiment: String? = "🤩" // Default to "Good" sentiment
    @Published var recentBills: [SavedBill] = []
    @Published var didAutoSave: Bool = false
    
    private let userDefaultsKey = "recentBills"
    private let maxHistoryCount = 10
    private let autoSaveDelay: TimeInterval = 7.0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load bills synchronously on init (safe for small data)
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let bills = try? JSONDecoder().decode([SavedBill].self, from: data) {
            self.recentBills = bills
        }
        
        // Set up auto-save pipeline: saves after 10 seconds of idle time
        setupAutoSave()
    }
    
    /// Sets up Combine pipeline to auto-save after idle period
    private func setupAutoSave() {
        Publishers.CombineLatest4(
            $billAmountString,
            $selectedTipPercentage,
            $numberOfPeopleString,
            Publishers.CombineLatest3($roundUp, $customTipString, $isCustomTipSelected)
        )
        .dropFirst() // Skip the initial values on subscription
        .debounce(for: .seconds(autoSaveDelay), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.autoSaveBillIfNeeded()
        }
        .store(in: &cancellables)
    }
    
    var billValue: Double {
        Double(billAmountString) ?? 0.0
    }
    
    var effectiveTipPercentage: Double {
        if isCustomTipSelected {
            return Double(customTipString) ?? 0.0
        }
        return selectedTipPercentage
    }
    
    var tipAmountBeforeRounding: Double {
        billValue * (effectiveTipPercentage / 100.0)
    }
    
    var tipAmount: Double {
        if roundUp {
            return ceil(tipAmountBeforeRounding)
        }
        return tipAmountBeforeRounding
    }
    
    var totalAmount: Double {
        billValue + tipAmount
    }
    
    var numberOfPeopleValue: Int {
        max(1, Int(numberOfPeopleString) ?? 1)
    }
    
    var amountPerPerson: Double {
        guard numberOfPeopleValue > 0 else { return 0 }
        return totalAmount / Double(numberOfPeopleValue)
    }
    
    // MARK: - Lifetime Statistics
    
    /// Total tips paid across all saved bills
    var lifetimeTips: Double {
        recentBills.reduce(0) { $0 + $1.tipAmount }
    }
    
    /// Total amount spent across all saved bills (bill + tip)
    var lifetimeSpend: Double {
        recentBills.reduce(0) { $0 + $1.totalAmount }
    }
    
    /// Checks if current bill values match the most recently saved bill
    private var isDuplicateOfLastSave: Bool {
        guard let lastBill = recentBills.first else { return false }
        return lastBill.billAmount == billValue &&
               lastBill.tipPercentage == effectiveTipPercentage &&
               lastBill.numberOfPeople == numberOfPeopleValue
    }
    
    func selectTipPercentage(_ percentage: Double) {
        selectedTipPercentage = percentage
        isCustomTipSelected = false
    }
    
    func selectTipWithSentiment(_ percentage: Double, sentiment: String) {
        selectedTipPercentage = percentage
        selectedSentiment = sentiment
        isCustomTipSelected = false
    }
    
    func selectCustomTip() {
        isCustomTipSelected = true
        selectedSentiment = nil
    }
    
    // MARK: - Bill History Persistence
    
    /// Auto-saves the bill if valid and not a duplicate of the last save
    private func autoSaveBillIfNeeded() {
        guard billValue > 0, !isDuplicateOfLastSave else { return }
        saveBill()
        
        // Signal that an auto-save occurred
        didAutoSave = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.didAutoSave = false
        }
    }
    
    /// Saves the current bill calculation to history
    func saveBill() {
        guard billValue > 0 else { return }
        
        let savedBill = SavedBill(
            billAmount: billValue,
            tipPercentage: effectiveTipPercentage,
            tipAmount: tipAmount,
            totalAmount: totalAmount,
            numberOfPeople: numberOfPeopleValue,
            amountPerPerson: amountPerPerson
        )
        
        // Prepend new bill to array
        recentBills.insert(savedBill, at: 0)
        
        // Limit to max history count
        if recentBills.count > maxHistoryCount {
            recentBills = Array(recentBills.prefix(maxHistoryCount))
        }
        
        persistBills()
    }
    
    /// Deletes a bill at the specified index
    func deleteBill(at offsets: IndexSet) {
        recentBills.remove(atOffsets: offsets)
        persistBills()
    }
    
    /// Clears all saved bills from history
    func clearHistory() {
        recentBills.removeAll()
        persistBills()
    }
    
    /// Persists bills to UserDefaults
    private func persistBills() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentBills)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to encode saved bills: \(error)")
        }
    }
}

