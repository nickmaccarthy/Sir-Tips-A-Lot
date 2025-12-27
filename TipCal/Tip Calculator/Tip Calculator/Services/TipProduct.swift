//
//  TipProduct.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import Foundation

/// Defines the consumable In-App Purchase tip products
enum TipProduct: String, CaseIterable, Identifiable {
    case small = "nmac.TipCalculator.tip.small"
    case medium = "nmac.TipCalculator.tip.medium"
    case large = "nmac.TipCalculator.tip.large"

    var id: String { rawValue }

    /// Display name for the tip tier
    var displayName: String {
        switch self {
        case .small: return "Good Service"
        case .medium: return "Great Service"
        case .large: return "AMAZING SERVICE!"
        }
    }

    /// Emoji for the tip tier
    var emoji: String {
        switch self {
        case .small: return "😀"
        case .medium: return "😊"
        case .large: return "🤩"
        }
    }

    /// All product IDs as an array of strings
    static var allProductIDs: [String] {
        allCases.map { $0.rawValue }
    }
}
