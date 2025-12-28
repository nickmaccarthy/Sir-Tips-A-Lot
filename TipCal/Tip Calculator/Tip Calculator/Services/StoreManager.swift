//
//  StoreManager.swift
//  Tip Calculator
//
//  Created by Nick MacCarthy on 12/26/25.
//

import Foundation
import StoreKit

/// Purchase state for tracking transaction progress
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case purchased
    case failed(String)
    case cancelled
}

/// Manages StoreKit 2 In-App Purchases for the Tip Jar
@MainActor
class StoreManager: ObservableObject {

    // MARK: - Published Properties

    /// Available products fetched from the App Store
    @Published private(set) var products: [Product] = []

    /// Current purchase state
    @Published var purchaseState: PurchaseState = .idle

    /// Indicates if products are being loaded
    @Published private(set) var isLoading: Bool = false

    /// Error message if product loading fails
    @Published private(set) var errorMessage: String?

    // MARK: - Private Properties

    /// Task for listening to transaction updates
    private var transactionListener: Task<Void, Error>?

    // MARK: - Initialization

    init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()

        // Fetch products on init
        Task {
            await loadProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public Methods

    /// Loads products from the App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: TipProduct.allProductIDs)

            // Sort products by price
            products = storeProducts.sorted { $0.price < $1.price }

            if products.isEmpty {
                errorMessage = "No products available"
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("StoreManager: Failed to load products - \(error)")
        }

        isLoading = false
    }

    /// Purchases a product
    /// - Parameter product: The product to purchase
    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified, finish it
                    await transaction.finish()
                    purchaseState = .purchased
                    triggerSuccessHaptic()

                case .unverified(_, let error):
                    purchaseState = .failed("Purchase verification failed: \(error.localizedDescription)")
                }

            case .pending:
                // Transaction is pending (e.g., parental approval)
                purchaseState = .idle

            case .userCancelled:
                purchaseState = .cancelled

            @unknown default:
                purchaseState = .failed("Unknown purchase result")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            print("StoreManager: Purchase failed - \(error)")
        }
    }

    /// Resets the purchase state to idle
    func resetPurchaseState() {
        purchaseState = .idle
    }

    /// Gets the TipProduct enum case for a StoreKit Product
    func tipProduct(for product: Product) -> TipProduct? {
        TipProduct(rawValue: product.id)
    }

    // MARK: - Private Methods

    /// Listens for transaction updates (e.g., interrupted purchases)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    await transaction.finish()
                } catch {
                    print("StoreManager: Transaction verification failed - \(error)")
                }
            }
        }
    }

    /// Verifies a transaction result
    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signedType):
            return signedType
        case .unverified(_, let error):
            throw error
        }
    }

    /// Triggers haptic feedback on successful purchase
    private func triggerSuccessHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}
