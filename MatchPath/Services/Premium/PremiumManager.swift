import Foundation
import Combine
import StoreKit

/// Manages premium features and In-App Purchase using StoreKit 2
/// Free tier: 1 schedule, basic features
/// Premium: Unlimited schedules, AI chatbot, real-time crowd data, advanced features
@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    // MARK: - Published Properties

    /// Set to true to give all users free access (no paywall)
    /// Set to false when IAP products are configured in App Store Connect
    private static let FREE_ACCESS_FOR_ALL = true

    @Published var isPremium: Bool = FREE_ACCESS_FOR_ALL
    @Published var isProcessingPurchase: Bool = false
    @Published var errorMessage: String? = nil
    @Published private(set) var product: Product?

    // MARK: - Constants

    /// Free tier schedule limit
    static let FREE_SCHEDULE_LIMIT = 1

    /// Product ID for In-App Purchase
    private let premiumProductID = "com.matchpath.premium"

    /// Transaction listener
    private var transactionListener: Task<Void, Error>?

    // MARK: - Computed Properties

    /// Get display price from StoreKit (dynamic)
    static var PREMIUM_PRICE: String {
        shared.product?.displayPrice ?? "Free"
    }

    // MARK: - Initialization

    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()

        Task {
            await loadProduct()
            await updatePurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    /// Load the premium product from App Store
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [premiumProductID])
            if let premiumProduct = products.first {
                self.product = premiumProduct
                print("💎 Premium product loaded: \(premiumProduct.displayPrice)")
            }
        } catch {
            print("❌ Failed to load premium product: \(error)")
        }
    }

    // MARK: - Premium Status

    /// Check if user has premium access
    var hasPremiumAccess: Bool {
        return isPremium
    }

    /// Update purchase status from App Store
    private func updatePurchaseStatus() async {
        // If free access mode is enabled, always grant premium
        if Self.FREE_ACCESS_FOR_ALL {
            isPremium = true
            return
        }

        // Check for active subscription/purchase
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == premiumProductID {
                    isPremium = true
                    print("💎 Premium status verified: active")
                    return
                }
            } catch {
                print("❌ Transaction verification failed: \(error)")
            }
        }
        isPremium = false
        print("💎 Premium status: not active")
    }

    /// Verify transaction
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updatePurchaseStatus()
                    await transaction?.finish()
                } catch {
                    print("❌ Transaction update failed: \(error)")
                }
            }
        }
    }

    // MARK: - Schedule Limits

    /// Check if user can create a new schedule
    func canCreateSchedule(currentCount: Int) -> Bool {
        if isPremium {
            return true // Unlimited for premium
        }
        return currentCount < Self.FREE_SCHEDULE_LIMIT
    }

    /// Get remaining free schedules
    func remainingFreeSchedules(currentCount: Int) -> Int {
        if isPremium {
            return Int.max // Unlimited
        }
        let remaining = Self.FREE_SCHEDULE_LIMIT - currentCount
        return max(0, remaining)
    }

    // MARK: - Feature Gates

    /// Check if AI Chatbot is available
    var canAccessAIChatbot: Bool {
        return isPremium
    }

    /// Check if real-time crowd intelligence is available
    var canAccessRealTimeCrowdData: Bool {
        return isPremium
    }

    /// Check if indoor AR compass is available
    var canAccessIndoorCompass: Bool {
        return isPremium
    }

    /// Check if advanced parking optimization is available
    var canAccessParkingOptimization: Bool {
        return isPremium
    }

    // MARK: - Purchase Flow

    /// Initiate premium purchase using StoreKit 2
    func purchasePremium() async throws {
        guard let product = product else {
            // Try to load product if not available
            await loadProduct()
            guard let product = self.product else {
                throw StoreError.productNotFound
            }
            try await performPurchase(product)
            return
        }

        try await performPurchase(product)
    }

    private func performPurchase(_ product: Product) async throws {
        isProcessingPurchase = true
        errorMessage = nil

        print("💎 Initiating premium purchase...")

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchaseStatus()
                await transaction.finish()
                isProcessingPurchase = false
                print("✅ Premium purchase successful!")

            case .userCancelled:
                isProcessingPurchase = false
                print("ℹ️ User cancelled purchase")

            case .pending:
                isProcessingPurchase = false
                errorMessage = "Purchase is pending approval"
                print("⏳ Purchase pending approval")

            @unknown default:
                isProcessingPurchase = false
                throw StoreError.productNotFound
            }
        } catch {
            isProcessingPurchase = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Restore previous purchases using StoreKit 2
    func restorePurchases() async throws {
        isProcessingPurchase = true
        errorMessage = nil

        print("🔄 Restoring purchases...")

        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
            isProcessingPurchase = false

            if isPremium {
                print("✅ Purchases restored successfully!")
            } else {
                print("ℹ️ No previous purchases found")
            }
        } catch {
            isProcessingPurchase = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Development Helpers

    #if DEBUG
    /// Toggle premium status for testing (DEBUG only)
    func togglePremiumForTesting() {
        isPremium = !isPremium
    }

    /// Reset premium status for testing (DEBUG only)
    func resetPremiumForTesting() {
        isPremium = false
    }
    #endif

    // MARK: - Messaging

    /// Get upgrade message for feature
    func upgradeMessage(for feature: PremiumFeature) -> String {
        switch feature {
        case .unlimitedSchedules:
            return "Upgrade to Premium for unlimited schedules"
        case .aiChatbot:
            return "Unlock AI Assistant with Premium"
        case .realTimeCrowdData:
            return "Get real-time crowd intelligence with Premium"
        case .indoorCompass:
            return "Access AR Indoor Compass with Premium"
        case .parkingOptimization:
            return "Unlock advanced parking with Premium"
        }
    }

    /// Get feature list for paywall
    func getPremiumFeatures() -> [PremiumFeatureDescription] {
        return [
            PremiumFeatureDescription(
                icon: "calendar.badge.plus",
                title: "Unlimited Schedules",
                description: "Create schedules for all your games",
                color: "blue"
            ),
            PremiumFeatureDescription(
                icon: "message.badge.fill",
                title: "AI Assistant",
                description: "Smart chatbot for game day help",
                color: "purple"
            ),
            PremiumFeatureDescription(
                icon: "person.3.fill",
                title: "Real-Time Crowds",
                description: "Live gate & transit crowd data",
                color: "orange"
            ),
            PremiumFeatureDescription(
                icon: "safari",
                title: "AR Indoor Compass",
                description: "Navigate inside the stadium",
                color: "green"
            ),
            PremiumFeatureDescription(
                icon: "parkingsign.circle.fill",
                title: "Parking Optimization",
                description: "Find best parking spots",
                color: "indigo"
            ),
            PremiumFeatureDescription(
                icon: "bell.badge.fill",
                title: "Priority Notifications",
                description: "Never miss important updates",
                color: "red"
            )
        ]
    }
}

// MARK: - Supporting Types

enum PremiumFeature {
    case unlimitedSchedules
    case aiChatbot
    case realTimeCrowdData
    case indoorCompass
    case parkingOptimization
}

struct PremiumFeatureDescription: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: String
}
