//
//  TipCalculatorViewModelTests.swift
//  Tip CalculatorTests
//
//  Created by Nick MacCarthy on 12/26/25.
//

import XCTest
@testable import Tip_Calculator

final class TipCalculatorViewModelTests: XCTestCase {

    var viewModel: TipCalculatorViewModel!

    override func setUp() {
        super.setUp()
        viewModel = TipCalculatorViewModel()
        // Clear any persisted data for clean tests
        UserDefaults.standard.removeObject(forKey: "recentBills")
    }

    override func tearDown() {
        viewModel = nil
        UserDefaults.standard.removeObject(forKey: "recentBills")
        super.tearDown()
    }

    // MARK: - Bill Value Tests

    func testBillValue_withValidInput_returnsCorrectValue() {
        viewModel.billAmountString = "50.00"
        XCTAssertEqual(viewModel.billValue, 50.0, accuracy: 0.001)
    }

    func testBillValue_withEmptyInput_returnsZero() {
        viewModel.billAmountString = ""
        XCTAssertEqual(viewModel.billValue, 0.0, accuracy: 0.001)
    }

    func testBillValue_withInvalidInput_returnsZero() {
        viewModel.billAmountString = "abc"
        XCTAssertEqual(viewModel.billValue, 0.0, accuracy: 0.001)
    }

    func testBillValue_withDecimalInput_returnsCorrectValue() {
        viewModel.billAmountString = "123.45"
        XCTAssertEqual(viewModel.billValue, 123.45, accuracy: 0.001)
    }

    // MARK: - Effective Tip Percentage Tests

    func testEffectiveTipPercentage_withPresetTip_returnsSelectedPercentage() {
        viewModel.selectedTipPercentage = 20.0
        viewModel.isCustomTipSelected = false
        XCTAssertEqual(viewModel.effectiveTipPercentage, 20.0, accuracy: 0.001)
    }

    func testEffectiveTipPercentage_withCustomTip_returnsCustomPercentage() {
        viewModel.isCustomTipSelected = true
        viewModel.customTipString = "25"
        XCTAssertEqual(viewModel.effectiveTipPercentage, 25.0, accuracy: 0.001)
    }

    func testEffectiveTipPercentage_withInvalidCustomTip_returnsZero() {
        viewModel.isCustomTipSelected = true
        viewModel.customTipString = "invalid"
        XCTAssertEqual(viewModel.effectiveTipPercentage, 0.0, accuracy: 0.001)
    }

    func testEffectiveTipPercentage_withEmptyCustomTip_returnsZero() {
        viewModel.isCustomTipSelected = true
        viewModel.customTipString = ""
        XCTAssertEqual(viewModel.effectiveTipPercentage, 0.0, accuracy: 0.001)
    }

    // MARK: - Tip Amount Tests

    func testTipAmount_withoutRounding_returnsExactAmount() {
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 15.0
        viewModel.roundUp = false
        XCTAssertEqual(viewModel.tipAmount, 15.0, accuracy: 0.001)
    }

    func testTipAmount_withRounding_returnsCeiledAmount() {
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 17.0
        viewModel.roundUp = true
        // 17% of 100 = 17.0, ceil(17.0) = 17.0
        XCTAssertEqual(viewModel.tipAmount, 17.0, accuracy: 0.001)
    }

    func testTipAmount_withRoundingFractionalTip_returnsCeiledAmount() {
        viewModel.billAmountString = "45.67"
        viewModel.selectedTipPercentage = 18.0
        viewModel.roundUp = true
        // 18% of 45.67 = 8.2206, ceil = 9.0
        XCTAssertEqual(viewModel.tipAmount, 9.0, accuracy: 0.001)
    }

    func testTipAmountBeforeRounding_returnsExactCalculation() {
        viewModel.billAmountString = "45.67"
        viewModel.selectedTipPercentage = 18.0
        let expected = 45.67 * 0.18
        XCTAssertEqual(viewModel.tipAmountBeforeRounding, expected, accuracy: 0.001)
    }

    // MARK: - Total Amount Tests

    func testTotalAmount_calculatesCorrectly() {
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 20.0
        viewModel.roundUp = false
        XCTAssertEqual(viewModel.totalAmount, 120.0, accuracy: 0.001)
    }

    func testTotalAmount_withZeroBill_returnsZero() {
        viewModel.billAmountString = "0"
        viewModel.selectedTipPercentage = 20.0
        XCTAssertEqual(viewModel.totalAmount, 0.0, accuracy: 0.001)
    }

    func testTotalAmount_withRounding_includesRoundedTip() {
        viewModel.billAmountString = "45.67"
        viewModel.selectedTipPercentage = 18.0
        viewModel.roundUp = true
        // Bill: 45.67 + Tip (ceil(8.2206) = 9.0) = 54.67
        XCTAssertEqual(viewModel.totalAmount, 54.67, accuracy: 0.001)
    }

    // MARK: - Number of People Tests

    func testNumberOfPeopleValue_withValidInput_returnsCorrectValue() {
        viewModel.numberOfPeopleString = "4"
        XCTAssertEqual(viewModel.numberOfPeopleValue, 4)
    }

    func testNumberOfPeopleValue_withInvalidInput_returnsOne() {
        viewModel.numberOfPeopleString = "abc"
        XCTAssertEqual(viewModel.numberOfPeopleValue, 1)
    }

    func testNumberOfPeopleValue_withZero_returnsOne() {
        viewModel.numberOfPeopleString = "0"
        XCTAssertEqual(viewModel.numberOfPeopleValue, 1)
    }

    func testNumberOfPeopleValue_withNegative_returnsOne() {
        viewModel.numberOfPeopleString = "-3"
        XCTAssertEqual(viewModel.numberOfPeopleValue, 1)
    }

    func testNumberOfPeopleValue_withEmpty_returnsOne() {
        viewModel.numberOfPeopleString = ""
        XCTAssertEqual(viewModel.numberOfPeopleValue, 1)
    }

    // MARK: - Amount Per Person Tests

    func testAmountPerPerson_withMultiplePeople_splitsEvenly() {
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 20.0
        viewModel.numberOfPeopleString = "4"
        // Total: 120, Per person: 30
        XCTAssertEqual(viewModel.amountPerPerson, 30.0, accuracy: 0.001)
    }

    func testAmountPerPerson_withOnePerson_returnsTotal() {
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 20.0
        viewModel.numberOfPeopleString = "1"
        XCTAssertEqual(viewModel.amountPerPerson, 120.0, accuracy: 0.001)
    }

    func testAmountPerPerson_withUnevenSplit_calculatesCorrectly() {
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 20.0
        viewModel.numberOfPeopleString = "3"
        // Total: 120, Per person: 40
        XCTAssertEqual(viewModel.amountPerPerson, 40.0, accuracy: 0.001)
    }

    // MARK: - Tip Selection Tests

    func testSelectTipPercentage_updatesSelectedPercentage() {
        viewModel.selectTipPercentage(25.0)
        XCTAssertEqual(viewModel.selectedTipPercentage, 25.0, accuracy: 0.001)
        XCTAssertFalse(viewModel.isCustomTipSelected)
    }

    func testSelectTipPercentage_disablesCustomTip() {
        viewModel.isCustomTipSelected = true
        viewModel.selectTipPercentage(20.0)
        XCTAssertFalse(viewModel.isCustomTipSelected)
    }

    func testSelectTipWithSentiment_updatesPercentageAndSentiment() {
        viewModel.selectTipWithSentiment(15.0, sentiment: "😢")
        XCTAssertEqual(viewModel.selectedTipPercentage, 15.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.selectedSentiment, "😢")
        XCTAssertFalse(viewModel.isCustomTipSelected)
    }

    func testSelectCustomTip_enablesCustomMode() {
        viewModel.selectCustomTip()
        XCTAssertTrue(viewModel.isCustomTipSelected)
        XCTAssertNil(viewModel.selectedSentiment)
    }

    // MARK: - Bill History Tests

    func testSaveBill_addsToHistory() {
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill()

        XCTAssertEqual(viewModel.recentBills.count, 1)
        XCTAssertEqual(viewModel.recentBills.first?.billAmount, 50.0)
    }

    func testSaveBill_withZeroBill_doesNotSave() {
        viewModel.billAmountString = "0"
        viewModel.saveBill()

        XCTAssertTrue(viewModel.recentBills.isEmpty)
    }

    func testSaveBill_prependsNewBill() {
        viewModel.billAmountString = "50"
        viewModel.saveBill()

        viewModel.billAmountString = "100"
        viewModel.saveBill()

        XCTAssertEqual(viewModel.recentBills.count, 2)
        XCTAssertEqual(viewModel.recentBills.first?.billAmount, 100.0)
        XCTAssertEqual(viewModel.recentBills.last?.billAmount, 50.0)
    }

    func testDeleteBill_removesFromHistory() {
        viewModel.billAmountString = "50"
        viewModel.saveBill()
        viewModel.billAmountString = "100"
        viewModel.saveBill()

        viewModel.deleteBill(at: IndexSet(integer: 0))

        XCTAssertEqual(viewModel.recentBills.count, 1)
        XCTAssertEqual(viewModel.recentBills.first?.billAmount, 50.0)
    }

    func testClearHistory_removesAllBills() {
        viewModel.billAmountString = "50"
        viewModel.saveBill()
        viewModel.billAmountString = "100"
        viewModel.saveBill()

        viewModel.clearHistory()

        XCTAssertTrue(viewModel.recentBills.isEmpty)
    }

    // MARK: - Edge Cases

    func testLargeBillAmount_calculatesCorrectly() {
        viewModel.billAmountString = "9999.99"
        viewModel.selectedTipPercentage = 20.0
        viewModel.numberOfPeopleString = "10"

        let expectedTip = 9999.99 * 0.20
        let expectedTotal = 9999.99 + expectedTip
        let expectedPerPerson = expectedTotal / 10

        XCTAssertEqual(viewModel.tipAmount, expectedTip, accuracy: 0.01)
        XCTAssertEqual(viewModel.totalAmount, expectedTotal, accuracy: 0.01)
        XCTAssertEqual(viewModel.amountPerPerson, expectedPerPerson, accuracy: 0.01)
    }

    func testZeroTipPercentage_resultsInNoTip() {
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 0.0

        XCTAssertEqual(viewModel.tipAmount, 0.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.totalAmount, 100.0, accuracy: 0.001)
    }

    // MARK: - Lifetime Statistics Tests

    func testLifetimeTips_withNoBills_returnsZero() {
        viewModel.clearHistory()
        XCTAssertEqual(viewModel.lifetimeTips, 0.0, accuracy: 0.001)
    }

    func testLifetimeTips_withBills_returnsSumOfTips() {
        viewModel.clearHistory()

        // Save first bill: $50 with 20% tip = $10 tip
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill()

        // Save second bill: $100 with 15% tip = $15 tip
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 15.0
        viewModel.saveBill()

        // Total tips: $10 + $15 = $25
        XCTAssertEqual(viewModel.lifetimeTips, 25.0, accuracy: 0.001)
    }

    func testLifetimeSpend_withNoBills_returnsZero() {
        viewModel.clearHistory()
        XCTAssertEqual(viewModel.lifetimeSpend, 0.0, accuracy: 0.001)
    }

    func testLifetimeSpend_withBills_returnsSumOfTotals() {
        viewModel.clearHistory()

        // Save first bill: $50 + $10 tip = $60 total
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill()

        // Save second bill: $100 + $15 tip = $115 total
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 15.0
        viewModel.saveBill()

        // Total spend: $60 + $115 = $175
        XCTAssertEqual(viewModel.lifetimeSpend, 175.0, accuracy: 0.001)
    }

    func testLifetimeStats_updateAfterDeletion() {
        viewModel.clearHistory()

        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill()

        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 15.0
        viewModel.saveBill()

        // Delete the most recent bill ($100 with $15 tip)
        viewModel.deleteBill(at: IndexSet(integer: 0))

        // Only the $50 bill remains: $10 tip, $60 total
        XCTAssertEqual(viewModel.lifetimeTips, 10.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.lifetimeSpend, 60.0, accuracy: 0.001)
    }

    func testLifetimeStats_resetAfterClear() {
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill()

        viewModel.clearHistory()

        XCTAssertEqual(viewModel.lifetimeTips, 0.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.lifetimeSpend, 0.0, accuracy: 0.001)
    }

    // MARK: - Reset All Tests

    func testResetAll_clearsBillAmount() {
        viewModel.billAmountString = "123.45"
        viewModel.resetAll()
        XCTAssertEqual(viewModel.billAmountString, "")
    }

    func testResetAll_resetsNumberOfPeopleToOne() {
        viewModel.numberOfPeopleString = "5"
        viewModel.resetAll()
        XCTAssertEqual(viewModel.numberOfPeopleString, "1")
    }

    func testResetAll_disablesRoundUp() {
        viewModel.roundUp = true
        viewModel.resetAll()
        XCTAssertFalse(viewModel.roundUp)
    }

    func testResetAll_disablesCustomTip() {
        viewModel.isCustomTipSelected = true
        viewModel.customTipString = "25"
        viewModel.resetAll()
        XCTAssertFalse(viewModel.isCustomTipSelected)
        XCTAssertEqual(viewModel.customTipString, "")
    }

    func testResetAll_setsSentimentToOk() {
        viewModel.selectedSentiment = "good"
        viewModel.resetAll()
        XCTAssertEqual(viewModel.selectedSentiment, "ok")
    }

    func testResetAll_resetsAllFieldsAtOnce() {
        // Set up a fully configured state
        viewModel.billAmountString = "99.99"
        viewModel.numberOfPeopleString = "4"
        viewModel.roundUp = true
        viewModel.isCustomTipSelected = true
        viewModel.customTipString = "30"
        viewModel.selectedSentiment = "bad"

        viewModel.resetAll()

        // Verify everything is reset
        XCTAssertEqual(viewModel.billAmountString, "")
        XCTAssertEqual(viewModel.numberOfPeopleString, "1")
        XCTAssertFalse(viewModel.roundUp)
        XCTAssertFalse(viewModel.isCustomTipSelected)
        XCTAssertEqual(viewModel.customTipString, "")
        XCTAssertEqual(viewModel.selectedSentiment, "ok")
    }

    // MARK: - Save Bill with Location and Sentiment Tests

    func testSaveBill_withLocationName_savesLocation() {
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill(locationName: "Joe's Pizza", sentimentEmoji: nil)

        XCTAssertEqual(viewModel.recentBills.first?.locationName, "Joe's Pizza")
    }

    func testSaveBill_withSentimentEmoji_savesSentiment() {
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill(locationName: nil, sentimentEmoji: "🤩")

        XCTAssertEqual(viewModel.recentBills.first?.sentiment, "🤩")
    }

    func testSaveBill_withLocationAndSentiment_savesBoth() {
        viewModel.billAmountString = "75"
        viewModel.selectedTipPercentage = 18.0
        viewModel.saveBill(locationName: "Olive Garden", sentimentEmoji: "😐")

        let savedBill = viewModel.recentBills.first
        XCTAssertEqual(savedBill?.locationName, "Olive Garden")
        XCTAssertEqual(savedBill?.sentiment, "😐")
    }

    func testSaveBill_withoutLocationOrSentiment_savesNil() {
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill()

        let savedBill = viewModel.recentBills.first
        XCTAssertNil(savedBill?.locationName)
        XCTAssertNil(savedBill?.sentiment)
    }

    // MARK: - Save Bill with Notes Tests

    func testSaveBill_withNotes_savesNotes() {
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill(locationName: nil, sentimentEmoji: nil, notes: "Great service!")

        XCTAssertEqual(viewModel.recentBills.first?.notes, "Great service!")
    }

    func testSaveBill_withAllOptionalFields_savesAllFields() {
        viewModel.billAmountString = "100"
        viewModel.selectedTipPercentage = 25.0
        viewModel.saveBill(
            locationName: "Fancy Restaurant",
            sentimentEmoji: "🤩",
            notes: "Anniversary dinner, excellent experience!"
        )

        let savedBill = viewModel.recentBills.first
        XCTAssertEqual(savedBill?.locationName, "Fancy Restaurant")
        XCTAssertEqual(savedBill?.sentiment, "🤩")
        XCTAssertEqual(savedBill?.notes, "Anniversary dinner, excellent experience!")
    }

    func testSaveBill_withEmptyNotes_savesEmptyString() {
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill(locationName: nil, sentimentEmoji: nil, notes: "")

        // Empty string should still be saved as empty string, not nil
        XCTAssertEqual(viewModel.recentBills.first?.notes, "")
    }

    func testSaveBill_withoutNotes_savesNilNotes() {
        viewModel.billAmountString = "50"
        viewModel.selectedTipPercentage = 20.0
        viewModel.saveBill(locationName: "Pizza Place", sentimentEmoji: "😐")

        XCTAssertNil(viewModel.recentBills.first?.notes)
    }

    // MARK: - Note Text State Tests

    func testNoteText_initialValue_isEmpty() {
        XCTAssertEqual(viewModel.noteText, "")
    }

    func testResetAll_clearsNoteText() {
        viewModel.noteText = "Some notes here"
        viewModel.resetAll()
        XCTAssertEqual(viewModel.noteText, "")
    }

    func testNoteText_canBeSet() {
        viewModel.noteText = "Test note"
        XCTAssertEqual(viewModel.noteText, "Test note")
    }
}
