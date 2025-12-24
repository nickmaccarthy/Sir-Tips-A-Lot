# PLAN: App Store Approval Overhaul (Sir Tips-A-Lot)

## Context
The iOS application "Sir Tips-A-Lot" was rejected by Apple App Review under **Guideline 4.2 (Minimum Functionality)**. The reviewer stated the app is primarily a utility that replicates a standard calculator or website.

## Objective
To approve the application, we must transform it from a "stateless calculator" into a "native iOS experience" by integrating features that:
1.  Utilize native hardware (Haptic engines).
2.  Integrate with the OS ecosystem (Share Sheet).
3.  Persist user data (History/State).

## Tech Stack
* **Language:** Swift 5.9+
* **Framework:** SwiftUI
* **Minimum OS:** iOS 17.0

---

## Implementation Roadmap

### Step 1: Rename this app to "Sir Tips Alot"
* **Goal:**: Rename the app in Xcode and on the iphone to "Sir Tips Alot"
* **Instructions:**
    1. Rename this app to "Sir Tips Alot"
    2. Ensure its changed on the iphone app
        2.1 Verify this in Xcode using the iphone simulator
    3. Ensure its changed in Xcode as well

### Step 2: Add Sensory Feedback (Haptics)
* **Goal:** Make the app feel physical and distinct from a web view.
* **Action:** Implement `UIImpactFeedbackGenerator`.
* **Files:** `ContentView.swift`
* **Instructions:**
    1.  Create a helper function `triggerHaptic(style: .medium)`.
    2.  Call this function whenever the user:
        * Interacts with the Bill Amount text field.
        * Changes the Tip Percentage (Slider/Button).
        * Increments/Decrements the "Split" stepper.

### Step 3: Implement "Share Split" Feature
* **Goal:** Deep system integration. Allow users to send the calculated split to friends via iMessage/etc.
* **Action:** Add a `ShareLink` or `UIActivityViewController`.
* **Files:** `ContentView.swift`
* **Instructions:**
    1.  Create a computed property or function that generates a formatted string: 
        * *"Bill: [Total] | Tip: [TipAmount] | Total: [GrandTotal] | You owe: [SplitAmount] via Sir Tips-A-Lot"*
    2.  Add a standard iOS Share icon button (SF Symbol `square.and.arrow.up`) near the "Total per Person" display.

### Step 4: Data Persistence (History)
* **Goal:** Differentiate the app from a calculator by giving it "memory."
* **Action:** Persist the last 10 calculations using `UserDefaults` (simplest) or `SwiftData`.
* **Files:** * New File: `Models/SavedBill.swift` (Struct: ID, Date, Total, Tip, Split)
    * Modify: `TipCalculatorViewModel.swift`
    * Modify: `ContentView.swift`
* **Instructions:**
    1.  Create `SavedBill` struct conforming to `Codable` and `Identifiable`.
    2.  In `ViewModel`, add an array `@Published var recentBills: [SavedBill]`.
    3.  Create a function `saveBill()` that appends the current state to the array and saves to UserDefaults.
    4.  Add a "Save" button to the main UI (or auto-save when Share is clicked).
    5.  Create a `HistoryView` (Sheet) to display the list of recent bills.

### Step 5: Submission Cleanup
* **Goal:** Remove friction points for the reviewer.
* **Action:** Temporarily hide the "Tip Jar" / Donation section.
* **Files:** `ContentView.swift`
* **Instructions:**
    1.  Comment out or use a compiler flag to hide the Tip Jar section/buttons. 
    2.  *Note: Apple sometimes views donation buttons on simple utility apps as "spammy" during the first review.*

---

## Prompting Guide for Cursor/Claude
* **To start Step 1:** "Review ContentView.swift and implement the haptic feedback detailed in Step 1 of the PLAN."
* **To start Step 3:** "Create the SavedBill model and update the ViewModel to handle saving/loading history as described in Step 3."