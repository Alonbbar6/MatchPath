import SwiftUI

/// View for browsing a vendor's menu and adding items to cart
struct VendorMenuView: View {
    let vendor: FoodVendor
    @Binding var cart: [CartItem]
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Vendor header
                vendorHeader

                // Menu categories
                ForEach(vendor.categories) { category in
                    categorySection(category)
                }
            }
            .padding()
        }
        .navigationTitle(vendor.name)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    onDone()
                }
            }
        }
    }

    private var vendorHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vendor.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label(vendor.location, systemImage: "mappin")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(vendor.ratingDisplay)
                }
            }
            .font(.caption)
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
    }

    private func categorySection(_ category: FoodCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.icon)
                    .font(.title2)
                Text(category.name)
                    .font(.headline)
            }

            ForEach(category.items) { item in
                FoodItemCard(item: item) {
                    addToCart(item)
                }
            }
        }
    }

    private func addToCart(_ item: FoodItem) {
        // Create default cart item with no customizations
        let cartItem = CartItem(
            id: UUID().uuidString,
            foodItem: item,
            quantity: 1,
            selectedCustomizations: [:],
            specialInstructions: nil
        )

        cart.append(cartItem)
    }
}

struct FoodItemCard: View {
    let item: FoodItem
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if item.isFanFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }

                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        ForEach(item.dietaryInfo, id: \.self) { tag in
                            DietaryTagBadge(tag: tag)
                        }
                    }

                    if let calories = item.caloriesDisplay {
                        Text(calories)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(item.priceDisplay)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
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

struct DietaryTagBadge: View {
    let tag: DietaryTag

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: tag.icon)
            Text(tag.rawValue)
        }
        .font(.system(size: 9))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tagColor.opacity(0.15))
        .foregroundColor(tagColor)
        .cornerRadius(4)
    }

    private var tagColor: Color {
        switch tag.color {
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

#Preview {
    VendorMenuView(
        vendor: FoodVendor.mockVendors(for: "stadium-001")[0],
        cart: .constant([]),
        onDone: {}
    )
}
