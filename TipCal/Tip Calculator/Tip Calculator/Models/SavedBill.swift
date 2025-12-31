//
//  SavedBill.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/23/25.
//

import Foundation

/// Represents a saved tip calculation for history persistence
struct SavedBill: Codable, Identifiable {
    let id: UUID
    let date: Date
    var billAmount: Double
    var tipPercentage: Double
    var tipAmount: Double
    var totalAmount: Double
    var numberOfPeople: Int
    var amountPerPerson: Double

    /// Tip amount per person when splitting (tipAmount / numberOfPeople)
    var tipPerPerson: Double

    /// The subtotal amount from the receipt (pre-tax, used for tip calculation)
    var subtotalAmount: Double?

    /// The receipt total (includes tax and other charges) - for display purposes
    var receiptTotal: Double?

    /// The name of the location/restaurant where the bill was saved (e.g., "Joe's Pizza")
    var locationName: String?

    /// The sentiment emoji used when calculating the tip (e.g., "🤩")
    var sentiment: String?

    /// Optional user notes about the bill (e.g., "Great birthday dinner!")
    var notes: String?

    /// Gratuity amount that was already included on the bill (detected from receipt)
    var includedGratuity: Double?

    /// Gratuity percentage that was already included on the bill (e.g., 18.0 for 18%)
    var includedGratuityPercentage: Double?

    // MARK: - Computed Properties

    /// Whether this bill had gratuity already included
    var hasIncludedGratuity: Bool {
        includedGratuity != nil && includedGratuity! > 0
    }

    /// Total tips including both included gratuity and additional tip
    var totalTips: Double {
        tipAmount + (includedGratuity ?? 0)
    }

    /// Whether this bill has both subtotal and total from receipt scanning
    var hasReceiptBreakdown: Bool {
        subtotalAmount != nil && receiptTotal != nil
    }

    /// The tax/other amount (difference between receipt total and subtotal)
    var taxAmount: Double? {
        guard let subtotal = subtotalAmount, let total = receiptTotal else { return nil }
        return total - subtotal
    }

    /// The final total including tip (receipt total + tip, or billAmount + tip)
    var grandTotal: Double {
        if let receiptTotal = receiptTotal {
            return receiptTotal + tipAmount
        }
        return totalAmount
    }

    // MARK: - CodingKeys for backward compatibility

    enum CodingKeys: String, CodingKey {
        case id, date, billAmount, tipPercentage, tipAmount, totalAmount
        case numberOfPeople, amountPerPerson, tipPerPerson
        case subtotalAmount, receiptTotal
        case locationName, sentiment, notes
        case includedGratuity, includedGratuityPercentage
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        billAmount: Double,
        tipPercentage: Double,
        tipAmount: Double,
        totalAmount: Double,
        numberOfPeople: Int,
        amountPerPerson: Double,
        tipPerPerson: Double? = nil,
        subtotalAmount: Double? = nil,
        receiptTotal: Double? = nil,
        locationName: String? = nil,
        sentiment: String? = nil,
        notes: String? = nil,
        includedGratuity: Double? = nil,
        includedGratuityPercentage: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.billAmount = billAmount
        self.tipPercentage = tipPercentage
        self.tipAmount = tipAmount
        self.totalAmount = totalAmount
        self.numberOfPeople = numberOfPeople
        self.amountPerPerson = amountPerPerson
        // Calculate tipPerPerson if not provided (backward compatibility)
        self.tipPerPerson = tipPerPerson ?? (numberOfPeople > 0 ? tipAmount / Double(numberOfPeople) : 0)
        self.subtotalAmount = subtotalAmount
        self.receiptTotal = receiptTotal
        self.locationName = locationName
        self.sentiment = sentiment
        self.notes = notes
        self.includedGratuity = includedGratuity
        self.includedGratuityPercentage = includedGratuityPercentage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        billAmount = try container.decode(Double.self, forKey: .billAmount)
        tipPercentage = try container.decode(Double.self, forKey: .tipPercentage)
        tipAmount = try container.decode(Double.self, forKey: .tipAmount)
        totalAmount = try container.decode(Double.self, forKey: .totalAmount)
        numberOfPeople = try container.decode(Int.self, forKey: .numberOfPeople)
        amountPerPerson = try container.decode(Double.self, forKey: .amountPerPerson)
        // Handle missing tipPerPerson for existing saved data
        tipPerPerson = try container.decodeIfPresent(Double.self, forKey: .tipPerPerson)
            ?? (numberOfPeople > 0 ? tipAmount / Double(numberOfPeople) : 0)
        subtotalAmount = try container.decodeIfPresent(Double.self, forKey: .subtotalAmount)
        receiptTotal = try container.decodeIfPresent(Double.self, forKey: .receiptTotal)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        sentiment = try container.decodeIfPresent(String.self, forKey: .sentiment)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        includedGratuity = try container.decodeIfPresent(Double.self, forKey: .includedGratuity)
        includedGratuityPercentage = try container.decodeIfPresent(Double.self, forKey: .includedGratuityPercentage)
    }

    // MARK: - Mutation Helpers

    /// Recalculates derived values (totalAmount, amountPerPerson, tipPerPerson) based on billAmount and tipAmount
    mutating func recalculateDerivedValues() {
        totalAmount = billAmount + tipAmount
        amountPerPerson = numberOfPeople > 0 ? totalAmount / Double(numberOfPeople) : 0
        tipPerPerson = numberOfPeople > 0 ? tipAmount / Double(numberOfPeople) : 0
    }

    /// Updates the tip based on a new percentage and recalculates derived values
    mutating func updateTipPercentage(_ newPercentage: Double) {
        tipPercentage = newPercentage
        tipAmount = billAmount * (tipPercentage / 100.0)
        recalculateDerivedValues()
    }

    /// Updates the bill amount and recalculates all related values
    mutating func updateBillAmount(_ newAmount: Double) {
        billAmount = newAmount
        tipAmount = billAmount * (tipPercentage / 100.0)
        recalculateDerivedValues()
    }

    /// Updates the number of people and recalculates per-person values
    mutating func updateNumberOfPeople(_ newCount: Int) {
        numberOfPeople = max(1, newCount)
        recalculateDerivedValues()
    }
}
