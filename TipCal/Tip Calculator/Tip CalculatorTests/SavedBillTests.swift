//
//  SavedBillTests.swift
//  Tip CalculatorTests
//
//  Created by Nick MacCarthy on 12/26/25.
//

import XCTest
@testable import Tip_Calculator

final class SavedBillTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSavedBill_initWithAllParameters_setsAllProperties() {
        let id = UUID()
        let date = Date()

        let bill = SavedBill(
            id: id,
            date: date,
            billAmount: 100.0,
            tipPercentage: 20.0,
            tipAmount: 20.0,
            totalAmount: 120.0,
            numberOfPeople: 2,
            amountPerPerson: 60.0
        )

        XCTAssertEqual(bill.id, id)
        XCTAssertEqual(bill.date, date)
        XCTAssertEqual(bill.billAmount, 100.0, accuracy: 0.001)
        XCTAssertEqual(bill.tipPercentage, 20.0, accuracy: 0.001)
        XCTAssertEqual(bill.tipAmount, 20.0, accuracy: 0.001)
        XCTAssertEqual(bill.totalAmount, 120.0, accuracy: 0.001)
        XCTAssertEqual(bill.numberOfPeople, 2)
        XCTAssertEqual(bill.amountPerPerson, 60.0, accuracy: 0.001)
    }

    func testSavedBill_initWithDefaults_generatesUUIDAndDate() {
        let bill = SavedBill(
            billAmount: 50.0,
            tipPercentage: 15.0,
            tipAmount: 7.5,
            totalAmount: 57.5,
            numberOfPeople: 1,
            amountPerPerson: 57.5
        )

        XCTAssertNotNil(bill.id)
        XCTAssertNotNil(bill.date)
        // Date should be approximately now
        XCTAssertTrue(Date().timeIntervalSince(bill.date) < 1.0)
        // Location, sentiment, and notes should default to nil
        XCTAssertNil(bill.locationName)
        XCTAssertNil(bill.sentiment)
        XCTAssertNil(bill.notes)
    }

    func testSavedBill_initWithLocationAndSentiment_setsProperties() {
        let bill = SavedBill(
            billAmount: 50.0,
            tipPercentage: 20.0,
            tipAmount: 10.0,
            totalAmount: 60.0,
            numberOfPeople: 1,
            amountPerPerson: 60.0,
            locationName: "Joe's Pizza",
            sentiment: "🤩"
        )

        XCTAssertEqual(bill.locationName, "Joe's Pizza")
        XCTAssertEqual(bill.sentiment, "🤩")
    }

    func testSavedBill_initWithOnlyLocation_sentimentIsNil() {
        let bill = SavedBill(
            billAmount: 50.0,
            tipPercentage: 20.0,
            tipAmount: 10.0,
            totalAmount: 60.0,
            numberOfPeople: 1,
            amountPerPerson: 60.0,
            locationName: "Olive Garden"
        )

        XCTAssertEqual(bill.locationName, "Olive Garden")
        XCTAssertNil(bill.sentiment)
    }

    func testSavedBill_initWithOnlySentiment_locationIsNil() {
        let bill = SavedBill(
            billAmount: 50.0,
            tipPercentage: 20.0,
            tipAmount: 10.0,
            totalAmount: 60.0,
            numberOfPeople: 1,
            amountPerPerson: 60.0,
            sentiment: "😐"
        )

        XCTAssertNil(bill.locationName)
        XCTAssertEqual(bill.sentiment, "😐")
    }

    func testSavedBill_initWithNotes_setsNotesProperty() {
        let bill = SavedBill(
            billAmount: 50.0,
            tipPercentage: 20.0,
            tipAmount: 10.0,
            totalAmount: 60.0,
            numberOfPeople: 1,
            amountPerPerson: 60.0,
            notes: "Great birthday dinner!"
        )

        XCTAssertEqual(bill.notes, "Great birthday dinner!")
    }

    func testSavedBill_initWithAllOptionalFields_setsAllProperties() {
        let bill = SavedBill(
            billAmount: 100.0,
            tipPercentage: 25.0,
            tipAmount: 25.0,
            totalAmount: 125.0,
            numberOfPeople: 4,
            amountPerPerson: 31.25,
            locationName: "The Fancy Restaurant",
            sentiment: "🤩",
            notes: "Celebrated anniversary here!"
        )

        XCTAssertEqual(bill.locationName, "The Fancy Restaurant")
        XCTAssertEqual(bill.sentiment, "🤩")
        XCTAssertEqual(bill.notes, "Celebrated anniversary here!")
    }

    // MARK: - Codable Tests

    func testSavedBill_encodeDecode_roundTrip() throws {
        let originalBill = SavedBill(
            billAmount: 75.50,
            tipPercentage: 18.0,
            tipAmount: 13.59,
            totalAmount: 89.09,
            numberOfPeople: 3,
            amountPerPerson: 29.70
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalBill)

        let decoder = JSONDecoder()
        let decodedBill = try decoder.decode(SavedBill.self, from: data)

        XCTAssertEqual(decodedBill.id, originalBill.id)
        XCTAssertEqual(decodedBill.billAmount, originalBill.billAmount, accuracy: 0.001)
        XCTAssertEqual(decodedBill.tipPercentage, originalBill.tipPercentage, accuracy: 0.001)
        XCTAssertEqual(decodedBill.tipAmount, originalBill.tipAmount, accuracy: 0.001)
        XCTAssertEqual(decodedBill.totalAmount, originalBill.totalAmount, accuracy: 0.001)
        XCTAssertEqual(decodedBill.numberOfPeople, originalBill.numberOfPeople)
        XCTAssertEqual(decodedBill.amountPerPerson, originalBill.amountPerPerson, accuracy: 0.001)
    }

    func testSavedBill_encodeDecodeWithLocationAndSentiment_roundTrip() throws {
        let originalBill = SavedBill(
            billAmount: 75.50,
            tipPercentage: 18.0,
            tipAmount: 13.59,
            totalAmount: 89.09,
            numberOfPeople: 3,
            amountPerPerson: 29.70,
            locationName: "Olive Garden",
            sentiment: "🤩"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalBill)

        let decoder = JSONDecoder()
        let decodedBill = try decoder.decode(SavedBill.self, from: data)

        XCTAssertEqual(decodedBill.locationName, "Olive Garden")
        XCTAssertEqual(decodedBill.sentiment, "🤩")
    }

    func testSavedBill_encodeDecodeWithNotes_roundTrip() throws {
        let originalBill = SavedBill(
            billAmount: 85.00,
            tipPercentage: 22.0,
            tipAmount: 18.70,
            totalAmount: 103.70,
            numberOfPeople: 2,
            amountPerPerson: 51.85,
            locationName: "Sushi Palace",
            sentiment: "🤩",
            notes: "Best omakase ever! Will return."
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalBill)

        let decoder = JSONDecoder()
        let decodedBill = try decoder.decode(SavedBill.self, from: data)

        XCTAssertEqual(decodedBill.notes, "Best omakase ever! Will return.")
        XCTAssertEqual(decodedBill.locationName, "Sushi Palace")
        XCTAssertEqual(decodedBill.sentiment, "🤩")
    }

    func testSavedBill_decodeWithoutNotes_backwardCompatibility() throws {
        // Simulate JSON from app version without notes field
        let legacyJSON = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440001",
            "date": 0,
            "billAmount": 75.0,
            "tipPercentage": 20.0,
            "tipAmount": 15.0,
            "totalAmount": 90.0,
            "numberOfPeople": 2,
            "amountPerPerson": 45.0,
            "locationName": "Pizza Place",
            "sentiment": "😐"
        }
        """

        let data = legacyJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decodedBill = try decoder.decode(SavedBill.self, from: data)

        XCTAssertEqual(decodedBill.billAmount, 75.0, accuracy: 0.001)
        XCTAssertEqual(decodedBill.locationName, "Pizza Place")
        XCTAssertEqual(decodedBill.sentiment, "😐")
        XCTAssertNil(decodedBill.notes)
    }

    func testSavedBill_decodeWithoutLocationAndSentiment_backwardCompatibility() throws {
        // Simulate JSON from older app version without locationName, sentiment, and notes fields
        let legacyJSON = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "date": 0,
            "billAmount": 50.0,
            "tipPercentage": 20.0,
            "tipAmount": 10.0,
            "totalAmount": 60.0,
            "numberOfPeople": 1,
            "amountPerPerson": 60.0
        }
        """

        let data = legacyJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decodedBill = try decoder.decode(SavedBill.self, from: data)

        XCTAssertEqual(decodedBill.billAmount, 50.0, accuracy: 0.001)
        XCTAssertNil(decodedBill.locationName)
        XCTAssertNil(decodedBill.sentiment)
        XCTAssertNil(decodedBill.notes)
    }

    func testSavedBill_encodeDecodeArray_roundTrip() throws {
        let bills = [
            SavedBill(
                billAmount: 50.0,
                tipPercentage: 20.0,
                tipAmount: 10.0,
                totalAmount: 60.0,
                numberOfPeople: 1,
                amountPerPerson: 60.0
            ),
            SavedBill(
                billAmount: 100.0,
                tipPercentage: 15.0,
                tipAmount: 15.0,
                totalAmount: 115.0,
                numberOfPeople: 2,
                amountPerPerson: 57.5
            )
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(bills)

        let decoder = JSONDecoder()
        let decodedBills = try decoder.decode([SavedBill].self, from: data)

        XCTAssertEqual(decodedBills.count, 2)
        XCTAssertEqual(decodedBills[0].billAmount, 50.0, accuracy: 0.001)
        XCTAssertEqual(decodedBills[1].billAmount, 100.0, accuracy: 0.001)
    }

    // MARK: - Identifiable Tests

    func testSavedBill_identifiable_uniqueIds() {
        let bill1 = SavedBill(
            billAmount: 50.0,
            tipPercentage: 20.0,
            tipAmount: 10.0,
            totalAmount: 60.0,
            numberOfPeople: 1,
            amountPerPerson: 60.0
        )

        let bill2 = SavedBill(
            billAmount: 50.0,
            tipPercentage: 20.0,
            tipAmount: 10.0,
            totalAmount: 60.0,
            numberOfPeople: 1,
            amountPerPerson: 60.0
        )

        XCTAssertNotEqual(bill1.id, bill2.id)
    }

    // MARK: - Edge Case Tests

    func testSavedBill_withZeroValues_encodesAndDecodes() throws {
        let bill = SavedBill(
            billAmount: 0.0,
            tipPercentage: 0.0,
            tipAmount: 0.0,
            totalAmount: 0.0,
            numberOfPeople: 1,
            amountPerPerson: 0.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(bill)

        let decoder = JSONDecoder()
        let decodedBill = try decoder.decode(SavedBill.self, from: data)

        XCTAssertEqual(decodedBill.billAmount, 0.0, accuracy: 0.001)
        XCTAssertEqual(decodedBill.totalAmount, 0.0, accuracy: 0.001)
    }

    func testSavedBill_withLargeValues_encodesAndDecodes() throws {
        let bill = SavedBill(
            billAmount: 999999.99,
            tipPercentage: 100.0,
            tipAmount: 999999.99,
            totalAmount: 1999999.98,
            numberOfPeople: 100,
            amountPerPerson: 19999.9998
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(bill)

        let decoder = JSONDecoder()
        let decodedBill = try decoder.decode(SavedBill.self, from: data)

        XCTAssertEqual(decodedBill.billAmount, 999999.99, accuracy: 0.01)
        XCTAssertEqual(decodedBill.numberOfPeople, 100)
    }
}
