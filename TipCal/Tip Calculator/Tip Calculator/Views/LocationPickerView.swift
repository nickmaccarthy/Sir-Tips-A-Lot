//
//  LocationPickerView.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/28/25.
//

import SwiftUI
import MapKit

/// View for searching and selecting a location/restaurant name
struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: String

    @StateObject private var searchCompleter = LocationSearchCompleter()
    @State private var searchText = ""

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

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        TextField("Search restaurants, cafes...", text: $searchText)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .onChange(of: searchText) { _, newValue in
                                searchCompleter.search(query: newValue)
                            }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchCompleter.results = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    if searchCompleter.results.isEmpty && !searchText.isEmpty {
                        // No results state
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.3))

                            Text("No Results")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))

                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.4))

                            // Use custom text button
                            Button {
                                selectedLocation = searchText
                                dismiss()
                            } label: {
                                Text("Use \"\(searchText)\"")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.mint, Color.teal],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                        }

                        Spacer()
                    } else if searchCompleter.results.isEmpty {
                        // Empty state
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.3))

                            Text("Search for a Location")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))

                            Text("Find restaurants, cafes, or enter any address")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Spacer()
                    } else {
                        // Results list
                        List {
                            ForEach(searchCompleter.results, id: \.self) { result in
                                Button {
                                    selectResult(result)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.mint)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.title)
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(.white)

                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .listRowBackground(Color.white.opacity(0.05))
                                .listRowSeparatorTint(Color.white.opacity(0.1))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
        }
    }

    private func selectResult(_ result: MKLocalSearchCompletion) {
        // Use the title as the location name
        selectedLocation = result.title
        dismiss()
    }
}

// MARK: - Location Search Completer

/// Observable object that wraps MKLocalSearchCompleter for SwiftUI
class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]

        // Filter for food-related POIs when possible
        if #available(iOS 16.0, *) {
            completer.pointOfInterestFilter = MKPointOfInterestFilter(including: [
                .restaurant,
                .cafe,
                .bakery,
                .brewery,
                .winery,
                .nightlife,
                .foodMarket
            ])
        }
    }

    func search(query: String) {
        completer.queryFragment = query
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer failed: \(error.localizedDescription)")
    }
}
