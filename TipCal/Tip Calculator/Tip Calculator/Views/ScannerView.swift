//
//  ScannerView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/23/25.
//

import SwiftUI
import VisionKit

// MARK: - Scanned Amount Types

/// Represents a labeled amount detected on a receipt
enum ScannedAmountType {
    case subtotal
    case total
    case tax
    case gratuity
    case unlabeled
}

/// Result of parsing a receipt text item
struct ParsedAmount {
    let value: Double
    let type: ScannedAmountType
}

/// Represents detected gratuity on a receipt
struct DetectedGratuity: Equatable {
    let amount: Double
    let percentage: Double?  // If we can detect "18%" etc.
    let label: String        // Original text like "18% Gratuity"
}

/// Result containing both subtotal and total when detected
struct ScannedBillAmounts {
    let subtotal: Double?
    let total: Double?
    let gratuity: DetectedGratuity?

    var hasSubtotal: Bool { subtotal != nil }
    var hasTotal: Bool { total != nil }
    var hasGratuity: Bool { gratuity != nil }
    var hasBoth: Bool { subtotal != nil && total != nil }
}

/// Result struct for amounts selected callback
struct SelectedAmounts {
    let subtotal: Double?
    let total: Double?
    let gratuity: DetectedGratuity?
}

/// A SwiftUI wrapper for VisionKit's DataScannerViewController
/// Enables receipt scanning with text detection, highlighting, and tap-to-capture
struct ScannerView: UIViewControllerRepresentable {
    /// Callback when a valid number is scanned and tapped by the user
    let onNumberScanned: (Double) -> Void

    /// Callback when labeled amounts are detected (subtotal/total)
    let onAmountsDetected: ((ScannedBillAmounts) -> Void)?

    /// Environment dismiss action to close the scanner
    @Environment(\.dismiss) private var dismiss

    init(onNumberScanned: @escaping (Double) -> Void, onAmountsDetected: ((ScannedBillAmounts) -> Void)? = nil) {
        self.onNumberScanned = onNumberScanned
        self.onAmountsDetected = onAmountsDetected
    }

    // MARK: - Availability Checks

    /// Whether the device supports DataScanner (requires iOS 16+ and specific hardware)
    static var isDeviceSupported: Bool {
        DataScannerViewController.isSupported
    }

    /// Whether scanning is currently available (camera permissions granted, not restricted)
    static var isScanningAvailable: Bool {
        DataScannerViewController.isAvailable
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator

        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning if not already running
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onNumberScanned: onNumberScanned, onAmountsDetected: onAmountsDetected, dismiss: dismiss)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onNumberScanned: (Double) -> Void
        let onAmountsDetected: ((ScannedBillAmounts) -> Void)?
        let dismiss: DismissAction

        // Detection history for consensus
        private var subtotalHistory: [Double] = []
        private var totalHistory: [Double] = []
        private var gratuityHistory: [(amount: Double, percentage: Double?, label: String)] = []
        private var lastNotifiedAmounts: ScannedBillAmounts?

        // Consensus detection settings
        private let maxHistorySize = 5
        private let valueTolerance: Double = 0.10
        private let maxReasonableAmount: Double = 1000.0

        // Tracked consensus values
        private var consensusSubtotal: Double?
        private var consensusTotal: Double?
        private var consensusGratuity: DetectedGratuity?

        init(onNumberScanned: @escaping (Double) -> Void, onAmountsDetected: ((ScannedBillAmounts) -> Void)?, dismiss: DismissAction) {
            self.onNumberScanned = onNumberScanned
            self.onAmountsDetected = onAmountsDetected
            self.dismiss = dismiss
        }

        // MARK: - DataScannerViewControllerDelegate

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processRecognizedItems(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processRecognizedItems(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if allItems.isEmpty {
                clearDetectionState()
            } else {
                processRecognizedItems(allItems)
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):
                // Attempt to parse the tapped text as a number
                if let parsed = parseAmountWithLabel(text.transcript) {
                    // Provide haptic feedback on successful capture
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    // Return the parsed value
                    onNumberScanned(parsed.value)

                    // Dismiss the scanner
                    dismiss()
                } else {
                    // Haptic feedback for invalid selection
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                }
            default:
                break
            }
        }

        /// Clears all detection state
        private func clearDetectionState() {
            subtotalHistory.removeAll()
            totalHistory.removeAll()
            gratuityHistory.removeAll()
            consensusSubtotal = nil
            consensusTotal = nil
            consensusGratuity = nil
            lastNotifiedAmounts = nil
        }

        // MARK: - Amount Detection

        /// Processes all recognized items to find subtotal, total, and gratuity amounts
        private func processRecognizedItems(_ items: [RecognizedItem]) {
            var frameSubtotals: [Double] = []
            var frameTotals: [Double] = []
            var frameGratuities: [(amount: Double, percentage: Double?, label: String)] = []
            var unlabeledAmounts: [Double] = []
            var hasLabelBlock = false
            var hasGratuityLabel = false
            var tipSuggestionAmounts: Set<Double> = [] // Amounts to blacklist from tip table
            var allTranscripts: [String] = [] // Collect all text for analysis

            // First pass: collect all transcripts and identify tip suggestion table amounts
            for item in items {
                if case .text(let text) = item {
                    allTranscripts.append(text.transcript)
                }
            }

            // Detect tip suggestion table amounts to blacklist
            tipSuggestionAmounts = detectTipSuggestionAmounts(from: allTranscripts)

            for item in items {
                if case .text(let text) = item {
                    let transcript = text.transcript

                    // Skip tip suggestion lines entirely
                    if isSuggestedTipLine(transcript) {
                        continue
                    }

                    // Skip item lines (start with quantity like "1 ", "2 ")
                    if isItemLine(transcript) {
                        continue
                    }

                    // Check if this block has labels
                    let hasLabels = transcript.uppercased().contains("SUBTOTAL") ||
                                    transcript.uppercased().contains("TOTAL") ||
                                    transcript.uppercased().contains("GRATUITY")
                    let hasNumbers = transcript.range(of: #"\d+\.\d{2}"#, options: .regularExpression) != nil

                    // Track gratuity labels
                    let gratuityKeywords = ["GRATUITY", "GRAT ", "TIP INCLUDED", "SERVICE CHARGE", "AUTO GRAT"]
                    for keyword in gratuityKeywords {
                        if transcript.uppercased().contains(keyword) {
                            hasGratuityLabel = true
                            break
                        }
                    }

                    // Skip labels-only blocks (no numbers)
                    if hasLabels && !hasNumbers {
                        hasLabelBlock = true
                        continue
                    }

                    if let parsed = parseAmountWithLabel(transcript) {
                        guard isReasonableAmount(parsed.value) else { continue }

                        // Skip amounts that are blacklisted from tip suggestion table
                        if tipSuggestionAmounts.contains(where: { abs($0 - parsed.value) < 0.01 }) {
                            continue
                        }

                        switch parsed.type {
                        case .subtotal:
                            frameSubtotals.append(parsed.value)
                        case .total:
                            frameTotals.append(parsed.value)
                        case .gratuity:
                            guard parsed.value >= 1.0 else { continue }
                            let percentage = extractPercentage(from: transcript)
                            frameGratuities.append((parsed.value, percentage, transcript))
                        case .tax:
                            break // Tax detected but not used directly
                        case .unlabeled:
                            // Extract ALL currency amounts from unlabeled blocks
                            let allAmounts = extractAllCurrencyAmounts(from: transcript)
                            if !allAmounts.isEmpty {
                                let isPromoText = transcript.lowercased().contains("prix") ||
                                                  transcript.lowercased().contains("offer") ||
                                                  transcript.lowercased().contains("special") ||
                                                  transcript.lowercased().contains("join us")
                                if !isPromoText {
                                    for amount in allAmounts where isReasonableAmount(amount) {
                                        // Skip blacklisted amounts
                                        if !tipSuggestionAmounts.contains(where: { abs($0 - amount) < 0.01 }) {
                                            unlabeledAmounts.append(amount)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Validate: if we have both subtotal and total, subtotal should be < total
            if let subtotal = frameSubtotals.first, let total = frameTotals.first {
                if subtotal > total {
                    // Something is wrong - likely picked up wrong amounts
                    // Try to swap if it makes more sense
                    if subtotal > total * 0.8 && subtotal < total * 1.5 {
                        // Close enough, might be swapped - use smaller as subtotal
                        frameSubtotals = [min(subtotal, total)]
                        frameTotals = [max(subtotal, total)]
                    }
                }
            }

            // Apply heuristics if we have labels in one block and amounts in another
            if hasLabelBlock && !unlabeledAmounts.isEmpty && frameSubtotals.isEmpty && frameTotals.isEmpty {
                applyHeuristics(unlabeledAmounts: unlabeledAmounts,
                               hasGratuityLabel: hasGratuityLabel,
                               frameSubtotals: &frameSubtotals,
                               frameTotals: &frameTotals,
                               frameGratuities: &frameGratuities)
            }

            // Add to history
            addToHistory(subtotals: frameSubtotals, totals: frameTotals, gratuities: frameGratuities)

            // Calculate consensus
            consensusSubtotal = findConsensusValue(from: subtotalHistory)
            consensusTotal = findConsensusValue(from: totalHistory)
            consensusGratuity = findConsensusGratuity()

            // Notify if we have new amounts
            let amounts = ScannedBillAmounts(subtotal: consensusSubtotal, total: consensusTotal, gratuity: consensusGratuity)
            if amounts.hasSubtotal || amounts.hasTotal || amounts.hasGratuity {
                if lastNotifiedAmounts?.subtotal != amounts.subtotal ||
                   lastNotifiedAmounts?.total != amounts.total ||
                   lastNotifiedAmounts?.gratuity != amounts.gratuity {
                    lastNotifiedAmounts = amounts
                    DispatchQueue.main.async {
                        self.onAmountsDetected?(amounts)
                    }
                }
            }
        }

        // MARK: - Heuristics

        /// Applies heuristics to classify unlabeled amounts
        private func applyHeuristics(unlabeledAmounts: [Double], hasGratuityLabel: Bool,
                                    frameSubtotals: inout [Double], frameTotals: inout [Double],
                                    frameGratuities: inout [(amount: Double, percentage: Double?, label: String)]) {
            guard let maxAmount = unlabeledAmounts.max() else { return }

            var bestSubtotal: Double?
            var bestGratuity: Double?

            // Only look for gratuity if we saw a gratuity label
            if hasGratuityLabel {
                for potentialSubtotal in unlabeledAmounts where potentialSubtotal != maxAmount {
                    let subtotalRatio = potentialSubtotal / maxAmount
                    guard subtotalRatio > 0.5 && subtotalRatio < 0.95 else { continue }

                    for potentialGratuity in unlabeledAmounts where potentialGratuity != maxAmount && potentialGratuity != potentialSubtotal {
                        let gratRatio = potentialGratuity / potentialSubtotal
                        guard gratRatio >= 0.10 && gratRatio <= 0.35 else { continue }

                        for potentialTax in unlabeledAmounts where potentialTax != maxAmount && potentialTax != potentialSubtotal && potentialTax != potentialGratuity {
                            let calculatedTotal = potentialSubtotal + potentialGratuity + potentialTax
                            let tolerance = maxAmount * 0.05
                            if abs(calculatedTotal - maxAmount) <= tolerance {
                                bestSubtotal = potentialSubtotal
                                bestGratuity = potentialGratuity
                                break
                            }
                        }
                        if bestSubtotal != nil { break }
                    }
                    if bestSubtotal != nil { break }
                }
            }

            // If no gratuity match, look for subtotal + tax = total
            if bestSubtotal == nil {
                for potentialSubtotal in unlabeledAmounts where potentialSubtotal != maxAmount {
                    let subtotalRatio = potentialSubtotal / maxAmount
                    guard subtotalRatio > 0.5 && subtotalRatio < 0.98 else { continue }

                    for potentialTax in unlabeledAmounts where potentialTax != maxAmount && potentialTax != potentialSubtotal {
                        let taxRatio = potentialTax / potentialSubtotal
                        guard taxRatio >= 0.03 && taxRatio <= 0.25 else { continue }

                        let calculatedTotal = potentialSubtotal + potentialTax
                        let tolerance = maxAmount * 0.05
                        if abs(calculatedTotal - maxAmount) <= tolerance {
                            bestSubtotal = potentialSubtotal
                            break
                        }
                    }
                    if bestSubtotal != nil { break }
                }
            }

            // Apply found values only if they pass validation
            if let subtotal = bestSubtotal {
                // Final validation: subtotal must be less than total
                if subtotal < maxAmount {
                    frameSubtotals.append(subtotal)
                    frameTotals.append(maxAmount)
                    if let gratuity = bestGratuity {
                        let percentage = (gratuity / subtotal) * 100
                        frameGratuities.append((gratuity, percentage, ""))
                    }
                }
            } else {
                // More conservative fallback: only use if amounts are reasonable
                // Look for the second largest that's 80-98% of max (typical subtotal ratio with tax)
                let sortedAmounts = unlabeledAmounts.sorted(by: >)
                if sortedAmounts.count >= 2 {
                    let largest = sortedAmounts[0]
                    let secondLargest = sortedAmounts[1]
                    let ratio = secondLargest / largest

                    // Only accept if ratio is in the expected subtotal/total range (80-98%)
                    // This accounts for typical 2-20% tax rates
                    if ratio > 0.80 && ratio < 0.98 {
                        frameSubtotals.append(secondLargest)
                        frameTotals.append(largest)
                    } else if ratio > 0.98 {
                        // Very close amounts - likely same value detected twice, use the larger
                        frameTotals.append(largest)
                    }
                    // If ratio < 0.80, don't use heuristics - the amounts are too different
                    // to be subtotal/total pair
                } else if sortedAmounts.count == 1 {
                    // Only one amount - could be total
                    frameTotals.append(sortedAmounts[0])
                }
            }
        }

        // MARK: - Consensus Helpers

        private func isReasonableAmount(_ value: Double) -> Bool {
            return value >= 0.01 && value <= maxReasonableAmount
        }

        private func addToHistory(subtotals: [Double], totals: [Double], gratuities: [(amount: Double, percentage: Double?, label: String)]) {
            subtotalHistory.append(contentsOf: subtotals)
            totalHistory.append(contentsOf: totals)
            gratuityHistory.append(contentsOf: gratuities)

            if subtotalHistory.count > maxHistorySize {
                subtotalHistory = Array(subtotalHistory.suffix(maxHistorySize))
            }
            if totalHistory.count > maxHistorySize {
                totalHistory = Array(totalHistory.suffix(maxHistorySize))
            }
            if gratuityHistory.count > maxHistorySize {
                gratuityHistory = Array(gratuityHistory.suffix(maxHistorySize))
            }
        }

        private func findConsensusValue(from history: [Double]) -> Double? {
            guard !history.isEmpty else { return nil }

            var groups: [(value: Double, count: Int)] = []
            for value in history {
                if let index = groups.firstIndex(where: { abs($0.value - value) <= valueTolerance }) {
                    let existing = groups[index]
                    let newCount = existing.count + 1
                    let newValue = (existing.value * Double(existing.count) + value) / Double(newCount)
                    groups[index] = (newValue, newCount)
                } else {
                    groups.append((value, 1))
                }
            }

            return groups.max(by: { $0.count < $1.count })?.value
        }

        private func findConsensusGratuity() -> DetectedGratuity? {
            guard !gratuityHistory.isEmpty else { return nil }
            let amounts = gratuityHistory.map { $0.amount }
            guard let consensusAmount = findConsensusValue(from: amounts) else { return nil }

            if let match = gratuityHistory.first(where: { abs($0.amount - consensusAmount) <= valueTolerance }) {
                return DetectedGratuity(amount: consensusAmount, percentage: match.percentage, label: match.label)
            }
            return DetectedGratuity(amount: consensusAmount, percentage: nil, label: "")
        }

        private func extractPercentage(from text: String) -> Double? {
            let pattern = #"(\d+(?:\.\d+)?)\s*%"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return Double(text[range])
        }

        // MARK: - Number Parsing

        /// Detects amounts from tip suggestion tables that should be blacklisted
        private func detectTipSuggestionAmounts(from transcripts: [String]) -> Set<Double> {
            var blacklistedAmounts: Set<Double> = []

            // Combine all transcripts for pattern matching
            let fullText = transcripts.joined(separator: "\n").uppercased()

            // Check if there's a tip suggestion table
            let hasTipTableHeader = fullText.contains("TIP") && fullText.contains("AMOUNT") && fullText.contains("TOTAL")
            let hasPercentageRows = fullText.range(of: #"(15|18|20|22|25|30)\s*%"#, options: .regularExpression) != nil

            // If we detect a tip table, extract amounts from percentage rows
            if hasTipTableHeader || hasPercentageRows {
                for transcript in transcripts {
                    let upper = transcript.uppercased()

                    // Look for rows with percentages (15%, 18%, 20%, etc.)
                    if upper.range(of: #"^\s*(15|18|20|22|25|30)\s*%"#, options: .regularExpression) != nil {
                        // This is a tip suggestion row - blacklist all amounts in it
                        let amounts = extractAllCurrencyAmounts(from: transcript)
                        for amount in amounts {
                            blacklistedAmounts.insert(amount)
                        }
                    }

                    // Also check for amounts in lines with percentages mid-text
                    if upper.contains("%") && upper.range(of: #"(15|18|20|22|25|30)\s*%"#, options: .regularExpression) != nil {
                        // Has common tip percentages
                        let amounts = extractAllCurrencyAmounts(from: transcript)
                        // If there are 2+ amounts on a line with a tip percentage, it's likely a tip table row
                        if amounts.count >= 2 {
                            for amount in amounts {
                                blacklistedAmounts.insert(amount)
                            }
                        }
                    }
                }
            }

            // Also blacklist amounts from explicit tip suggestion lines
            for transcript in transcripts {
                if isSuggestedTipLine(transcript) {
                    let amounts = extractAllCurrencyAmounts(from: transcript)
                    for amount in amounts {
                        blacklistedAmounts.insert(amount)
                    }
                }
            }

            return blacklistedAmounts
        }

        /// Checks if text is a menu item line (quantity + item name + price)
        private func isItemLine(_ text: String) -> Bool {
            // Pattern: starts with small number (1-9) followed by space and text
            // e.g., "1  Tendril IPA  $8.33" or "2  Soda Water  $5.56"
            let itemPattern = #"^\s*[1-9]\s+[A-Za-z]"#
            if let regex = try? NSRegularExpression(pattern: itemPattern),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                // Verify it has a price at the end (item line pattern)
                if text.contains("$") || text.range(of: #"\d+\.\d{2}$"#, options: .regularExpression) != nil {
                    return true
                }
            }
            return false
        }

        /// Checks if text is a suggested tip line (not actual gratuity)
        private func isSuggestedTipLine(_ text: String) -> Bool {
            let uppercased = text.uppercased()

            // Pattern 1: "+X% Tip $Y Total $Z" format
            if uppercased.contains("+") && uppercased.contains("%") &&
               uppercased.contains("TIP") && uppercased.contains("TOTAL") {
                return true
            }

            // Pattern 2: "Suggested Tip/Gratuity" header
            if uppercased.contains("SUGGESTED") && (uppercased.contains("TIP") || uppercased.contains("GRATUITY")) {
                return true
            }

            // Pattern 3: Tip suggestion table header "Tip Amount Total"
            if (uppercased.contains("TIP") && uppercased.contains("AMOUNT") && uppercased.contains("TOTAL")) {
                return true
            }

            // Pattern 4: Line starts with common tip percentages (15%, 18%, 20%, 22%, 25%, 30%)
            // and contains dollar amounts - this is a tip suggestion row
            let tipPercentagePattern = #"^\s*(15|18|20|22|25|30)\s*%"#
            if let regex = try? NSRegularExpression(pattern: tipPercentagePattern, options: .caseInsensitive),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                // Check if it also has dollar amounts (tip suggestion row)
                if text.contains("$") {
                    return true
                }
            }

            // Pattern 5: Contains multiple dollar amounts with a percentage (tip table row)
            // e.g., "18%   $6.66   $44.78"
            let dollarCount = text.components(separatedBy: "$").count - 1
            let hasPercentage = text.contains("%")
            if dollarCount >= 2 && hasPercentage {
                return true
            }

            // Pattern 6: "To cover the cost" explanatory text about tips/surcharges
            if uppercased.contains("TO COVER") || uppercased.contains("WON'T BE SURCHARGED") {
                return true
            }

            return false
        }

        /// Parses text and returns both the amount and its label type
        func parseAmountWithLabel(_ text: String) -> ParsedAmount? {
            let uppercased = text.uppercased()

            // Skip suggested tip lines
            if isSuggestedTipLine(uppercased) {
                return nil
            }

            var type: ScannedAmountType = .unlabeled

            // Check for subtotal
            let subtotalPatterns = [
                "SUBTOTAL", "SUB TOTAL", "SUB-TOTAL", "SUB TOT", "SUB TOT:",
                "FOOD TOTAL", "FOOD & BEV", "ITEMS TOTAL",
                "PRETAX", "PRE-TAX", "BEFORE TAX"
            ]
            for pattern in subtotalPatterns {
                if uppercased.contains(pattern) {
                    type = .subtotal
                    break
                }
            }

            // Check for tax (must check before total to handle "Total Taxes")
            if type == .unlabeled {
                let taxPatterns = [
                    "TOTAL TAX", "TOTAL TAXES", "TAX:", "TAX ", " TAX",
                    "SALES TAX", "STATE TAX", "HST:", "GST:", "PST:", "VAT:",
                    "TAXES:"
                ]
                for pattern in taxPatterns {
                    if uppercased.contains(pattern) {
                        type = .tax
                        break
                    }
                }
            }

            // Check for surcharge (treat like tax)
            if type == .unlabeled {
                let surchargePatterns = ["SURCHARGE", "CARD FEE", "CC FEE", "CREDIT CARD FEE"]
                for pattern in surchargePatterns {
                    if uppercased.contains(pattern) {
                        type = .tax // Treat surcharges like tax
                        break
                    }
                }
            }

            // Check for gratuity (requires currency amount)
            if type == .unlabeled {
                let gratuityPatterns = [
                    "GRATUITY", "GRAT ", "TIP INCLUDED", "TIP ADDED",
                    "SERVICE CHARGE", "SERVICE FEE", "AUTO GRAT"
                ]
                var hasGratuityKeyword = false
                for pattern in gratuityPatterns {
                    if uppercased.contains(pattern) {
                        hasGratuityKeyword = true
                        break
                    }
                }
                if hasGratuityKeyword {
                    let hasCurrency = text.range(of: #"[$€£¥₹]\s*\d+(\.\d{1,2})?"#, options: .regularExpression) != nil
                    let hasDecimal = text.range(of: #"\d+\.\d{2}"#, options: .regularExpression) != nil
                    if hasCurrency || hasDecimal {
                        type = .gratuity
                    }
                }
            }

            // Check for total (but NOT "Total Tax" or "Total Taxes" - already handled above)
            if type == .unlabeled {
                // First check for explicit total patterns that shouldn't be confused
                let explicitTotalPatterns = [
                    "TOTAL DUE", "AMOUNT DUE", "BALANCE DUE", "GRAND TOTAL",
                    "CREDIT CARD AUTH", "CARD AUTH", "CHARGE TOTAL"
                ]
                for pattern in explicitTotalPatterns {
                    if uppercased.contains(pattern) {
                        type = .total
                        break
                    }
                }

                // Then check for simple "TOTAL" but exclude tax-related
                if type == .unlabeled && uppercased.contains("TOTAL") {
                    // Make sure it's not a tax line
                    if !uppercased.contains("TAX") {
                        type = .total
                    }
                }

                // Check other total patterns
                if type == .unlabeled {
                    let otherTotalPatterns = ["AMOUNT", "BALANCE", "DUE"]
                    for pattern in otherTotalPatterns {
                        if uppercased.contains(pattern) {
                            type = .total
                            break
                        }
                    }
                }
            }

            // For labeled amounts, extract the amount NEAR the label, not just the first amount
            let value: Double?
            if type != .unlabeled {
                value = extractAmountNearLabel(text: text, type: type)
            } else {
                value = cleanAndParseNumber(text)
            }

            guard let finalValue = value else {
                return nil
            }

            // Minimum amount validation based on type
            // Subtotals and totals should be reasonable amounts (not $1)
            if type == .subtotal && finalValue < 5.0 {
                return nil // Skip suspiciously low subtotals
            }
            if type == .total && finalValue < 5.0 {
                return nil // Skip suspiciously low totals
            }

            return ParsedAmount(value: finalValue, type: type)
        }

        /// Extracts the amount that appears near/after a label in the text
        private func extractAmountNearLabel(text: String, type: ScannedAmountType) -> Double? {
            let uppercased = text.uppercased()

            // Find which label pattern matched
            var labelPatterns: [String] = []
            switch type {
            case .subtotal:
                labelPatterns = ["SUBTOTAL", "SUB TOTAL", "SUB-TOTAL", "SUB TOT"]
            case .total:
                labelPatterns = ["TOTAL DUE", "AMOUNT DUE", "BALANCE DUE", "GRAND TOTAL",
                                "CREDIT CARD AUTH", "CARD AUTH", "TOTAL"]
            case .tax:
                labelPatterns = ["TOTAL TAX", "TOTAL TAXES", "TAX", "SALES TAX", "STATE TAX"]
            case .gratuity:
                labelPatterns = ["GRATUITY", "SERVICE CHARGE", "TIP INCLUDED", "AUTO GRAT"]
            case .unlabeled:
                return cleanAndParseNumber(text)
            }

            // Find the position of the label
            var labelEndIndex: String.Index? = nil
            for pattern in labelPatterns {
                if let range = uppercased.range(of: pattern) {
                    labelEndIndex = range.upperBound
                    break
                }
            }

            // If we found the label, look for amounts AFTER it
            if let labelEnd = labelEndIndex {
                let textAfterLabel = String(text[labelEnd...])

                // Try to find a currency amount after the label
                let currencyPattern = #"[$€£¥₹]\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)"#
                if let regex = try? NSRegularExpression(pattern: currencyPattern),
                   let match = regex.firstMatch(in: textAfterLabel, range: NSRange(textAfterLabel.startIndex..., in: textAfterLabel)),
                   let amountRange = Range(match.range(at: 1), in: textAfterLabel) {
                    let amountString = String(textAfterLabel[amountRange]).replacingOccurrences(of: ",", with: "")
                    if let value = Double(amountString), value > 0 {
                        return value
                    }
                }

                // Also try decimal pattern without currency symbol (for some receipts)
                let decimalPattern = #"(\d+\.\d{2})"#
                if let regex = try? NSRegularExpression(pattern: decimalPattern),
                   let match = regex.firstMatch(in: textAfterLabel, range: NSRange(textAfterLabel.startIndex..., in: textAfterLabel)),
                   let amountRange = Range(match.range(at: 1), in: textAfterLabel) {
                    let amountString = String(textAfterLabel[amountRange])
                    if let value = Double(amountString), value > 0 {
                        return value
                    }
                }
            }

            // Fallback: if the text is short (single line with label + amount), use standard parsing
            // But prefer the LAST amount (usually the one on the same line as the label)
            let allAmounts = extractAllCurrencyAmounts(from: text)
            if !allAmounts.isEmpty {
                return allAmounts.last // Return last amount (usually near the label at end of block)
            }

            return cleanAndParseNumber(text)
        }

        /// Extracts ALL currency amounts from a text block
        private func extractAllCurrencyAmounts(from text: String) -> [Double] {
            var amounts: [Double] = []
            let pattern = #"[$€£¥₹]\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return amounts }

            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)

            for match in matches {
                if let amountRange = Range(match.range(at: 1), in: text) {
                    let amountString = String(text[amountRange]).replacingOccurrences(of: ",", with: "")
                    if let value = Double(amountString), value > 0 {
                        amounts.append(value)
                    }
                }
            }
            return amounts
        }

        /// Cleans a string and attempts to parse it as a currency/number value
        func cleanAndParseNumber(_ text: String) -> Double? {
            var cleaned = text

            // Try currency pattern first
            let currencyPatterns = [
                #"[$€£¥₹]\s*(\d+(?:,\d{3})*\.\d{2})"#,
                #"[$€£¥₹]\s*(\d+(?:,\d{3})*)"#,
                #"\$\s*(\d+\.\d{2})"#
            ]
            for pattern in currencyPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                   let range = Range(match.range(at: 1), in: text) {
                    let amountString = String(text[range]).replacingOccurrences(of: ",", with: "")
                    if let value = Double(amountString), value > 0 {
                        return value
                    }
                }
            }

            // Remove percentage patterns
            let percentagePattern = #"\(?\d+(?:\.\d+)?%\)?"#
            if let percentRegex = try? NSRegularExpression(pattern: percentagePattern) {
                cleaned = percentRegex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
            }

            // Remove currency symbols
            let currencySymbols = ["$", "€", "£", "¥", "₹", "kr", "CHF"]
            for symbol in currencySymbols {
                cleaned = cleaned.replacingOccurrences(of: symbol, with: "")
            }

            // Remove labels
            let labelsToRemove = [
                "Total", "TOTAL", "Subtotal", "SUBTOTAL", "Sub Total", "SUB TOTAL",
                "Amount", "AMOUNT", "Due", "DUE", "Balance", "BALANCE",
                "Gratuity", "GRATUITY", "Service Charge", "SERVICE CHARGE",
                "Tip", "TIP", ":"
            ]
            for label in labelsToRemove {
                cleaned = cleaned.replacingOccurrences(of: label, with: "", options: .caseInsensitive)
            }

            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

            // Handle European format
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
    }
}

// MARK: - Scanner Container View

/// A container view that handles availability checks and provides fallback UI
struct ScannerContainerView: View {
    /// Callback when amounts are selected (subtotal and/or total)
    let onAmountsSelected: (SelectedAmounts) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var detectedAmounts: ScannedBillAmounts?
    @State private var showGratuityConfirmation = false

    var body: some View {
        ZStack {
            if ScannerView.isDeviceSupported && ScannerView.isScanningAvailable {
                ScannerView(
                    onNumberScanned: { amount in
                        // Manual tap: use as subtotal
                        selectAmounts(subtotal: amount, total: nil, gratuity: nil)
                    },
                    onAmountsDetected: { amounts in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            detectedAmounts = amounts
                        }
                    }
                )
                .ignoresSafeArea()

                // Overlay UI
                VStack(spacing: 0) {
                    // Top bar with close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.white, .black.opacity(0.5))
                        }
                        .padding()
                    }

                    Spacer()

                    // Bottom area: detected amounts or instructions
                    VStack(spacing: 12) {
                        if let amounts = detectedAmounts {
                            // Detected amounts banner
                            detectedAmountsBanner(amounts)
                        } else {
                            // Instructions banner
                            instructionsBanner
                        }
                    }
                    .padding(.bottom, 40)
                }
            } else {
                UnsupportedScannerView(dismiss: dismiss)
            }
        }
        .alert("Gratuity Already Included", isPresented: $showGratuityConfirmation) {
            Button("Got It") { }
        } message: {
            if let gratuity = detectedAmounts?.gratuity {
                let percentText = gratuity.percentage.map { String(format: "%.0f%%", $0) } ?? ""
                Text("This receipt includes a \(percentText) gratuity of $\(String(format: "%.2f", gratuity.amount)). Adjust your tip accordingly.")
            }
        }
    }

    // MARK: - Subviews

    private var instructionsBanner: some View {
        Text("Point camera at receipt. Tap a number to capture it.")
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }

    private func detectedAmountsBanner(_ amounts: ScannedBillAmounts) -> some View {
        VStack(spacing: 12) {
            // Gratuity warning if detected
            if let gratuity = amounts.gratuity {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("Gratuity Included: $\(String(format: "%.2f", gratuity.amount))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.8))
                .clipShape(Capsule())
            }

            // Amount selection buttons
            HStack(spacing: 12) {
                if let subtotal = amounts.subtotal {
                    amountButton(
                        label: "Subtotal",
                        amount: subtotal,
                        color: .mint
                    ) {
                        selectAmounts(subtotal: subtotal, total: amounts.total, gratuity: amounts.gratuity)
                    }
                }

                if let total = amounts.total {
                    amountButton(
                        label: "Total",
                        amount: total,
                        color: .teal
                    ) {
                        selectAmounts(subtotal: amounts.subtotal, total: total, gratuity: amounts.gratuity)
                    }
                }
            }

            // Single amount banner (no buttons, just one amount)
            if amounts.subtotal != nil && amounts.total == nil && amounts.gratuity == nil {
                // Already showing subtotal button above
            } else if amounts.subtotal == nil && amounts.total != nil && amounts.gratuity == nil {
                // Already showing total button above
            }

            // Hint
            Text("Tap to use detected amount, or tap receipt for other amounts")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private func amountButton(label: String, amount: Double, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Text("$\(String(format: "%.2f", amount))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Actions

    private func selectAmounts(subtotal: Double?, total: Double?, gratuity: DetectedGratuity?) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Show gratuity confirmation if detected
        if gratuity != nil {
            showGratuityConfirmation = true
        }

        onAmountsSelected(SelectedAmounts(subtotal: subtotal, total: total, gratuity: gratuity))
        dismiss()
    }
}

// MARK: - Unsupported Scanner View

/// Fallback view shown when the device doesn't support DataScanner
struct UnsupportedScannerView: View {
    let dismiss: DismissAction

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))

                Text("Scanner Unavailable")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Receipt scanning requires a device with a camera and iOS 16 or later.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.mint, Color.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .padding(.top, 16)
            }
        }
    }
}

#Preview {
    ScannerContainerView { amount in
        print("Scanned amount: \(amount)")
    }
}
