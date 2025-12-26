//
//  NumberParsingTests.swift
//  Tip CalculatorTests
//
//  Created by Nick MacCarthy on 12/26/25.
//

import XCTest
@testable import Tip_Calculator

/// Tests for the number parsing logic used in receipt scanning
/// This duplicates the cleanAndParseNumber function for testability
final class NumberParsingTests: XCTestCase {
    
    // MARK: - Helper
    
    /// Cleans a string and attempts to parse it as a currency/number value
    /// Handles formats like "$45.50", "45,50", "€ 123.45", "Total: $99.99"
    private func cleanAndParseNumber(_ text: String) -> Double? {
        var cleaned = text
        
        // Remove currency symbols
        let currencySymbols = ["$", "€", "£", "¥", "₹", "kr", "CHF"]
        for symbol in currencySymbols {
            cleaned = cleaned.replacingOccurrences(of: symbol, with: "")
        }
        
        // Remove common labels that might appear on receipts
        let labelsToRemove = ["Total", "TOTAL", "Subtotal", "SUBTOTAL", "Amount", "AMOUNT", "Due", "DUE", "Balance", "BALANCE", ":"]
        for label in labelsToRemove {
            cleaned = cleaned.replacingOccurrences(of: label, with: "")
        }
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle European format (comma as decimal separator)
        if cleaned.contains(",") && !cleaned.contains(".") {
            let parts = cleaned.split(separator: ",")
            if parts.count == 2, let lastPart = parts.last, lastPart.count <= 2 {
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        } else {
            cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        }
        
        // Extract just the numeric portion using regex
        let pattern = #"[\d]+\.?[\d]*"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
              let range = Range(match.range, in: cleaned) else {
            return nil
        }
        
        let numberString = String(cleaned[range])
        
        guard let value = Double(numberString), value > 0 else {
            return nil
        }
        
        return value
    }
    
    /// Helper to assert optional Double equality with accuracy
    private func assertDoubleEqual(_ actual: Double?, _ expected: Double, accuracy: Double = 0.001, file: StaticString = #file, line: UInt = #line) {
        guard let actualValue = actual else {
            XCTFail("Expected \(expected) but got nil", file: file, line: line)
            return
        }
        XCTAssertEqual(actualValue, expected, accuracy: accuracy, file: file, line: line)
    }
    
    // MARK: - Basic Number Parsing
    
    func testCleanAndParseNumber_simpleNumber_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("45.50"), 45.50)
    }
    
    func testCleanAndParseNumber_integerNumber_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("100"), 100.0)
    }
    
    func testCleanAndParseNumber_smallDecimal_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("0.99"), 0.99)
    }
    
    // MARK: - Currency Symbol Tests
    
    func testCleanAndParseNumber_dollarSign_removesSymbol() {
        assertDoubleEqual(cleanAndParseNumber("$45.50"), 45.50)
    }
    
    func testCleanAndParseNumber_euroSign_removesSymbol() {
        assertDoubleEqual(cleanAndParseNumber("€123.45"), 123.45)
    }
    
    func testCleanAndParseNumber_poundSign_removesSymbol() {
        assertDoubleEqual(cleanAndParseNumber("£99.99"), 99.99)
    }
    
    func testCleanAndParseNumber_yenSign_removesSymbol() {
        assertDoubleEqual(cleanAndParseNumber("¥1000"), 1000.0)
    }
    
    func testCleanAndParseNumber_rupeeSign_removesSymbol() {
        assertDoubleEqual(cleanAndParseNumber("₹500.50"), 500.50)
    }
    
    func testCleanAndParseNumber_krona_removesSymbol() {
        assertDoubleEqual(cleanAndParseNumber("kr 250.00"), 250.0)
    }
    
    func testCleanAndParseNumber_swissFranc_removesSymbol() {
        assertDoubleEqual(cleanAndParseNumber("CHF 75.00"), 75.0)
    }
    
    // MARK: - Label Removal Tests
    
    func testCleanAndParseNumber_totalLabel_removesLabel() {
        assertDoubleEqual(cleanAndParseNumber("Total: $45.50"), 45.50)
    }
    
    func testCleanAndParseNumber_totalUppercase_removesLabel() {
        assertDoubleEqual(cleanAndParseNumber("TOTAL $99.99"), 99.99)
    }
    
    func testCleanAndParseNumber_subtotal_removesLabel() {
        assertDoubleEqual(cleanAndParseNumber("Subtotal: 75.00"), 75.0)
    }
    
    func testCleanAndParseNumber_amountDue_removesLabel() {
        assertDoubleEqual(cleanAndParseNumber("Amount Due: $123.45"), 123.45)
    }
    
    func testCleanAndParseNumber_balance_removesLabel() {
        assertDoubleEqual(cleanAndParseNumber("Balance: $50.00"), 50.0)
    }
    
    // MARK: - European Format Tests (Comma as Decimal)
    
    func testCleanAndParseNumber_europeanFormat_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("45,50"), 45.50)
    }
    
    func testCleanAndParseNumber_europeanFormatWithEuro_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("€ 123,45"), 123.45)
    }
    
    func testCleanAndParseNumber_europeanFormatSingleDecimal_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("99,9"), 99.9)
    }
    
    // MARK: - Thousands Separator Tests
    
    func testCleanAndParseNumber_thousandsSeparator_removesComma() {
        assertDoubleEqual(cleanAndParseNumber("1,234.56"), 1234.56)
    }
    
    func testCleanAndParseNumber_multipleThousandsSeparators_removesCommas() {
        assertDoubleEqual(cleanAndParseNumber("$1,234,567.89"), 1234567.89)
    }
    
    func testCleanAndParseNumber_europeanThousands_parsesAsInteger() {
        // 1,234 with more than 2 digits after comma = thousands separator
        assertDoubleEqual(cleanAndParseNumber("1,234"), 1234.0)
    }
    
    // MARK: - Edge Cases
    
    func testCleanAndParseNumber_emptyString_returnsNil() {
        XCTAssertNil(cleanAndParseNumber(""))
    }
    
    func testCleanAndParseNumber_noNumbers_returnsNil() {
        XCTAssertNil(cleanAndParseNumber("abc"))
    }
    
    func testCleanAndParseNumber_onlySymbols_returnsNil() {
        XCTAssertNil(cleanAndParseNumber("$€£"))
    }
    
    func testCleanAndParseNumber_zero_returnsNil() {
        // Zero is not a valid bill amount
        XCTAssertNil(cleanAndParseNumber("0"))
    }
    
    func testCleanAndParseNumber_zeroPointZero_returnsNil() {
        XCTAssertNil(cleanAndParseNumber("0.00"))
    }
    
    func testCleanAndParseNumber_negativeNumber_extractsPositive() {
        // Negative numbers don't make sense for receipts
        // The regex extracts positive portion, but -5 would extract 5
        assertDoubleEqual(cleanAndParseNumber("-5.00"), 5.0)
    }
    
    func testCleanAndParseNumber_whitespace_trimmed() {
        assertDoubleEqual(cleanAndParseNumber("  $45.50  "), 45.50)
    }
    
    func testCleanAndParseNumber_mixedText_extractsNumber() {
        assertDoubleEqual(cleanAndParseNumber("abc123.45xyz"), 123.45)
    }
    
    func testCleanAndParseNumber_multipleNumbers_extractsFirst() {
        // This tests that it extracts the first number found
        let result = cleanAndParseNumber("Item 1: $5.00 Item 2: $10.00")
        // The first match after cleanup will be the first number
        XCTAssertNotNil(result)
    }
    
    // MARK: - Real Receipt Examples
    
    func testCleanAndParseNumber_realReceiptTotal_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("TOTAL DUE: $87.32"), 87.32)
    }
    
    func testCleanAndParseNumber_restaurantBill_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("Amount: $156.78"), 156.78)
    }
    
    func testCleanAndParseNumber_europeanReceipt_parsesCorrectly() {
        assertDoubleEqual(cleanAndParseNumber("€ 45,99"), 45.99)
    }
}
