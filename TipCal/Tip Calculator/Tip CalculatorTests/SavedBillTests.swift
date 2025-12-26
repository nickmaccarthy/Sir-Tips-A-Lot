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

