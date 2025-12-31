//
//  VisionScannerView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/30/25.
//

import SwiftUI
import VisionKit
import Vision

// MARK: - Text Observation Model

/// Represents a recognized text item with its spatial position
struct TextObservation {
    let text: String
    let boundingBox: CGRect  // Normalized 0-1 coordinates
    let confidence: Float

    /// Y-center of the bounding box (for line grouping)
    var yCenter: CGFloat {
        boundingBox.origin.y + boundingBox.height / 2
    }

    /// X-center of the bounding box (for left-to-right ordering)
    var xCenter: CGFloat {
        boundingBox.origin.x + boundingBox.width / 2
    }
}

// MARK: - Vision Scanner View

/// Enhanced scanner using VNDocumentCameraViewController and Vision framework
/// Provides better accuracy through document cropping and spatial text analysis
struct VisionScannerView: UIViewControllerRepresentable {
    /// Callback when amounts are detected and selected
    let onAmountsSelected: (SelectedAmounts) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Availability Check

    /// Whether document scanning is available on this device
    static var isAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onAmountsSelected: onAmountsSelected, dismiss: dismiss)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onAmountsSelected: (SelectedAmounts) -> Void
        let dismiss: DismissAction

        init(onAmountsSelected: @escaping (SelectedAmounts) -> Void, dismiss: DismissAction) {
            self.onAmountsSelected = onAmountsSelected
            self.dismiss = dismiss
        }

        // MARK: - VNDocumentCameraViewControllerDelegate

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Process the first page (receipts are typically single page)
            guard scan.pageCount > 0 else {
                dismiss()
                return
            }

            let image = scan.imageOfPage(at: 0)

            // Process the scanned image
            Task {
                let amounts = await processScannedImage(image)
                await MainActor.run {
                    if amounts.hasSubtotal || amounts.hasTotal {
                        // Show selection UI
                        presentAmountSelection(amounts: amounts, in: controller)
                    } else {
                        // No amounts detected - dismiss
                        dismiss()
                    }
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document camera error: \(error.localizedDescription)")
            dismiss()
        }

        // MARK: - Image Processing

        /// Processes the scanned image using Vision framework
        private func processScannedImage(_ image: UIImage) async -> ScannedBillAmounts {
            guard let cgImage = image.cgImage else {
                return ScannedBillAmounts(subtotal: nil, total: nil, gratuity: nil)
            }

            return await withCheckedContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        print("Vision error: \(error.localizedDescription)")
                        continuation.resume(returning: ScannedBillAmounts(subtotal: nil, total: nil, gratuity: nil))
                        return
                    }

                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(returning: ScannedBillAmounts(subtotal: nil, total: nil, gratuity: nil))
                        return
                    }

                    let amounts = self.analyzeTextObservations(observations)
                    continuation.resume(returning: amounts)
                }

                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try handler.perform([request])
                } catch {
                    print("Failed to perform Vision request: \(error)")
                    continuation.resume(returning: ScannedBillAmounts(subtotal: nil, total: nil, gratuity: nil))
                }
            }
        }

        // MARK: - Spatial Text Analysis

        /// Analyzes text observations using spatial positioning
        private func analyzeTextObservations(_ observations: [VNRecognizedTextObservation]) -> ScannedBillAmounts {
            // Convert to our TextObservation model
            var textObservations: [TextObservation] = []

            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }

                // Skip low confidence results
                guard candidate.confidence > 0.5 else { continue }

                textObservations.append(TextObservation(
                    text: candidate.string,
                    boundingBox: observation.boundingBox,
                    confidence: candidate.confidence
                ))
            }

            // Group by lines (Y-position)
            let lineGroups = groupByLine(textObservations)

            // Match labels to amounts
            return matchLabelsToAmounts(lineGroups)
        }

        /// Groups text observations by Y-position (same line)
        private func groupByLine(_ observations: [TextObservation]) -> [[TextObservation]] {
            guard !observations.isEmpty else { return [] }

            // Sort by Y (bottom to top in normalized coordinates, but we want top to bottom)
            let sorted = observations.sorted { $0.yCenter > $1.yCenter }

            var groups: [[TextObservation]] = []
            var currentGroup: [TextObservation] = []
            var lastY: CGFloat = -1

            let yTolerance: CGFloat = 0.015 // 1.5% of image height

            for observation in sorted {
                if lastY < 0 || abs(observation.yCenter - lastY) <= yTolerance {
                    currentGroup.append(observation)
                } else {
                    if !currentGroup.isEmpty {
                        // Sort current group by X (left to right)
                        groups.append(currentGroup.sorted { $0.xCenter < $1.xCenter })
                    }
                    currentGroup = [observation]
                }
                lastY = observation.yCenter
            }

            // Add the last group
            if !currentGroup.isEmpty {
                groups.append(currentGroup.sorted { $0.xCenter < $1.xCenter })
            }

            return groups
        }

        /// Matches labels (Subtotal, Total, etc.) to amounts on the same line
        private func matchLabelsToAmounts(_ lineGroups: [[TextObservation]]) -> ScannedBillAmounts {
            var subtotal: Double?
            var total: Double?
            var gratuity: DetectedGratuity?
            var tipSuggestionLines: Set<Int> = []

            // First pass: identify tip suggestion table lines
            for (index, line) in lineGroups.enumerated() {
                let lineText = line.map { $0.text }.joined(separator: " ").uppercased()

                // Tip suggestion table patterns
                if isTipSuggestionLine(lineText) {
                    tipSuggestionLines.insert(index)
                }
            }

            // Second pass: extract labeled amounts (skip tip suggestion lines)
            for (index, line) in lineGroups.enumerated() {
                guard !tipSuggestionLines.contains(index) else { continue }

                let lineText = line.map { $0.text }.joined(separator: " ")
                let upperLineText = lineText.uppercased()

                // Find the rightmost amount on this line
                var lineAmount: Double?
                for observation in line.reversed() {
                    if let amount = extractCurrencyAmount(from: observation.text) {
                        lineAmount = amount
                        break
                    }
                }

                guard let amount = lineAmount, amount >= 5.0 else { continue }

                // Check for label types
                if containsSubtotalLabel(upperLineText) && subtotal == nil {
                    subtotal = amount
                } else if containsTotalLabel(upperLineText) && !containsTaxLabel(upperLineText) && total == nil {
                    total = amount
                } else if containsGratuityLabel(upperLineText) && gratuity == nil {
                    let percentage = extractPercentage(from: lineText)
                    gratuity = DetectedGratuity(amount: amount, percentage: percentage, label: lineText)
                }
            }

            // Validate: subtotal should be less than total
            if let s = subtotal, let t = total, s > t {
                // Swap if needed
                subtotal = t
                total = s
            }

            return ScannedBillAmounts(subtotal: subtotal, total: total, gratuity: gratuity)
        }

        // MARK: - Label Detection Helpers

        private func containsSubtotalLabel(_ text: String) -> Bool {
            let patterns = ["SUBTOTAL", "SUB TOTAL", "SUB-TOTAL", "PRETAX", "PRE-TAX", "FOOD TOTAL"]
            return patterns.contains { text.contains($0) }
        }

        private func containsTotalLabel(_ text: String) -> Bool {
            let patterns = ["TOTAL", "AMOUNT DUE", "BALANCE DUE", "GRAND TOTAL", "CREDIT CARD AUTH"]
            return patterns.contains { text.contains($0) }
        }

        private func containsTaxLabel(_ text: String) -> Bool {
            let patterns = ["TAX", "TAXES", "HST", "GST", "PST", "VAT"]
            return patterns.contains { text.contains($0) }
        }

        private func containsGratuityLabel(_ text: String) -> Bool {
            let patterns = ["GRATUITY", "SERVICE CHARGE", "TIP INCLUDED", "AUTO GRAT"]
            return patterns.contains { text.contains($0) }
        }

        private func isTipSuggestionLine(_ text: String) -> Bool {
            // Tip table header
            if text.contains("TIP") && text.contains("AMOUNT") && text.contains("TOTAL") {
                return true
            }
            // Tip percentage rows (15%, 18%, 20%, etc.)
            if text.range(of: #"^\s*(15|18|20|22|25|30)\s*%"#, options: .regularExpression) != nil {
                return true
            }
            // Multiple dollar amounts with percentage
            let dollarCount = text.components(separatedBy: "$").count - 1
            let hasPercentage = text.contains("%")
            if dollarCount >= 2 && hasPercentage {
                return true
            }
            return false
        }

        // MARK: - Amount Extraction Helpers

        private func extractCurrencyAmount(from text: String) -> Double? {
            // Try currency pattern first
            let currencyPattern = #"\$\s*(\d+(?:,\d{3})*(?:\.\d{2})?)"#
            if let regex = try? NSRegularExpression(pattern: currencyPattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountString = String(text[range]).replacingOccurrences(of: ",", with: "")
                return Double(amountString)
            }

            // Try decimal pattern without currency
            let decimalPattern = #"(\d+\.\d{2})"#
            if let regex = try? NSRegularExpression(pattern: decimalPattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return Double(text[range])
            }

            return nil
        }

        private func extractPercentage(from text: String) -> Double? {
            let pattern = #"(\d+(?:\.\d+)?)\s*%"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return Double(text[range])
            }
            return nil
        }

        // MARK: - Amount Selection UI

        private func presentAmountSelection(amounts: ScannedBillAmounts, in controller: UIViewController) {
            let alert = UIAlertController(
                title: "Amounts Detected",
                message: buildAmountMessage(amounts),
                preferredStyle: .actionSheet
            )

            if let subtotal = amounts.subtotal {
                alert.addAction(UIAlertAction(
                    title: "Use Subtotal: $\(String(format: "%.2f", subtotal))",
                    style: .default
                ) { [weak self] _ in
                    self?.selectAmounts(subtotal: subtotal, total: amounts.total, gratuity: amounts.gratuity)
                })
            }

            if let total = amounts.total {
                alert.addAction(UIAlertAction(
                    title: "Use Total: $\(String(format: "%.2f", total))",
                    style: .default
                ) { [weak self] _ in
                    self?.selectAmounts(subtotal: amounts.subtotal, total: total, gratuity: amounts.gratuity)
                })
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.dismiss()
            })

            // For iPad
            if let popover = alert.popoverPresentationController {
                popover.sourceView = controller.view
                popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            controller.present(alert, animated: true)
        }

        private func buildAmountMessage(_ amounts: ScannedBillAmounts) -> String {
            var lines: [String] = []

            if let subtotal = amounts.subtotal {
                lines.append("Subtotal: $\(String(format: "%.2f", subtotal))")
            }
            if let total = amounts.total {
                lines.append("Total: $\(String(format: "%.2f", total))")
            }
            if let gratuity = amounts.gratuity {
                let percentText = gratuity.percentage.map { " (\(Int($0))%)" } ?? ""
                lines.append("Gratuity\(percentText): $\(String(format: "%.2f", gratuity.amount))")
            }

            return lines.joined(separator: "\n")
        }

        private func selectAmounts(subtotal: Double?, total: Double?, gratuity: DetectedGratuity?) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            onAmountsSelected(SelectedAmounts(subtotal: subtotal, total: total, gratuity: gratuity))
            dismiss()
        }
    }
}

// MARK: - Vision Scanner Container View

/// Container that wraps VisionScannerView with proper UI handling
struct VisionScannerContainerView: View {
    let onAmountsSelected: (SelectedAmounts) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if VisionScannerView.isAvailable {
            VisionScannerView(onAmountsSelected: onAmountsSelected)
                .ignoresSafeArea()
        } else {
            // Fallback for unsupported devices (shouldn't happen on iOS 17+)
            VStack(spacing: 24) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))

                Text("Document Scanner Unavailable")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("This device doesn't support document scanning.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color.mint)
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
        }
    }
}

#Preview {
    VisionScannerContainerView { amounts in
        print("Selected: \(amounts)")
    }
}
