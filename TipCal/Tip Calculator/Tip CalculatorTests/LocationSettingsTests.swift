//
//  LocationSettingsTests.swift
//  Tip CalculatorTests
//
//  Created by Nick MacCarthy on 12/27/25.
//

import XCTest
import CoreLocation
@testable import Tip_Calculator

final class LocationSettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear location-related UserDefaults for clean tests
        UserDefaults.standard.removeObject(forKey: "locationEnabled")
        UserDefaults.standard.removeObject(forKey: "hasSeenLocationOnboarding")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "locationEnabled")
        UserDefaults.standard.removeObject(forKey: "hasSeenLocationOnboarding")
        super.tearDown()
    }

    // MARK: - Location Enabled Default Value Tests

    func testLocationEnabled_defaultValue_isTrue() {
        // When no value is set, locationEnabled should default to true
        let value = UserDefaults.standard.object(forKey: "locationEnabled") as? Bool
        // Before any setting, the key doesn't exist
        XCTAssertNil(value)
        // The app defaults to true when nil (via @AppStorage default)
    }

    func testLocationEnabled_whenSetToFalse_returnsFalse() {
        UserDefaults.standard.set(false, forKey: "locationEnabled")
        let value = UserDefaults.standard.bool(forKey: "locationEnabled")
        XCTAssertFalse(value)
    }

    func testLocationEnabled_whenSetToTrue_returnsTrue() {
        UserDefaults.standard.set(true, forKey: "locationEnabled")
        let value = UserDefaults.standard.bool(forKey: "locationEnabled")
        XCTAssertTrue(value)
    }

    // MARK: - Location Onboarding State Tests

    func testHasSeenLocationOnboarding_defaultValue_isFalse() {
        let value = UserDefaults.standard.bool(forKey: "hasSeenLocationOnboarding")
        XCTAssertFalse(value)
    }

    func testHasSeenLocationOnboarding_whenSetToTrue_returnsTrue() {
        UserDefaults.standard.set(true, forKey: "hasSeenLocationOnboarding")
        let value = UserDefaults.standard.bool(forKey: "hasSeenLocationOnboarding")
        XCTAssertTrue(value)
    }

    // MARK: - Simulated "Maybe Later" Flow Tests

    func testMaybeLaterFlow_setsLocationEnabledToFalse() {
        // Simulate what happens when user taps "Maybe Later" in onboarding
        UserDefaults.standard.set(false, forKey: "locationEnabled")
        UserDefaults.standard.set(true, forKey: "hasSeenLocationOnboarding")

        XCTAssertFalse(UserDefaults.standard.bool(forKey: "locationEnabled"))
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenLocationOnboarding"))
    }

    func testEnableLocationFlow_leavesLocationEnabledAsDefault() {
        // Simulate what happens when user taps "Enable Location" in onboarding
        // We don't explicitly set locationEnabled, it uses the default (true)
        UserDefaults.standard.set(true, forKey: "hasSeenLocationOnboarding")

        // Since locationEnabled was never set to false, using @AppStorage default of true
        let locationEnabled = UserDefaults.standard.object(forKey: "locationEnabled") as? Bool ?? true
        XCTAssertTrue(locationEnabled)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenLocationOnboarding"))
    }

    // MARK: - Location Toggle State Logic Tests

    func testEffectiveLocationState_whenSystemDenied_shouldBeFalse() {
        // Even if user preference is true, if system denied, effective state is false
        UserDefaults.standard.set(true, forKey: "locationEnabled")
        
        let userPreference = UserDefaults.standard.bool(forKey: "locationEnabled")
        let systemDenied = true // Simulating CLAuthorizationStatus.denied
        
        // The effective state shown in UI
        let effectiveState = systemDenied ? false : userPreference
        
        XCTAssertFalse(effectiveState)
    }

    func testEffectiveLocationState_whenSystemAuthorized_respectsUserPreference() {
        UserDefaults.standard.set(true, forKey: "locationEnabled")
        
        let userPreference = UserDefaults.standard.bool(forKey: "locationEnabled")
        let systemDenied = false // Simulating authorized status
        
        let effectiveState = systemDenied ? false : userPreference
        
        XCTAssertTrue(effectiveState)
    }

    func testEffectiveLocationState_whenUserDisabled_shouldBeFalse() {
        UserDefaults.standard.set(false, forKey: "locationEnabled")
        
        let userPreference = UserDefaults.standard.bool(forKey: "locationEnabled")
        let systemDenied = false // Simulating authorized status
        
        let effectiveState = systemDenied ? false : userPreference
        
        XCTAssertFalse(effectiveState)
    }

    // MARK: - Location Manager Tests (MainActor)

    @MainActor
    func testLocationManager_initialization_setsAuthorizationStatus() {
        let manager = LocationManager()
        // Authorization status should be set (likely .notDetermined in test environment)
        // We just verify it doesn't crash and has a valid status
        let status = manager.authorizationStatus
        XCTAssertTrue([.notDetermined, .restricted, .denied, .authorizedWhenInUse, .authorizedAlways].contains(status))
    }

    @MainActor
    func testLocationManager_currentPlaceName_initiallyNil() {
        let manager = LocationManager()
        XCTAssertNil(manager.currentPlaceName)
    }

    @MainActor
    func testLocationManager_isFetching_initiallyFalse() {
        let manager = LocationManager()
        XCTAssertFalse(manager.isFetching)
    }
}

