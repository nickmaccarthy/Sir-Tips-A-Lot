//
//  ScannerView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/23/25.
//

import SwiftUI
import VisionKit

/// A SwiftUI wrapper for VisionKit's DataScannerViewController
/// Enables receipt scanning with text detection, highlighting, and tap-to-capture
struct ScannerView: UIViewControllerRepresentable {
    /// Callback when a valid number is scanned and tapped by the user
    let onNumberScanned: (Double) -> Void
    
    /// Environment dismiss action to close the scanner
    @Environment(\.dismiss) private var dismiss
    
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
        Coordinator(onNumberScanned: onNumberScanned, dismiss: dismiss)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onNumberScanned: (Double) -> Void
        let dismiss: DismissAction
        
        init(onNumberScanned: @escaping (Double) -> Void, dismiss: DismissAction) {
            self.onNumberScanned = onNumberScanned
            self.dismiss = dismiss
        }
        
        // MARK: - DataScannerViewControllerDelegate
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):
                // Attempt to parse the tapped text as a number
                if let amount = cleanAndParseNumber(text.transcript) {
                    // Provide haptic feedback on successful capture
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Return the parsed value
                    onNumberScanned(amount)
                    
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
        
        // MARK: - Number Parsing
        
        /// Cleans a string and attempts to parse it as a currency/number value
        /// Handles formats like "$45.50", "45,50", "€ 123.45", "Total: $99.99"
        func cleanAndParseNumber(_ text: String) -> Double? {
            // Remove common currency symbols and labels
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
            // If there's a comma but no period, and the comma has exactly 2 digits after it
            if cleaned.contains(",") && !cleaned.contains(".") {
                // Check if it's likely a decimal comma (e.g., "45,50")
                let parts = cleaned.split(separator: ",")
                if parts.count == 2, let lastPart = parts.last, lastPart.count <= 2 {
                    cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
                } else {
                    // It's a thousands separator, just remove it
                    cleaned = cleaned.replacingOccurrences(of: ",", with: "")
                }
            } else {
                // Remove commas as thousand separators (e.g., "1,234.56" -> "1234.56")
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
            
            // Extract just the numeric portion using regex
            // This handles cases like "abc123.45xyz" -> "123.45"
            let pattern = #"[\d]+\.?[\d]*"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
                  let range = Range(match.range, in: cleaned) else {
                return nil
            }
            
            let numberString = String(cleaned[range])
            
            // Parse as Double
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
    let onNumberScanned: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            if ScannerView.isDeviceSupported && ScannerView.isScanningAvailable {
                ScannerView(onNumberScanned: onNumberScanned)
                    .ignoresSafeArea()
                
                // Overlay with close button and instructions
                VStack {
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
                    
                    // Instructions banner
                    Text("Point camera at receipt. Tap a number to capture it.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
            } else {
                // Fallback for unsupported devices (e.g., Simulator)
                UnsupportedScannerView(dismiss: dismiss)
            }
        }
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

