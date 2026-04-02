import SwiftUI
import Combine

/// Main view for pre-ordering stadium food
struct FoodOrderingView: View {
    let game: SportingEvent
    let arrivalTime: Date

    @StateObject private var viewModel: FoodOrderingViewModel
    @Environment(\.dismiss) private var dismiss

    init(game: SportingEvent, arrivalTime: Date) {
        self.game = game
        self.arrivalTime = arrivalTime
        _viewModel = StateObject(wrappedValue: FoodOrderingViewModel(game: game, arrivalTime: arrivalTime))
        print("🍔 FoodOrderingView initialized for game: \(game.displayName)")
    }

    var body: some View {
        content
            .navigationTitle("Pre-Order Food")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadVendors()
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $viewModel.showingVendorMenu) {
                if let vendor = viewModel.selectedVendor {
                    NavigationView {
                        VendorMenuView(
                            vendor: vendor,
                            cart: $viewModel.cart,
                            onDone: {
                                viewModel.showingVendorMenu = false
                            }
                        )
                    }
                }
            }
            #else
            .sheet(isPresented: $viewModel.showingVendorMenu) {
                if let vendor = viewModel.selectedVendor {
                    NavigationView {
                        VendorMenuView(
                            vendor: vendor,
                            cart: $viewModel.cart,
                            onDone: {
                                viewModel.showingVendorMenu = false
                            }
                        )
                    }
                    .frame(minWidth: 700, minHeight: 700)
                }
            }
            #endif
            #if os(iOS)
            .fullScreenCover(isPresented: $viewModel.showingOrderConfirmation) {
                if let order = viewModel.confirmedOrder {
                    OrderConfirmationView(order: order) {
                        dismiss()
                    }
                }
            }
            #else
            .sheet(isPresented: $viewModel.showingOrderConfirmation) {
                if let order = viewModel.confirmedOrder {
                    OrderConfirmationView(order: order) {
                        dismiss()
                    }
                    .frame(minWidth: 600, minHeight: 700)
                }
            }
            #endif
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Game info header
                gameInfoSection
                    .onAppear {
                        print("🍔 Game info section appeared")
                    }

                // Pickup time selection
                if viewModel.pickupTime == nil {
                    pickupTimeSection
                        .onAppear {
                            print("🍔 Pickup time section appeared. Suggestions count: \(viewModel.pickupSuggestions.count)")
                        }
                }

                // Vendor selection (after pickup time chosen)
                if viewModel.pickupTime != nil {
                    if viewModel.isLoading {
                        ProgressView("Loading vendors...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        vendorSection
                    }
                }

                // Cart summary
                if !viewModel.cart.isEmpty {
                    cartSection
                }

                // Place order button
                if viewModel.canPlaceOrder {
                    placeOrderButton
                }
            }
            .padding()
        }
        #if os(iOS)
        .background(Color(.systemGroupedBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
    }

    private var gameInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.displayName)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Label(game.formattedKickoff, systemImage: "clock")
                Spacer()
                Label(game.stadium.name, systemImage: "building.2")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            Group {
                #if os(iOS)
                Color(.systemBackground)
                #else
                Color(nsColor: .windowBackgroundColor)
                #endif
            }
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var pickupTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When do you want to pick up?")
                .font(.headline)

            ForEach(viewModel.pickupSuggestions) { suggestion in
                PickupTimeButton(
                    suggestion: suggestion,
                    onTap: {
                        viewModel.selectPickupTime(suggestion.time)
                    }
                )
            }
        }
    }

    private var vendorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Vendor")
                    .font(.headline)

                if let time = viewModel.pickupTime {
                    Spacer()
                    Text("Pickup: \(time, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.vendors) { vendor in
                    VendorCard(vendor: vendor) {
                        viewModel.selectVendor(vendor)
                    }
                }
            }
        }
    }

    private var cartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Order")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    viewModel.clearCart()
                }
                .font(.subheadline)
                .foregroundColor(.red)
            }

            ForEach(viewModel.cart) { item in
                CartItemRow(item: item) {
                    viewModel.removeFromCart(item)
                }
            }

            Divider()

            VStack(spacing: 4) {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(viewModel.subtotalDisplay)
                }
                .font(.subheadline)

                HStack {
                    Text("Tax")
                    Spacer()
                    Text(viewModel.taxDisplay)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                HStack {
                    Text("Service Fee")
                    Spacer()
                    Text(viewModel.serviceFeeDisplay)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                Divider()

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.totalDisplay)
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(
            Group {
                #if os(iOS)
                Color(.systemBackground)
                #else
                Color(nsColor: .windowBackgroundColor)
                #endif
            }
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var placeOrderButton: some View {
        Button {
            Task {
                await viewModel.placeOrder()
            }
        } label: {
            HStack {
                if viewModel.isPlacingOrder {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "cart.fill")
                    Text("Place Order - \(viewModel.totalDisplay)")
                    Image(systemName: "arrow.right")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isPlacingOrder)
    }
}

// MARK: - Supporting Views

struct PickupTimeButton: View {
    let suggestion: PickupTimeSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(suggestion.label)
                            .font(.headline)
                        if suggestion.isRecommended {
                            Text("RECOMMENDED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }

                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(suggestion.timeDisplay)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                Group {
                    #if os(iOS)
                    Color(.systemBackground)
                    #else
                    Color(nsColor: .windowBackgroundColor)
                    #endif
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(suggestion.isRecommended ? Color.green : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct VendorCard: View {
    let vendor: FoodVendor
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vendor.name)
                            .font(.headline)

                        Text(vendor.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Label(vendor.location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(vendor.ratingDisplay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                Group {
                    #if os(iOS)
                    Color(.systemBackground)
                    #else
                    Color(nsColor: .windowBackgroundColor)
                    #endif
                }
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(item.quantity)x \(item.foodItem.name)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if !item.selectedCustomizations.isEmpty {
                    Text(customizationText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.itemTotalDisplay)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var customizationText: String {
        item.selectedCustomizations
            .map { "\($0.key): \($0.value.joined(separator: ", "))" }
            .joined(separator: " • ")
    }
}

// MARK: - ViewModel

@MainActor
class FoodOrderingViewModel: ObservableObject {
    @Published var vendors: [FoodVendor] = []
    @Published var cart: [CartItem] = []
    @Published var pickupTime: Date?
    @Published var selectedVendor: FoodVendor?
    @Published var isLoading = false
    @Published var isPlacingOrder = false
    @Published var showingVendorMenu = false
    @Published var showingOrderConfirmation = false
    @Published var confirmedOrder: FoodOrder?

    let game: SportingEvent
    let arrivalTime: Date
    let pickupSuggestions: [PickupTimeSuggestion]

    private let foodService = FoodOrderingService.shared

    init(game: SportingEvent, arrivalTime: Date) {
        self.game = game
        self.arrivalTime = arrivalTime
        self.pickupSuggestions = foodService.suggestPickupTimes(
            arrivalTime: arrivalTime,
            kickoffTime: game.kickoffTime
        )
    }

    var canPlaceOrder: Bool {
        return !cart.isEmpty && pickupTime != nil && !isPlacingOrder
    }

    var subtotal: Double {
        cart.reduce(0) { $0 + $1.itemTotal }
    }

    var tax: Double {
        subtotal * 0.08
    }

    var serviceFee: Double {
        cart.isEmpty ? 0 : 1.99
    }

    var total: Double {
        subtotal + tax + serviceFee
    }

    var subtotalDisplay: String {
        String(format: "$%.2f", subtotal)
    }

    var taxDisplay: String {
        String(format: "$%.2f", tax)
    }

    var serviceFeeDisplay: String {
        String(format: "$%.2f", serviceFee)
    }

    var totalDisplay: String {
        String(format: "$%.2f", total)
    }

    func loadVendors() async {
        print("🍔 FoodOrderingViewModel: Starting to load vendors...")
        print("🍔 Stadium ID: \(game.stadium.id)")
        print("🍔 Mock Mode: \(FoodOrderingConfig.useMockMode)")

        isLoading = true

        do {
            vendors = try await foodService.getStadiumVendors(
                stadiumId: game.stadium.id,
                gameDate: game.kickoffTime
            )
            print("🍔 Successfully loaded \(vendors.count) vendors")
        } catch {
            print("❌ Error loading vendors: \(error)")
        }

        isLoading = false
        print("🍔 Loading complete. Vendors count: \(vendors.count)")
    }

    func selectPickupTime(_ time: Date) {
        withAnimation {
            pickupTime = time
        }
    }

    func selectVendor(_ vendor: FoodVendor) {
        selectedVendor = vendor
        showingVendorMenu = true
    }

    func clearCart() {
        withAnimation {
            cart.removeAll()
        }
    }

    func removeFromCart(_ item: CartItem) {
        withAnimation {
            cart.removeAll { $0.id == item.id }
        }
    }

    func placeOrder() async {
        guard let pickupTime = pickupTime, !cart.isEmpty else { return }

        isPlacingOrder = true

        // Create order request
        let orderItems = cart.map { cartItem in
            OrderItemRequest(
                foodItemId: cartItem.foodItem.id,
                quantity: cartItem.quantity,
                customizations: cartItem.selectedCustomizations,
                specialInstructions: cartItem.specialInstructions
            )
        }

        let request = CreateFoodOrderRequest(
            gameScheduleId: nil,
            vendorId: selectedVendor?.id ?? cart.first?.foodItem.id ?? "vendor-001",
            items: orderItems,
            pickupTime: pickupTime,
            specialInstructions: nil,
            paymentMethodId: "pm_mock_payment"
        )

        do {
            let order = try await foodService.createOrder(request: request, cartItems: cart)
            confirmedOrder = order
            showingOrderConfirmation = true
        } catch {
            print("Error placing order: \(error)")
        }

        isPlacingOrder = false
    }
}

#Preview {
    FoodOrderingView(
        game: SportingEvent.sampleEvents[0],
        arrivalTime: Date().addingTimeInterval(3600)
    )
}
