import Foundation
import CoreLocation

// MARK: - Menu & Food Items

struct FoodVendor: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let location: String // e.g., "Section 120, Gate B"
    let coordinate: Coordinate
    let logoURL: String?
    let rating: Double // 1.0 - 5.0
    let reviewCount: Int
    let categories: [FoodCategory]
    let operatingHours: OperatingHours
    let acceptsPreOrders: Bool
    let estimatedPrepTimeMinutes: Int
    let minimumOrder: Double?
    let deliveryFee: Double?

    var ratingDisplay: String {
        String(format: "%.1f", rating)
    }
}

struct FoodCategory: Identifiable, Codable {
    let id: String
    let name: String // "Hot Dogs", "Beverages", "Premium"
    let icon: String // SF Symbol
    let items: [FoodItem]

    var itemCount: Int {
        return items.count
    }
}

struct FoodItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let imageURL: String?
    let dietaryInfo: [DietaryTag]
    let customizationOptions: [CustomizationOption]
    let available: Bool
    let prepTimeMinutes: Int
    let calories: Int?
    let isFanFavorite: Bool

    var priceDisplay: String {
        String(format: "$%.2f", price)
    }

    var caloriesDisplay: String? {
        guard let cal = calories else { return nil }
        return "\(cal) cal"
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        return lhs.id == rhs.id
    }
}

enum DietaryTag: String, Codable, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case halal = "Halal"
    case kosher = "Kosher"
    case spicy = "Spicy"

    var icon: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.circle.fill"
        case .glutenFree: return "g.circle.fill"
        case .dairyFree: return "drop.fill"
        case .halal: return "h.circle.fill"
        case .kosher: return "k.circle.fill"
        case .spicy: return "flame.fill"
        }
    }

    var color: String {
        switch self {
        case .vegetarian: return "green"
        case .vegan: return "green"
        case .glutenFree: return "orange"
        case .dairyFree: return "blue"
        case .halal: return "purple"
        case .kosher: return "purple"
        case .spicy: return "red"
        }
    }
}

struct CustomizationOption: Identifiable, Codable, Hashable {
    let id: String
    let name: String // "Toppings", "Size"
    let required: Bool
    let options: [CustomizationChoice]
    let minSelections: Int
    let maxSelections: Int

    var selectionRangeDisplay: String {
        if required {
            if minSelections == maxSelections {
                return "Choose \(minSelections)"
            } else {
                return "Choose \(minSelections)-\(maxSelections)"
            }
        } else {
            if maxSelections == 1 {
                return "Optional"
            } else {
                return "Choose up to \(maxSelections)"
            }
        }
    }
}

struct CustomizationChoice: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let priceModifier: Double // +0.50, -1.00, etc.

    var priceModifierDisplay: String {
        if priceModifier == 0 {
            return ""
        } else if priceModifier > 0 {
            return "+$\(String(format: "%.2f", priceModifier))"
        } else {
            return "-$\(String(format: "%.2f", abs(priceModifier)))"
        }
    }
}

// MARK: - Food Order

struct FoodOrder: Identifiable, Codable {
    let id: String
    let gameScheduleId: String? // Links to GameSchedule
    let vendorId: String
    let vendorName: String
    let vendorLocation: String
    let items: [OrderItem]
    let pickupTime: Date
    let subtotal: Double
    let tax: Double
    let serviceFee: Double
    let totalAmount: Double
    let status: OrderStatus
    let confirmationCode: String
    let qrCode: String? // For pickup verification
    let createdAt: Date
    let estimatedReadyTime: Date
    let specialInstructions: String?

    var totalDisplay: String {
        String(format: "$%.2f", totalAmount)
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

    var isActive: Bool {
        [.pending, .confirmed, .preparing].contains(status)
    }

    var itemCount: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }
}

struct OrderItem: Identifiable, Codable {
    let id: String
    let foodItem: FoodItem
    let quantity: Int
    let selectedCustomizations: [String: [String]] // "Toppings": ["Mustard", "Ketchup"]
    let specialInstructions: String?
    let itemTotal: Double

    var itemTotalDisplay: String {
        String(format: "$%.2f", itemTotal)
    }

    var customizationSummary: String {
        guard !selectedCustomizations.isEmpty else { return "" }
        return selectedCustomizations
            .map { "\($0.key): \($0.value.joined(separator: ", "))" }
            .joined(separator: " • ")
    }
}

enum OrderStatus: String, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case preparing = "Preparing"
    case ready = "Ready for Pickup"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var color: String {
        switch self {
        case .pending: return "yellow"
        case .confirmed: return "blue"
        case .preparing: return "orange"
        case .ready: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .preparing: return "flame.fill"
        case .ready: return "bell.fill"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var userMessage: String {
        switch self {
        case .pending: return "Processing your order..."
        case .confirmed: return "Order confirmed! Vendor is preparing your food."
        case .preparing: return "Your food is being prepared!"
        case .ready: return "Your order is ready for pickup!"
        case .completed: return "Thank you! Enjoy the game."
        case .cancelled: return "Order cancelled"
        }
    }
}

// MARK: - Cart Item (for building orders)

struct CartItem: Identifiable, Codable {
    let id: String
    let foodItem: FoodItem
    var quantity: Int
    var selectedCustomizations: [String: [String]]
    var specialInstructions: String?

    var itemTotal: Double {
        let basePrice = foodItem.price
        let customizationCost = calculateCustomizationCost()
        return (basePrice + customizationCost) * Double(quantity)
    }

    var itemTotalDisplay: String {
        String(format: "$%.2f", itemTotal)
    }

    private func calculateCustomizationCost() -> Double {
        var cost = 0.0

        for (optionName, selectedChoices) in selectedCustomizations {
            // Find the customization option
            if let option = foodItem.customizationOptions.first(where: { $0.name == optionName }) {
                for choiceName in selectedChoices {
                    if let choice = option.options.first(where: { $0.name == choiceName }) {
                        cost += choice.priceModifier
                    }
                }
            }
        }

        return cost
    }
}

// MARK: - Request Models

struct FoodMenuRequest: Codable {
    let stadiumId: String
    let gameDate: Date
}

struct CreateFoodOrderRequest: Codable {
    let gameScheduleId: String?
    let vendorId: String
    let items: [OrderItemRequest]
    let pickupTime: Date
    let specialInstructions: String?
    let paymentMethodId: String
}

struct OrderItemRequest: Codable {
    let foodItemId: String
    let quantity: Int
    let customizations: [String: [String]]
    let specialInstructions: String?
}

// MARK: - Pickup Time Suggestion

struct PickupTimeSuggestion: Identifiable {
    let id = UUID()
    let time: Date
    let label: String
    let description: String
    let isRecommended: Bool

    var timeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
}

// MARK: - Mock Data for Development

extension FoodVendor {
    static func mockVendors(for stadiumId: String) -> [FoodVendor] {
        [
            FoodVendor(
                id: "vendor-001",
                name: "All-American Hot Dogs",
                description: "Classic stadium hot dogs and sausages",
                location: "Section 120, Gate B",
                coordinate: Coordinate(latitude: 25.9582, longitude: -80.2391),
                logoURL: nil,
                rating: 4.5,
                reviewCount: 328,
                categories: FoodCategory.mockHotDogCategories(),
                operatingHours: OperatingHours(open24Hours: false, openingTime: "10:00 AM", closingTime: "10:00 PM"),
                acceptsPreOrders: true,
                estimatedPrepTimeMinutes: 8,
                minimumOrder: nil,
                deliveryFee: nil
            ),
            FoodVendor(
                id: "vendor-002",
                name: "Pizza Paradise",
                description: "Fresh New York-style pizza by the slice",
                location: "Section 105, Gate A",
                coordinate: Coordinate(latitude: 25.9578, longitude: -80.2387),
                logoURL: nil,
                rating: 4.7,
                reviewCount: 512,
                categories: FoodCategory.mockPizzaCategories(),
                operatingHours: OperatingHours(open24Hours: false, openingTime: "11:00 AM", closingTime: "9:00 PM"),
                acceptsPreOrders: true,
                estimatedPrepTimeMinutes: 12,
                minimumOrder: nil,
                deliveryFee: nil
            ),
            FoodVendor(
                id: "vendor-003",
                name: "Nacho Nation",
                description: "Loaded nachos and Mexican favorites",
                location: "Section 215, Gate C",
                coordinate: Coordinate(latitude: 25.9588, longitude: -80.2393),
                logoURL: nil,
                rating: 4.3,
                reviewCount: 245,
                categories: FoodCategory.mockNachoCategories(),
                operatingHours: OperatingHours(open24Hours: false, openingTime: "11:00 AM", closingTime: "10:00 PM"),
                acceptsPreOrders: true,
                estimatedPrepTimeMinutes: 10,
                minimumOrder: nil,
                deliveryFee: nil
            ),
            FoodVendor(
                id: "vendor-004",
                name: "Beverage Central",
                description: "Drinks, beer, and refreshments",
                location: "Section 110, Gate B",
                coordinate: Coordinate(latitude: 25.9580, longitude: -80.2388),
                logoURL: nil,
                rating: 4.6,
                reviewCount: 892,
                categories: FoodCategory.mockBeverageCategories(),
                operatingHours: OperatingHours(open24Hours: false, openingTime: "10:00 AM", closingTime: "11:00 PM"),
                acceptsPreOrders: true,
                estimatedPrepTimeMinutes: 3,
                minimumOrder: nil,
                deliveryFee: nil
            )
        ]
    }
}

extension FoodCategory {
    static func mockHotDogCategories() -> [FoodCategory] {
        [
            FoodCategory(
                id: "cat-hotdogs",
                name: "Hot Dogs & Sausages",
                icon: "🌭",
                items: [
                    FoodItem(
                        id: "item-001",
                        name: "Classic Stadium Dog",
                        description: "Quarter-pound all-beef hot dog on a toasted bun",
                        price: 7.50,
                        imageURL: nil,
                        dietaryInfo: [],
                        customizationOptions: [
                            CustomizationOption(
                                id: "toppings-001",
                                name: "Toppings",
                                required: false,
                                options: [
                                    CustomizationChoice(id: "mustard", name: "Mustard", priceModifier: 0),
                                    CustomizationChoice(id: "ketchup", name: "Ketchup", priceModifier: 0),
                                    CustomizationChoice(id: "relish", name: "Relish", priceModifier: 0),
                                    CustomizationChoice(id: "onions", name: "Grilled Onions", priceModifier: 0.50),
                                    CustomizationChoice(id: "sauerkraut", name: "Sauerkraut", priceModifier: 0.50),
                                    CustomizationChoice(id: "chili", name: "Chili", priceModifier: 1.50),
                                    CustomizationChoice(id: "cheese", name: "Melted Cheese", priceModifier: 1.00)
                                ],
                                minSelections: 0,
                                maxSelections: 7
                            )
                        ],
                        available: true,
                        prepTimeMinutes: 5,
                        calories: 380,
                        isFanFavorite: true
                    ),
                    FoodItem(
                        id: "item-002",
                        name: "Bratwurst",
                        description: "Premium German bratwurst with sauerkraut",
                        price: 9.50,
                        imageURL: nil,
                        dietaryInfo: [],
                        customizationOptions: [
                            CustomizationOption(
                                id: "toppings-002",
                                name: "Toppings",
                                required: false,
                                options: [
                                    CustomizationChoice(id: "mustard", name: "Mustard", priceModifier: 0),
                                    CustomizationChoice(id: "sauerkraut", name: "Sauerkraut", priceModifier: 0),
                                    CustomizationChoice(id: "onions", name: "Grilled Onions", priceModifier: 0.50)
                                ],
                                minSelections: 0,
                                maxSelections: 3
                            )
                        ],
                        available: true,
                        prepTimeMinutes: 6,
                        calories: 420,
                        isFanFavorite: false
                    )
                ]
            ),
            FoodCategory(
                id: "cat-sides",
                name: "Sides",
                icon: "🍟",
                items: [
                    FoodItem(
                        id: "item-003",
                        name: "French Fries",
                        description: "Crispy golden fries with sea salt",
                        price: 5.00,
                        imageURL: nil,
                        dietaryInfo: [.vegetarian, .vegan],
                        customizationOptions: [
                            CustomizationOption(
                                id: "size-001",
                                name: "Size",
                                required: true,
                                options: [
                                    CustomizationChoice(id: "regular", name: "Regular", priceModifier: 0),
                                    CustomizationChoice(id: "large", name: "Large", priceModifier: 2.00)
                                ],
                                minSelections: 1,
                                maxSelections: 1
                            )
                        ],
                        available: true,
                        prepTimeMinutes: 4,
                        calories: 320,
                        isFanFavorite: true
                    )
                ]
            )
        ]
    }

    static func mockPizzaCategories() -> [FoodCategory] {
        [
            FoodCategory(
                id: "cat-pizza",
                name: "Pizza",
                icon: "🍕",
                items: [
                    FoodItem(
                        id: "item-101",
                        name: "Pepperoni Pizza Slice",
                        description: "Classic New York-style pepperoni slice",
                        price: 6.50,
                        imageURL: nil,
                        dietaryInfo: [],
                        customizationOptions: [],
                        available: true,
                        prepTimeMinutes: 8,
                        calories: 285,
                        isFanFavorite: true
                    ),
                    FoodItem(
                        id: "item-102",
                        name: "Cheese Pizza Slice",
                        description: "Classic cheese slice with marinara",
                        price: 5.50,
                        imageURL: nil,
                        dietaryInfo: [.vegetarian],
                        customizationOptions: [],
                        available: true,
                        prepTimeMinutes: 8,
                        calories: 240,
                        isFanFavorite: false
                    ),
                    FoodItem(
                        id: "item-103",
                        name: "Whole Pepperoni Pizza",
                        description: "Large 18\" pepperoni pizza (8 slices)",
                        price: 28.00,
                        imageURL: nil,
                        dietaryInfo: [],
                        customizationOptions: [],
                        available: true,
                        prepTimeMinutes: 15,
                        calories: 2280,
                        isFanFavorite: false
                    )
                ]
            )
        ]
    }

    static func mockNachoCategories() -> [FoodCategory] {
        [
            FoodCategory(
                id: "cat-nachos",
                name: "Nachos",
                icon: "🧀",
                items: [
                    FoodItem(
                        id: "item-201",
                        name: "Loaded Nachos",
                        description: "Tortilla chips loaded with cheese, jalapeños, and toppings",
                        price: 11.00,
                        imageURL: nil,
                        dietaryInfo: [.vegetarian, .spicy],
                        customizationOptions: [
                            CustomizationOption(
                                id: "nachos-toppings",
                                name: "Add Toppings",
                                required: false,
                                options: [
                                    CustomizationChoice(id: "guac", name: "Guacamole", priceModifier: 2.00),
                                    CustomizationChoice(id: "sour-cream", name: "Sour Cream", priceModifier: 1.00),
                                    CustomizationChoice(id: "salsa", name: "Salsa", priceModifier: 0.50),
                                    CustomizationChoice(id: "chicken", name: "Grilled Chicken", priceModifier: 3.00)
                                ],
                                minSelections: 0,
                                maxSelections: 4
                            )
                        ],
                        available: true,
                        prepTimeMinutes: 10,
                        calories: 580,
                        isFanFavorite: true
                    )
                ]
            ),
            FoodCategory(
                id: "cat-tacos",
                name: "Tacos",
                icon: "🌮",
                items: [
                    FoodItem(
                        id: "item-202",
                        name: "Street Tacos (3)",
                        description: "Three authentic street tacos with your choice of filling",
                        price: 9.50,
                        imageURL: nil,
                        dietaryInfo: [],
                        customizationOptions: [
                            CustomizationOption(
                                id: "taco-protein",
                                name: "Choose Protein",
                                required: true,
                                options: [
                                    CustomizationChoice(id: "carnitas", name: "Carnitas", priceModifier: 0),
                                    CustomizationChoice(id: "chicken", name: "Grilled Chicken", priceModifier: 0),
                                    CustomizationChoice(id: "beef", name: "Seasoned Beef", priceModifier: 0),
                                    CustomizationChoice(id: "veggie", name: "Grilled Veggies", priceModifier: 0)
                                ],
                                minSelections: 1,
                                maxSelections: 1
                            )
                        ],
                        available: true,
                        prepTimeMinutes: 8,
                        calories: 450,
                        isFanFavorite: false
                    )
                ]
            )
        ]
    }

    static func mockBeverageCategories() -> [FoodCategory] {
        [
            FoodCategory(
                id: "cat-beverages",
                name: "Beverages",
                icon: "🥤",
                items: [
                    FoodItem(
                        id: "item-301",
                        name: "Soft Drink",
                        description: "Coca-Cola products",
                        price: 5.00,
                        imageURL: nil,
                        dietaryInfo: [.vegetarian, .vegan],
                        customizationOptions: [
                            CustomizationOption(
                                id: "drink-type",
                                name: "Drink Type",
                                required: true,
                                options: [
                                    CustomizationChoice(id: "coke", name: "Coca-Cola", priceModifier: 0),
                                    CustomizationChoice(id: "diet-coke", name: "Diet Coke", priceModifier: 0),
                                    CustomizationChoice(id: "sprite", name: "Sprite", priceModifier: 0),
                                    CustomizationChoice(id: "fanta", name: "Fanta Orange", priceModifier: 0)
                                ],
                                minSelections: 1,
                                maxSelections: 1
                            ),
                            CustomizationOption(
                                id: "drink-size",
                                name: "Size",
                                required: true,
                                options: [
                                    CustomizationChoice(id: "medium", name: "Medium (20oz)", priceModifier: 0),
                                    CustomizationChoice(id: "large", name: "Large (32oz)", priceModifier: 2.00)
                                ],
                                minSelections: 1,
                                maxSelections: 1
                            )
                        ],
                        available: true,
                        prepTimeMinutes: 2,
                        calories: 140,
                        isFanFavorite: false
                    ),
                    FoodItem(
                        id: "item-302",
                        name: "Bottled Water",
                        description: "Cold bottled water",
                        price: 4.00,
                        imageURL: nil,
                        dietaryInfo: [.vegetarian, .vegan],
                        customizationOptions: [],
                        available: true,
                        prepTimeMinutes: 1,
                        calories: 0,
                        isFanFavorite: false
                    ),
                    FoodItem(
                        id: "item-303",
                        name: "Domestic Beer",
                        description: "Bud Light, Miller Lite, Coors Light",
                        price: 12.00,
                        imageURL: nil,
                        dietaryInfo: [],
                        customizationOptions: [
                            CustomizationOption(
                                id: "beer-type",
                                name: "Beer Selection",
                                required: true,
                                options: [
                                    CustomizationChoice(id: "bud", name: "Bud Light", priceModifier: 0),
                                    CustomizationChoice(id: "miller", name: "Miller Lite", priceModifier: 0),
                                    CustomizationChoice(id: "coors", name: "Coors Light", priceModifier: 0)
                                ],
                                minSelections: 1,
                                maxSelections: 1
                            )
                        ],
                        available: true,
                        prepTimeMinutes: 2,
                        calories: 103,
                        isFanFavorite: true
                    )
                ]
            )
        ]
    }
}

extension FoodOrder {
    static func mockOrder(from request: CreateFoodOrderRequest, items: [CartItem]) -> FoodOrder {
        let subtotal = items.reduce(0.0) { $0 + $1.itemTotal }
        let tax = subtotal * 0.08 // 8% tax
        let serviceFee = 1.99
        let total = subtotal + tax + serviceFee

        let orderItems = items.map { cartItem in
            OrderItem(
                id: UUID().uuidString,
                foodItem: cartItem.foodItem,
                quantity: cartItem.quantity,
                selectedCustomizations: cartItem.selectedCustomizations,
                specialInstructions: cartItem.specialInstructions,
                itemTotal: cartItem.itemTotal
            )
        }

        return FoodOrder(
            id: "food-order-\(UUID().uuidString.prefix(8))",
            gameScheduleId: request.gameScheduleId,
            vendorId: request.vendorId,
            vendorName: "All-American Hot Dogs", // Would lookup from vendor ID
            vendorLocation: "Section 120, Gate B",
            items: orderItems,
            pickupTime: request.pickupTime,
            subtotal: subtotal,
            tax: tax,
            serviceFee: serviceFee,
            totalAmount: total,
            status: .confirmed,
            confirmationCode: "FOOD-\(Int.random(in: 1000...9999))",
            qrCode: nil,
            createdAt: Date(),
            estimatedReadyTime: request.pickupTime.addingTimeInterval(-5 * 60),
            specialInstructions: request.specialInstructions
        )
    }

    static let mockOrders: [FoodOrder] = [
        FoodOrder(
            id: "order-001",
            gameScheduleId: nil,
            vendorId: "vendor-001",
            vendorName: "All-American Hot Dogs",
            vendorLocation: "Section 120, Gate B",
            items: [
                OrderItem(
                    id: "oi-001",
                    foodItem: FoodCategory.mockHotDogCategories()[0].items[0],
                    quantity: 2,
                    selectedCustomizations: ["Toppings": ["Mustard", "Ketchup", "Grilled Onions"]],
                    specialInstructions: nil,
                    itemTotal: 18.00
                )
            ],
            pickupTime: Date().addingTimeInterval(3600),
            subtotal: 18.00,
            tax: 1.44,
            serviceFee: 1.99,
            totalAmount: 21.43,
            status: .confirmed,
            confirmationCode: "FOOD-1234",
            qrCode: nil,
            createdAt: Date(),
            estimatedReadyTime: Date().addingTimeInterval(3300),
            specialInstructions: nil
        )
    ]
}
