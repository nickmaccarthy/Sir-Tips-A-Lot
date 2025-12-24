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
    @Published var recentBills: [SavedBill] = []
    
    private let userDefaultsKey = "recentBills"
    private let maxHistoryCount = 10
    
    init() {
        // Load bills synchronously on init (safe for small data)
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let bills = try? JSONDecoder().decode([SavedBill].self, from: data) {
            self.recentBills = bills
        }
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
    
    func selectTipPercentage(_ percentage: Double) {
        selectedTipPercentage = percentage
        isCustomTipSelected = false
    }
    
    func selectCustomTip() {
        isCustomTipSelected = true
    }
    
    // MARK: - Bill History Persistence
    
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

