//
//  LocationManager.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import Foundation
import CoreLocation

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
        // Check authorization first
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
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
