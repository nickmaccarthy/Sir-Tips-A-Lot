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
    let billAmount: Double
    let tipPercentage: Double
    let tipAmount: Double
    let totalAmount: Double
    let numberOfPeople: Int
    let amountPerPerson: Double

    /// The name of the location/restaurant where the bill was saved (e.g., "Joe's Pizza")
    let locationName: String?

    /// The sentiment emoji used when calculating the tip (e.g., "🤩")
    let sentiment: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        billAmount: Double,
        tipPercentage: Double,
        tipAmount: Double,
        totalAmount: Double,
        numberOfPeople: Int,
        amountPerPerson: Double,
        locationName: String? = nil,
        sentiment: String? = nil
    ) {
        self.id = id
        self.date = date
        self.billAmount = billAmount
        self.tipPercentage = tipPercentage
        self.tipAmount = tipAmount
        self.totalAmount = totalAmount
        self.numberOfPeople = numberOfPeople
        self.amountPerPerson = amountPerPerson
        self.locationName = locationName
        self.sentiment = sentiment
    }
}
