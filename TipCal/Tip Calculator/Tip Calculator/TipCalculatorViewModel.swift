//
//  TipCalculatorViewModel.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TipCalculatorViewModel: ObservableObject {
    @Published var billAmountString: String = ""
    @Published var selectedTipPercentage: Double = 20.0
    @Published var roundUp: Bool = false
    @Published var numberOfPeopleString: String = "1"
    @Published var isCustomTipSelected: Bool = false
    @Published var customTipString: String = ""
    
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
}

