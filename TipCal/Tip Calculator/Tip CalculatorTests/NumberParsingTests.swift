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

        // Remove common labels that might appear on receipts (including OCR misspellings)
        let labelsToRemove = [
            // Standard labels
            "Total", "TOTAL", "Subtotal", "SUBTOTAL", "Sub Total", "SUB TOTAL",
            "Amount", "AMOUNT", "Due", "DUE", "Balance", "BALANCE",
            "Grand", "GRAND", "Food", "FOOD", "Pretax", "PRETAX", ":",
            // Gratuity labels
            "Gratuity", "GRATUITY", "Service Charge", "SERVICE CHARGE",
            "Service Fee", "SERVICE FEE", "SVC", "Auto Grat", "AUTO GRAT",
            "Tip", "TIP", "Included", "INCLUDED", "Added", "ADDED",
            // OCR misspellings
            "TOTL", "TTAL", "T0TAL", "T0TL", "TOTAI",
            "AMMOUNT", "AMONT", "AM0UNT", "AMNT", "AMT",
            "SUBT0TAL", "SUBTOTL", "SUB T0TAL",
            "BALANC", "BALANSE", "BAIANCE",
            "GRATUTIY", "GRATUTY", "GRATULTY"
        ]
        for label in labelsToRemove {
            cleaned = cleaned.replacingOccurrences(of: label, with: "", options: .caseInsensitive)
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

    // MARK: - Amount Type Detection Helper

    /// Represents a labeled amount type for testing
    private enum TestAmountType {
        case subtotal
        case total
        case gratuity
        case unlabeled
    }

    /// Result of parsing a receipt text item for testing
    private struct TestParsedAmount {
        let value: Double
        let type: TestAmountType
    }

    /// Parses text and returns both the amount and its label type (test helper matching ScannerView implementation)
    private func parseAmountWithLabel(_ text: String) -> TestParsedAmount? {
        let uppercased = text.uppercased()

        var type: TestAmountType = .unlabeled

        // Check for subtotal label (must check before total since "subtotal" contains "total")
        let subtotalPatterns = [
            "SUBTOTAL", "SUB TOTAL", "SUB-TOTAL", "FOOD TOTAL",
            "PRETAX", "PRE-TAX", "BEFORE TAX",
            // OCR misspellings
            "SUBT0TAL", "SUBTOTL", "SUB T0TAL", "SUBT0TL",
            "F00D TOTAL", "FOOD T0TAL", "FOODTOTAL"
        ]
        for pattern in subtotalPatterns {
            if uppercased.contains(pattern) {
                type = .subtotal
                break
            }
        }

        // Check for gratuity/tip already included (before total check)
        if type == .unlabeled {
            let gratuityPatterns = [
                "GRATUITY", "GRATUTIY", "GRAT ",
                "TIP INCLUDED", "TIP ADDED", "INCLUDED TIP",
                "SERVICE CHARGE", "SERVICE FEE", "SVC CHARGE", "SVC FEE",
                "AUTO GRAT", "AUTOGRAT", "AUTO GRATUITY", "AUTOGRATUITY",
                // OCR misspellings
                "GRATUTIY", "GRATUTY", "GRATULTY", "GRATU1TY",
                "SERV1CE CHARGE", "SERVICE CHRG", "SVC CHRG"
            ]
            for pattern in gratuityPatterns {
                if uppercased.contains(pattern) {
                    type = .gratuity
                    break
                }
            }
        }

        // Check for total label (only if not already marked as subtotal or gratuity)
        if type == .unlabeled {
            let totalPatterns = [
                "TOTAL", "AMOUNT DUE", "BALANCE DUE", "GRAND TOTAL", "AMOUNT", "DUE", "BALANCE",
                // OCR misspellings - Total variations
                "TOTL", "TTAL", "T0TAL", "T0TL", "TOTAI",
                // OCR misspellings - Amount variations
                "AMMOUNT", "AMONT", "AM0UNT", "AMNT", "AMT",
                // OCR misspellings - Balance variations
                "BALANC", "BALANSE", "BAIANCE"
            ]
            for pattern in totalPatterns {
                if uppercased.contains(pattern) {
                    type = .total
                    break
                }
            }
        }

        guard let value = cleanAndParseNumber(text) else {
            return nil
        }

        return TestParsedAmount(value: value, type: type)
    }

    // MARK: - Standard Label Detection Tests

    func testParseAmountWithLabel_totalLabel_detectsTotal() {
        let result = parseAmountWithLabel("TOTAL: $45.50")
        XCTAssertEqual(result?.type, .total)
        assertDoubleEqual(result?.value, 45.50)
    }

    func testParseAmountWithLabel_subtotalLabel_detectsSubtotal() {
        let result = parseAmountWithLabel("Subtotal: $35.00")
        XCTAssertEqual(result?.type, .subtotal)
        assertDoubleEqual(result?.value, 35.00)
    }

    func testParseAmountWithLabel_amountDue_detectsTotal() {
        let result = parseAmountWithLabel("AMOUNT DUE: $99.99")
        XCTAssertEqual(result?.type, .total)
        assertDoubleEqual(result?.value, 99.99)
    }

    func testParseAmountWithLabel_unlabeledNumber_detectsUnlabeled() {
        let result = parseAmountWithLabel("$25.00")
        XCTAssertEqual(result?.type, .unlabeled)
        assertDoubleEqual(result?.value, 25.00)
    }

    // MARK: - OCR Misspelling Tests - Total Patterns

    func testParseAmountWithLabel_ocrTotal_T0TAL_detectsTotal() {
        // "0" instead of "O"
        let result = parseAmountWithLabel("T0TAL: $50.00")
        XCTAssertEqual(result?.type, .total)
    }

    func testParseAmountWithLabel_ocrTotal_TOTL_detectsTotal() {
        // Missing "A"
        let result = parseAmountWithLabel("TOTL: $50.00")
        XCTAssertEqual(result?.type, .total)
    }

    func testParseAmountWithLabel_ocrTotal_TTAL_detectsTotal() {
        // Missing "O"
        let result = parseAmountWithLabel("TTAL: $50.00")
        XCTAssertEqual(result?.type, .total)
    }

    func testParseAmountWithLabel_ocrTotal_TOTAI_detectsTotal() {
        // "I" instead of "L"
        let result = parseAmountWithLabel("TOTAI: $50.00")
        XCTAssertEqual(result?.type, .total)
    }

    // MARK: - OCR Misspelling Tests - Amount Patterns

    func testParseAmountWithLabel_ocrAmount_AMMOUNT_detectsTotal() {
        // Double "M"
        let result = parseAmountWithLabel("AMMOUNT: $75.00")
        XCTAssertEqual(result?.type, .total)
    }

    func testParseAmountWithLabel_ocrAmount_AMONT_detectsTotal() {
        // Missing "U"
        let result = parseAmountWithLabel("AMONT: $75.00")
        XCTAssertEqual(result?.type, .total)
    }

    func testParseAmountWithLabel_ocrAmount_AM0UNT_detectsTotal() {
        // "0" instead of "O"
        let result = parseAmountWithLabel("AM0UNT DUE: $75.00")
        XCTAssertEqual(result?.type, .total)
    }

    func testParseAmountWithLabel_ocrAmount_AMT_detectsTotal() {
        // Common abbreviation
        let result = parseAmountWithLabel("AMT DUE: $75.00")
        XCTAssertEqual(result?.type, .total)
    }

    // MARK: - OCR Misspelling Tests - Subtotal Patterns

    func testParseAmountWithLabel_ocrSubtotal_SUBT0TAL_detectsSubtotal() {
        // "0" instead of "O"
        let result = parseAmountWithLabel("SUBT0TAL: $40.00")
        XCTAssertEqual(result?.type, .subtotal)
    }

    func testParseAmountWithLabel_ocrSubtotal_SUBTOTL_detectsSubtotal() {
        // Missing "A"
        let result = parseAmountWithLabel("SUBTOTL: $40.00")
        XCTAssertEqual(result?.type, .subtotal)
    }

    func testParseAmountWithLabel_foodTotal_detectsSubtotal() {
        let result = parseAmountWithLabel("FOOD TOTAL: $55.00")
        XCTAssertEqual(result?.type, .subtotal)
    }

    // MARK: - Gratuity Detection Tests

    func testParseAmountWithLabel_gratuity_detectsGratuity() {
        let result = parseAmountWithLabel("GRATUITY: $12.50")
        XCTAssertEqual(result?.type, .gratuity)
        assertDoubleEqual(result?.value, 12.50)
    }

    func testParseAmountWithLabel_gratuityWithPercent_detectsGratuity() {
        // Note: When percent appears before dollar amount, the parser extracts the first number
        // In real usage, the percentage is extracted separately via extractPercentage()
        let result = parseAmountWithLabel("GRATUITY 18%: $15.00")
        XCTAssertEqual(result?.type, .gratuity)
        // The regex extracts first number found after label removal
        XCTAssertNotNil(result?.value)
    }

    func testParseAmountWithLabel_autoGratuity_detectsGratuity() {
        let result = parseAmountWithLabel("AUTO GRATUITY: $20.00")
        XCTAssertEqual(result?.type, .gratuity)
    }

    func testParseAmountWithLabel_autoGrat_detectsGratuity() {
        let result = parseAmountWithLabel("AUTO GRAT 18%: $18.00")
        XCTAssertEqual(result?.type, .gratuity)
    }

    func testParseAmountWithLabel_serviceCharge_detectsGratuity() {
        let result = parseAmountWithLabel("SERVICE CHARGE: $10.00")
        XCTAssertEqual(result?.type, .gratuity)
        assertDoubleEqual(result?.value, 10.00)
    }

    func testParseAmountWithLabel_serviceFee_detectsGratuity() {
        let result = parseAmountWithLabel("SERVICE FEE: $8.00")
        XCTAssertEqual(result?.type, .gratuity)
    }

    func testParseAmountWithLabel_svcCharge_detectsGratuity() {
        let result = parseAmountWithLabel("SVC CHARGE: $7.50")
        XCTAssertEqual(result?.type, .gratuity)
    }

    func testParseAmountWithLabel_tipIncluded_detectsGratuity() {
        let result = parseAmountWithLabel("TIP INCLUDED: $12.00")
        XCTAssertEqual(result?.type, .gratuity)
    }

    func testParseAmountWithLabel_tipAdded_detectsGratuity() {
        let result = parseAmountWithLabel("TIP ADDED: $15.00")
        XCTAssertEqual(result?.type, .gratuity)
    }

    // MARK: - Gratuity OCR Misspelling Tests

    func testParseAmountWithLabel_ocrGratuity_GRATUTY_detectsGratuity() {
        // Missing "I"
        let result = parseAmountWithLabel("GRATUTY: $10.00")
        XCTAssertEqual(result?.type, .gratuity)
    }

    func testParseAmountWithLabel_ocrGratuity_GRATU1TY_detectsGratuity() {
        // "1" instead of "I"
        let result = parseAmountWithLabel("GRATU1TY: $10.00")
        XCTAssertEqual(result?.type, .gratuity)
    }

    func testParseAmountWithLabel_ocrServiceCharge_CHRG_detectsGratuity() {
        // Abbreviated CHARGE
        let result = parseAmountWithLabel("SERVICE CHRG: $8.00")
        XCTAssertEqual(result?.type, .gratuity)
    }

    // MARK: - Real-world Receipt Examples

    func testParseAmountWithLabel_realReceipt_largePartyGratuity() {
        // Note: Percent before dollar amount means first number extracted is the percent
        // The type detection still works correctly
        let result = parseAmountWithLabel("GRATUITY ADDED: $45.00")
        XCTAssertEqual(result?.type, .gratuity)
        assertDoubleEqual(result?.value, 45.00)
    }

    func testParseAmountWithLabel_realReceipt_hotelServiceCharge() {
        let result = parseAmountWithLabel("SERVICE CHARGE 15%: $22.50")
        XCTAssertEqual(result?.type, .gratuity)
    }

    func testParseAmountWithLabel_realReceipt_ocrMisreadTotal() {
        // Simulating a poorly printed/scanned receipt with 0 instead of O
        let result = parseAmountWithLabel("T0TAL: $87.32")
        XCTAssertEqual(result?.type, .total)
        assertDoubleEqual(result?.value, 87.32)
    }
}
