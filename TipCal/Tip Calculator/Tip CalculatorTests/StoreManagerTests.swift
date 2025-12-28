//
//  StoreManagerTests.swift
//  Tip CalculatorTests
//
//  Created by Nick MacCarthy on 12/26/25.
//

import XCTest
@testable import Tip_Calculator

final class StoreManagerTests: XCTestCase {

    // MARK: - TipProduct Tests

    func testTipProductIDs() {
        // Verify all product IDs are correctly defined
        XCTAssertEqual(TipProduct.good.rawValue, "nmac.TipCalculator.tip.service.good")
        XCTAssertEqual(TipProduct.great.rawValue, "nmac.TipCalculator.tip.service.great")
        XCTAssertEqual(TipProduct.amazing.rawValue, "nmac.TipCalculator.tip.service.amazing")
    }

    func testTipProductDisplayNames() {
        XCTAssertEqual(TipProduct.good.displayName, "Good Service")
        XCTAssertEqual(TipProduct.great.displayName, "Great Service")
        XCTAssertEqual(TipProduct.amazing.displayName, "AMAZING SERVICE!")
    }

    func testTipProductEmojis() {
        XCTAssertEqual(TipProduct.good.emoji, "😀")
        XCTAssertEqual(TipProduct.great.emoji, "😊")
        XCTAssertEqual(TipProduct.amazing.emoji, "🤩")
    }

    func testTipProductAllProductIDs() {
        let allIDs = TipProduct.allProductIDs
        XCTAssertEqual(allIDs.count, 3)
        XCTAssertTrue(allIDs.contains("nmac.TipCalculator.tip.service.good"))
        XCTAssertTrue(allIDs.contains("nmac.TipCalculator.tip.service.great"))
        XCTAssertTrue(allIDs.contains("nmac.TipCalculator.tip.service.amazing"))
    }

    func testTipProductIdentifiable() {
        // Verify each product's id matches its rawValue
        XCTAssertEqual(TipProduct.good.id, TipProduct.good.rawValue)
        XCTAssertEqual(TipProduct.great.id, TipProduct.great.rawValue)
        XCTAssertEqual(TipProduct.amazing.id, TipProduct.amazing.rawValue)
    }

    func testTipProductCaseIterable() {
        // Verify CaseIterable conformance returns all cases
        let allCases = TipProduct.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.good))
        XCTAssertTrue(allCases.contains(.great))
        XCTAssertTrue(allCases.contains(.amazing))
    }

    // MARK: - PurchaseState Tests

    func testPurchaseStateEquatable() {
        // Test idle state
        XCTAssertEqual(PurchaseState.idle, PurchaseState.idle)

        // Test purchasing state
        XCTAssertEqual(PurchaseState.purchasing, PurchaseState.purchasing)

        // Test purchased state
        XCTAssertEqual(PurchaseState.purchased, PurchaseState.purchased)

        // Test cancelled state
        XCTAssertEqual(PurchaseState.cancelled, PurchaseState.cancelled)

        // Test failed state with same message
        XCTAssertEqual(PurchaseState.failed("Error"), PurchaseState.failed("Error"))

        // Test failed state with different messages
        XCTAssertNotEqual(PurchaseState.failed("Error1"), PurchaseState.failed("Error2"))

        // Test different states are not equal
        XCTAssertNotEqual(PurchaseState.idle, PurchaseState.purchasing)
        XCTAssertNotEqual(PurchaseState.purchased, PurchaseState.cancelled)
    }

    // MARK: - StoreManager Initialization Tests

    @MainActor
    func testStoreManagerInitialState() {
        let storeManager = StoreManager()

        // Initial state should be idle
        XCTAssertEqual(storeManager.purchaseState, .idle)

        // Products array should initially be empty (will be populated async)
        // Note: In a real test with StoreKit configuration, products would load
        XCTAssertTrue(storeManager.products.isEmpty || storeManager.isLoading)
    }

    @MainActor
    func testStoreManagerResetPurchaseState() {
        let storeManager = StoreManager()

        // Set to a non-idle state
        storeManager.purchaseState = .purchased
        XCTAssertEqual(storeManager.purchaseState, .purchased)

        // Reset should return to idle
        storeManager.resetPurchaseState()
        XCTAssertEqual(storeManager.purchaseState, .idle)
    }

    @MainActor
    func testStoreManagerResetFromFailedState() {
        let storeManager = StoreManager()

        // Set to failed state
        storeManager.purchaseState = .failed("Test error")
        XCTAssertEqual(storeManager.purchaseState, .failed("Test error"))

        // Reset should return to idle
        storeManager.resetPurchaseState()
        XCTAssertEqual(storeManager.purchaseState, .idle)
    }

    @MainActor
    func testStoreManagerResetFromCancelledState() {
        let storeManager = StoreManager()

        // Set to cancelled state
        storeManager.purchaseState = .cancelled
        XCTAssertEqual(storeManager.purchaseState, .cancelled)

        // Reset should return to idle
        storeManager.resetPurchaseState()
        XCTAssertEqual(storeManager.purchaseState, .idle)
    }
}


