//
//  TipCalculatorViewModel.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

class TipCalculatorViewModel: ObservableObject {
    @Published var billAmountString: String = ""
    @Published var selectedTipPercentage: Double = 20.0
    @Published var roundUp: Bool = false
    @Published var numberOfPeopleString: String = "1"
    @Published var isCustomTipSelected: Bool = false
    @Published var customTipString: String = ""
    @Published var selectedSentiment: String? = "good" // Default to "Good" sentiment
    @Published var recentBills: [SavedBill] = []
    @Published var didAutoSave: Bool = false
    @Published var noteText: String = ""

    /// Flag to prevent auto-save while user is editing notes
    @Published var isEditingNote: Bool = false
    
    // MARK: - Scanned Receipt Properties
    
    /// Scanned subtotal from receipt (the pre-gratuity amount)
    @Published var scannedSubtotal: Double?
    
    /// Scanned total from receipt (may include gratuity already)
    @Published var scannedTotal: Double?
    
    /// Detected gratuity from receipt (if pre-included)
    @Published var detectedGratuityAmount: Double?
    @Published var detectedGratuityPercentage: Double?
    
    /// Whether to tip on subtotal (true) or total (false) when receipt breakdown available
    @Published var tipOnSubtotal: Bool = true

    /// Location manager for fetching venue names (lazy to avoid MainActor isolation issues)
    @MainActor lazy var locationManager = LocationManager()

    private let userDefaultsKey = "recentBills"
    private let maxHistoryCount = 10
    private let autoSaveDelay: TimeInterval = 7.0
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load bills synchronously on init (safe for small data)
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let bills = try? JSONDecoder().decode([SavedBill].self, from: data) {
            self.recentBills = bills
        }

        // Set up auto-save pipeline: saves after 10 seconds of idle time
        setupAutoSave()
    }

    /// Sets up Combine pipeline to auto-save after idle period
    private func setupAutoSave() {
        Publishers.CombineLatest4(
            $billAmountString,
            $selectedTipPercentage,
            $numberOfPeopleString,
            Publishers.CombineLatest3($roundUp, $customTipString, $isCustomTipSelected)
        )
        .dropFirst() // Skip the initial values on subscription
        .debounce(for: .seconds(autoSaveDelay), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.autoSaveBillIfNeeded()
        }
        .store(in: &cancellables)
    }

    var billValue: Double {
        Double(billAmountString) ?? 0.0
    }

    var effectiveTipPercentage: Double {
        if isCustomTipSelected {
            return Double(customTipString) ?? 0.0
        }
        return selectedTipPercentage
    }

    var tipAmountBeforeRounding: Double {
        billValue * (effectiveTipPercentage / 100.0)
    }

    var tipAmount: Double {
        if roundUp {
            return ceil(tipAmountBeforeRounding)
        }
        return tipAmountBeforeRounding
    }

    var totalAmount: Double {
        billValue + tipAmount
    }

    var numberOfPeopleValue: Int {
        max(1, Int(numberOfPeopleString) ?? 1)
    }

    var amountPerPerson: Double {
        guard numberOfPeopleValue > 0 else { return 0 }
        return grandTotal / Double(numberOfPeopleValue)
    }
    
    // MARK: - Receipt Breakdown Properties
    
    /// Whether we have a scanned receipt with subtotal/total breakdown
    var hasReceiptBreakdown: Bool {
        scannedSubtotal != nil || scannedTotal != nil
    }
    
    /// The grand total: scannedTotal + tipAmount if we have a receipt, otherwise billValue + tipAmount
    var grandTotal: Double {
        if let receiptTotal = scannedTotal {
            // Receipt has a total (may include gratuity already)
            // Add our tip on top of the appropriate base
            return receiptTotal + tipAmount
        }
        return totalAmount
    }
    
    /// Clears all scanned receipt data
    func clearScannedData() {
        scannedSubtotal = nil
        scannedTotal = nil
        detectedGratuityAmount = nil
        detectedGratuityPercentage = nil
    }

    // MARK: - Lifetime Statistics

    /// Total tips paid across all saved bills
    var lifetimeTips: Double {
        recentBills.reduce(0) { $0 + $1.tipAmount }
    }

    /// Total amount spent across all saved bills (bill + tip)
    var lifetimeSpend: Double {
        recentBills.reduce(0) { $0 + $1.totalAmount }
    }

    /// Checks if current bill values match the most recently saved bill
    private var isDuplicateOfLastSave: Bool {
        guard let lastBill = recentBills.first else { return false }
        return lastBill.billAmount == billValue &&
               lastBill.tipPercentage == effectiveTipPercentage &&
               lastBill.numberOfPeople == numberOfPeopleValue
    }

    func selectTipPercentage(_ percentage: Double) {
        selectedTipPercentage = percentage
        isCustomTipSelected = false
    }

    func selectTipWithSentiment(_ percentage: Double, sentiment: String) {
        selectedTipPercentage = percentage
        selectedSentiment = sentiment
        isCustomTipSelected = false
    }

    func selectCustomTip() {
        isCustomTipSelected = true
        selectedSentiment = nil
    }

    // MARK: - Reset

    /// Resets the calculator to its default state
    /// Clears bill amount, resets split to 1, and defaults tip to "Ok" sentiment
    func resetAll() {
        billAmountString = ""
        numberOfPeopleString = "1"
        roundUp = false
        isCustomTipSelected = false
        customTipString = ""
        selectedSentiment = "ok"
        noteText = ""
        isEditingNote = false
        clearScannedData()
        // Note: selectedTipPercentage will be set by ContentView when sentiment changes
    }

    // MARK: - Bill History Persistence

    /// Auto-saves the bill if valid and not a duplicate of the last save
    private func autoSaveBillIfNeeded() {
        // Don't auto-save if user is currently editing notes
        guard billValue > 0, !isDuplicateOfLastSave, !isEditingNote else { return }

        // Get the current sentiment emoji from UserDefaults
        let sentimentEmoji = getCurrentSentimentEmoji()

        // Auto-save with async location fetch
        Task { @MainActor in
            let locationName = await locationManager.fetchCurrentLocationName()
            saveBill(locationName: locationName, sentimentEmoji: sentimentEmoji)

            // Signal that an auto-save occurred
            didAutoSave = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.didAutoSave = false
            }
        }
    }

    /// Gets the current sentiment emoji based on selectedSentiment
    private func getCurrentSentimentEmoji() -> String? {
        guard let sentiment = selectedSentiment else { return nil }

        switch sentiment {
        case "bad":
            return UserDefaults.standard.string(forKey: "emoji_bad") ?? "😢"
        case "ok":
            return UserDefaults.standard.string(forKey: "emoji_ok") ?? "😐"
        case "good":
            return UserDefaults.standard.string(forKey: "emoji_good") ?? "🤩"
        default:
            return nil
        }
    }

    /// Saves the current bill calculation to history
    /// - Parameters:
    ///   - locationName: Optional venue/restaurant name from location services
    ///   - sentimentEmoji: Optional emoji representing the service sentiment
    ///   - notes: Optional user notes about the bill
    func saveBill(locationName: String? = nil, sentimentEmoji: String? = nil, notes: String? = nil) {
        guard billValue > 0 else { return }

        // Use provided notes, or fall back to current noteText if not empty
        let billNotes: String? = notes ?? (noteText.isEmpty ? nil : noteText)

        let savedBill = SavedBill(
            billAmount: billValue,
            tipPercentage: effectiveTipPercentage,
            tipAmount: tipAmount,
            totalAmount: totalAmount,
            numberOfPeople: numberOfPeopleValue,
            amountPerPerson: amountPerPerson,
            locationName: locationName,
            sentiment: sentimentEmoji,
            notes: billNotes
        )

        // Prepend new bill to array
        recentBills.insert(savedBill, at: 0)

        // Limit to max history count
        if recentBills.count > maxHistoryCount {
            recentBills = Array(recentBills.prefix(maxHistoryCount))
        }

        persistBills()

        // Clear note text after saving
        noteText = ""
    }

    /// Deletes a bill at the specified index
    func deleteBill(at offsets: IndexSet) {
        recentBills.remove(atOffsets: offsets)
        persistBills()
    }

    /// Clears all saved bills from history
    func clearHistory() {
        recentBills.removeAll()
        persistBills()
    }

    /// Persists bills to UserDefaults
    private func persistBills() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentBills)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to encode saved bills: \(error)")
        }
    }
}

// MARK: - Location Manager

/// Manages location services for reverse geocoding restaurant/venue names
@MainActor @Observable
class LocationManager: NSObject, CLLocationManagerDelegate {

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    /// Current authorization status for location services
    var authorizationStatus: CLAuthorizationStatus

    /// The most recently fetched place name from reverse geocoding
    var currentPlaceName: String?

    /// Indicates if a location fetch is in progress
    var isFetching: Bool = false

    /// Continuation for async location requests
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    // MARK: - Initialization

    override init() {
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public Methods

    /// Requests "When In Use" location permission from the user
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Fetches the current location and reverse geocodes it to a place name
    /// - Returns: The name of the current location (e.g., "Olive Garden") or nil if unavailable
    func fetchCurrentLocationName() async -> String? {
        // Check user preference first - respect the toggle even if system permission is granted
        let locationEnabled = UserDefaults.standard.object(forKey: "locationEnabled") as? Bool ?? true
        guard locationEnabled else {
            return nil
        }

        // Check authorization - don't request permission here to avoid unexpected dialogs
        // Permission should be requested via LocationOnboardingView on first run
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return nil
        }

        isFetching = true
        defer { isFetching = false }

        // Get current location
        guard let location = await getCurrentLocation() else {
            return nil
        }

        // Reverse geocode the location
        return await reverseGeocode(location: location)
    }

    // MARK: - Private Methods

    /// Requests the current location using async/await
    private func getCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    /// Reverse geocodes a location to extract the place name
    private func reverseGeocode(location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            // Try to get the most descriptive name available
            // Priority: name (business name) > thoroughfare (street) > locality (city)
            if let name = placemark.name, !name.isEmpty {
                currentPlaceName = name
                return name
            } else if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
                let streetName = thoroughfare
                currentPlaceName = streetName
                return streetName
            } else if let locality = placemark.locality, !locality.isEmpty {
                currentPlaceName = locality
                return locality
            }

            return nil
        } catch {
            print("Reverse geocoding failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locationContinuation?.resume(returning: locations.first)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location manager failed with error: \(error.localizedDescription)")
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}
