//
//  Currency.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/28/25.
//

import Foundation

/// Supported currencies for the tip calculator
enum Currency: String, CaseIterable, Identifiable {
    case usd
    case eur
    case gbp
    case cad
    case aud
    case jpy
    case chf
    case mxn
    case inr

    var id: String { rawValue }

    /// ISO 4217 currency code (e.g., "USD", "EUR")
    var code: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        case .gbp: return "GBP"
        case .cad: return "CAD"
        case .aud: return "AUD"
        case .jpy: return "JPY"
        case .chf: return "CHF"
        case .mxn: return "MXN"
        case .inr: return "INR"
        }
    }

    /// Human-readable currency name
    var displayName: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .jpy: return "Japanese Yen"
        case .chf: return "Swiss Franc"
        case .mxn: return "Mexican Peso"
        case .inr: return "Indian Rupee"
        }
    }

    /// Currency symbol for display
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .cad: return "C$"
        case .aud: return "A$"
        case .jpy: return "¥"
        case .chf: return "CHF"
        case .mxn: return "MX$"
        case .inr: return "₹"
        }
    }

    /// Display label for picker (symbol + name)
    var pickerLabel: String {
        "\(symbol) - \(displayName)"
    }

    /// Creates a Currency from a raw value string, defaulting to USD if not found
    static func from(_ rawValue: String) -> Currency {
        Currency(rawValue: rawValue) ?? .usd
    }
}
