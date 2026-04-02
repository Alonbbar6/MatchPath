import SwiftUI

/// View shown after successfully placing a food order
struct OrderConfirmationView: View {
    let order: FoodOrder
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Success animation
                    successHeader

                    // Order details
                    orderDetailsSection

                    // Items ordered
                    itemsSection

                    // Pricing breakdown
                    pricingSection

                    // Pickup instructions
                    pickupInstructionsSection

                    // Done button
                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Order Confirmed!")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDone()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    private var successHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }

            Text("Your order is confirmed!")
                .font(.title2)
                .fontWeight(.bold)

            Text(order.status.userMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var orderDetailsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Order Details")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Confirmation Code", value: order.confirmationCode, isHighlighted: true)
                DetailRow(label: "Vendor", value: order.vendorName)
                DetailRow(label: "Location", value: order.vendorLocation)
                DetailRow(label: "Pickup Time", value: formatTime(order.pickupTime))
                DetailRow(label: "Ready By", value: formatTime(order.estimatedReadyTime))
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
    }

    private var itemsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Items (\(order.itemCount))")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(order.items) { item in
                    HStack(alignment: .top) {
                        Text("\(item.quantity)x")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.foodItem.name)
                                .font(.subheadline)

                            if !item.selectedCustomizations.isEmpty {
                                Text(item.customizationSummary)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Text(item.itemTotalDisplay)
                            .font(.subheadline)
                            .fontWeight(.medium)
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
        }
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Payment Summary")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                PriceRow(label: "Subtotal", amount: order.subtotalDisplay)
                PriceRow(label: "Tax", amount: order.taxDisplay)
                PriceRow(label: "Service Fee", amount: order.serviceFeeDisplay)

                Divider()

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(order.totalDisplay)
                        .font(.title3)
                        .fontWeight(.bold)
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
        }
    }

    private var pickupInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Pickup Instructions")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                InstructionStep(number: "1", text: "Arrive at \(order.vendorLocation)")
                InstructionStep(number: "2", text: "Show confirmation code: \(order.confirmationCode)")
                InstructionStep(number: "3", text: "Collect your order and enjoy!")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(isHighlighted ? .headline : .subheadline)
                .fontWeight(isHighlighted ? .bold : .regular)
                .foregroundColor(isHighlighted ? .blue : .primary)
        }
    }
}

struct PriceRow: View {
    let label: String
    let amount: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(amount)
                .font(.subheadline)
        }
    }
}

struct InstructionStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)

                Text(number)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    OrderConfirmationView(
        order: FoodOrder.mockOrders[0],
        onDone: {}
    )
}
