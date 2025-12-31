//
//  LocationManager.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import Foundation
import CoreLocation
import MapKit

/// Manages location services for reverse geocoding restaurant/venue names
@MainActor @Observable
class LocationManager: NSObject, CLLocationManagerDelegate {

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    /// Search radius for nearby POI (in meters)
    private let poiSearchRadius: CLLocationDistance = 50

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
        // Default is true (enabled) if the key has never been set
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

        // Try MapKit POI search first for restaurant/bar names
        if let poiName = await fetchNearbyRestaurant(at: location) {
            currentPlaceName = poiName
            return poiName
        }

        // Fall back to reverse geocoding
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

    /// Searches for nearby restaurants, bars, or cafes using MapKit
    /// - Parameter location: The location to search near
    /// - Returns: The name of the closest restaurant/bar/cafe POI, or nil if none found
    private func fetchNearbyRestaurant(at location: CLLocation) async -> String? {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: poiSearchRadius * 2,
            longitudinalMeters: poiSearchRadius * 2
        )

        // Search for food-related POIs
        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .restaurant,
            .cafe,
            .bakery,
            .brewery,
            .winery,
            .nightlife,
            .foodMarket
        ])

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()

            // Find the closest POI within our radius
            var closestItem: MKMapItem?
            var closestDistance: CLLocationDistance = .greatestFiniteMagnitude

            for item in response.mapItems {
                guard let itemLocation = item.placemark.location else { continue }
                let distance = location.distance(from: itemLocation)

                if distance < closestDistance && distance <= poiSearchRadius {
                    closestDistance = distance
                    closestItem = item
                }
            }

            // Return the name of the closest POI
            if let item = closestItem, let name = item.name {
                return name
            }
        } catch {
            print("MapKit POI search failed: \(error.localizedDescription)")
        }

        return nil
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
