//
//  EditBillView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/28/25.
//

import SwiftUI

/// View for editing a saved bill entry
struct EditBillView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TipCalculatorViewModel

    let bill: SavedBill

    // Editable state
    @State private var billAmountString: String
    @State private var tipPercentageString: String
    @State private var numberOfPeopleString: String
    @State private var locationName: String
    @State private var notes: String

    // Location picker state
    @State private var showLocationPicker = false

    // Currency setting
    @AppStorage("selectedCurrency") private var selectedCurrency: String = "usd"
    private var currency: Currency { Currency.from(selectedCurrency) }

    init(viewModel: TipCalculatorViewModel, bill: SavedBill) {
        self.viewModel = viewModel
        self.bill = bill

        // Initialize state from bill
        _billAmountString = State(initialValue: String(format: "%.2f", bill.billAmount))
        _tipPercentageString = State(initialValue: String(format: "%.0f", bill.tipPercentage))
        _numberOfPeopleString = State(initialValue: String(bill.numberOfPeople))
        _locationName = State(initialValue: bill.locationName ?? "")
        _notes = State(initialValue: bill.notes ?? "")
    }

    private var billAmount: Double {
        Double(billAmountString) ?? 0
    }

    private var tipPercentage: Double {
        Double(tipPercentageString) ?? 0
    }

    private var numberOfPeople: Int {
        max(1, Int(numberOfPeopleString) ?? 1)
    }

    private var tipAmount: Double {
        billAmount * (tipPercentage / 100.0)
    }

    private var totalAmount: Double {
        billAmount + tipAmount
    }

    private var amountPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return totalAmount / Double(numberOfPeople)
    }

    private var tipPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return tipAmount / Double(numberOfPeople)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.1, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Bill Amount Section
                        editSection(title: "Bill Amount") {
                            HStack {
                                Text("$")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.mint)

                                TextField("0.00", text: $billAmountString)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }

                        // Tip Percentage Section
                        editSection(title: "Tip Percentage") {
                            HStack {
                                TextField("0", text: $tipPercentageString)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)

                                Text("%")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.mint)
                            }

                            // Quick tip buttons
                            HStack(spacing: 12) {
                                ForEach([10, 15, 18, 20, 25], id: \.self) { percent in
                                    Button {
                                        tipPercentageString = String(percent)
                                    } label: {
                                        Text("\(percent)%")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(tipPercentage == Double(percent) ? .black : .white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                tipPercentage == Double(percent)
                                                    ? AnyShapeStyle(LinearGradient(colors: [.mint, .teal], startPoint: .leading, endPoint: .trailing))
                                                    : AnyShapeStyle(Color.white.opacity(0.1))
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Split Section
                        editSection(title: "Split Between") {
                            HStack {
                                Button {
                                    let current = Int(numberOfPeopleString) ?? 1
                                    if current > 1 {
                                        numberOfPeopleString = String(current - 1)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.mint.opacity(numberOfPeople > 1 ? 1 : 0.3))
                                }
                                .disabled(numberOfPeople <= 1)

                                TextField("1", text: $numberOfPeopleString)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)

                                Button {
                                    let current = Int(numberOfPeopleString) ?? 1
                                    numberOfPeopleString = String(current + 1)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.mint)
                                }
                            }
                        }

                        // Location Section
                        editSection(title: "Location") {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.mint)

                                TextField("Restaurant name or address", text: $locationName)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)

                                Button {
                                    showLocationPicker = true
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title3)
                                        .foregroundColor(.mint)
                                }
                            }
                        }

                        // Notes Section
                        editSection(title: "Notes") {
                            TextField("Add a note...", text: $notes, axis: .vertical)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(3...6)
                        }

                        // Summary Preview
                        summarySection

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.mint)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBill()
                    }
                    .font(.headline)
                    .foregroundColor(.mint)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .foregroundColor(.mint)
                    }
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(selectedLocation: $locationName)
            }
        }
    }

    // MARK: - Helper Views

    private func editSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(16)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)

            VStack(spacing: 12) {
                summaryRow(label: "Subtotal", value: formatCurrency(billAmount))
                summaryRow(label: "Tip (\(Int(tipPercentage))%)", value: formatCurrency(tipAmount))

                Divider()
                    .background(Color.white.opacity(0.2))

                summaryRow(label: "Total", value: formatCurrency(totalAmount), isTotal: true)

                if numberOfPeople > 1 {
                    Divider()
                        .background(Color.white.opacity(0.2))

                    VStack(spacing: 4) {
                        summaryRow(label: "Per Person", value: formatCurrency(amountPerPerson), isHighlight: true)
                        HStack {
                            Spacer()
                            Text("(\(formatCurrency(tipPerPerson)) tip)")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private func summaryRow(label: String, value: String, isTotal: Bool = false, isHighlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: isTotal ? 16 : 14, weight: isTotal ? .bold : .medium, design: .rounded))
                .foregroundColor(isHighlight ? .mint : (isTotal ? .white : .white.opacity(0.7)))

            Spacer()

            Text(value)
                .font(.system(size: isTotal ? 20 : 16, weight: isTotal ? .bold : .semibold, design: .rounded))
                .foregroundColor(isHighlight ? .mint : (isTotal ? .white : .mint))
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)0.00"
    }

    // MARK: - Actions

    private func saveBill() {
        var updatedBill = bill
        updatedBill.billAmount = billAmount
        updatedBill.tipPercentage = tipPercentage
        updatedBill.tipAmount = tipAmount
        updatedBill.totalAmount = totalAmount
        updatedBill.numberOfPeople = numberOfPeople
        updatedBill.amountPerPerson = amountPerPerson
        updatedBill.tipPerPerson = tipPerPerson
        updatedBill.locationName = locationName.isEmpty ? nil : locationName
        updatedBill.notes = notes.isEmpty ? nil : notes

        viewModel.updateBill(id: bill.id, with: updatedBill)
        dismiss()
    }
}
