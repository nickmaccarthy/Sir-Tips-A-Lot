//
//  TipProduct.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import Foundation

/// Defines the consumable In-App Purchase tip products
enum TipProduct: String, CaseIterable, Identifiable {
    case good = "nmac.TipCalculator.tip.service.good"
    case great = "nmac.TipCalculator.tip.service.great"
    case amazing = "nmac.TipCalculator.tip.service.amazing"

    var id: String { rawValue }

    /// Display name for the tip tier
    var displayName: String {
        switch self {
        case .good: return "Good Service"
        case .great: return "Great Service"
        case .amazing: return "AMAZING SERVICE!"
        }
    }

    /// Emoji for the tip tier
    var emoji: String {
        switch self {
        case .good: return "😀"
        case .great: return "😊"
        case .amazing: return "🤩"
        }
    }

    /// All product IDs as an array of strings
    static var allProductIDs: [String] {
        allCases.map { $0.rawValue }
    }
}


