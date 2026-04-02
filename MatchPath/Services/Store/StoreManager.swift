import Foundation
import StoreKit
import Combine

/// Manager for handling In-App Purchases using StoreKit 2
@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    // Product IDs
    enum ProductID: String, CaseIterable {
        case schedule = "com.matchpath.schedule"

        var displayName: String {
            switch self {
            case .schedule:
                return "Game Day Schedule"
            }
        }
    }

    // MARK: - Published Properties

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedSchedules: Set<String> = [] // Schedule IDs
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Transaction Listener

    private var transactionListener: Task<Void, Error>?

    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load products from App Store
            let storeProducts = try await Product.products(for: ProductID.allCases.map { $0.rawValue })

            await MainActor.run {
                self.products = storeProducts.sorted { $0.displayName < $1.displayName }
                self.isLoading = false
            }

            print("✅ StoreManager: Loaded \(storeProducts.count) products")
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ StoreManager: Failed to load products - \(error)")
        }
    }

    // MARK: - Purchase Flow

    /// Purchase a schedule for a specific game
    func purchaseSchedule(for game: SportingEvent) async -> Bool {
        guard let product = products.first(where: { $0.id == ProductID.schedule.rawValue }) else {
            errorMessage = "Product not available"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Unlock content
                _ = await MainActor.run {
                    self.purchasedSchedules.insert(game.id)
                }

                // Finish the transaction
                await transaction.finish()

                await MainActor.run {
                    self.isLoading = false
                }

                print("✅ StoreManager: Purchase successful for game \(game.id)")
                return true

            case .userCancelled:
                await MainActor.run {
                    self.isLoading = false
                }
                print("ℹ️ StoreManager: User cancelled purchase")
                return false

            case .pending:
                await MainActor.run {
                    self.errorMessage = "Purchase is pending approval"
                    self.isLoading = false
                }
                print("⏳ StoreManager: Purchase pending")
                return false

            @unknown default:
                await MainActor.run {
                    self.errorMessage = "Unknown purchase result"
                    self.isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Purchase failed: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ StoreManager: Purchase failed - \(error)")
            return false
        }
    }

    /// Check if user has purchased a schedule for this game
    func hasPurchasedSchedule(for gameId: String) -> Bool {
        return purchasedSchedules.contains(gameId)
    }

    // MARK: - Transaction Verification

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Update purchased products
                    await self.updatePurchasedProducts()

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("❌ StoreManager: Transaction verification failed - \(error)")
                }
            }
        }
    }

    // MARK: - Update Purchased Products

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // For consumables, we track by game ID in local storage
                // In production, you'd verify against your backend
                if transaction.productID == ProductID.schedule.rawValue {
                    // Load purchased schedule IDs from local storage
                    if let savedSchedules = UserDefaults.standard.array(forKey: "PurchasedScheduleIDs") as? [String] {
                        purchased = Set(savedSchedules)
                    }
                }
            } catch {
                print("❌ StoreManager: Failed to verify transaction - \(error)")
            }
        }

        await MainActor.run {
            self.purchasedSchedules = purchased
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            await MainActor.run {
                self.isLoading = false
            }

            print("✅ StoreManager: Purchases restored")
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ StoreManager: Failed to restore purchases - \(error)")
        }
    }

    // MARK: - Helper Methods

    /// Get display price for schedule product
    var schedulePrice: String {
        if let product = products.first(where: { $0.id == ProductID.schedule.rawValue }) {
            return product.displayPrice
        }
        return "Free" // App is free
    }

    /// Save purchased schedule ID to local storage
    func recordSchedulePurchase(scheduleId: String) {
        var purchased = UserDefaults.standard.array(forKey: "PurchasedScheduleIDs") as? [String] ?? []
        if !purchased.contains(scheduleId) {
            purchased.append(scheduleId)
            UserDefaults.standard.set(purchased, forKey: "PurchasedScheduleIDs")
        }
        purchasedSchedules.insert(scheduleId)
    }
}

// MARK: - Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found in App Store"
        }
    }
}
