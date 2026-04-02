import SwiftUI

// MARK: - Destination Model

struct NavigationDestination: Identifiable, Equatable {
    let id: String
    let name: String
    let category: DestinationCategory
    let localX: Double
    let localY: Double
    let detail: String?

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.id == rhs.id
    }

    enum DestinationCategory: String, CaseIterable {
        case section = "Sections"
        case restroom = "Restrooms"
        case concession = "Food & Drinks"
        case gate = "Gates & Exits"

        var icon: String {
            switch self {
            case .section: return "ticket"
            case .restroom: return "toilet"
            case .concession: return "cup.and.saucer.fill"
            case .gate: return "door.left.hand.open"
            }
        }

        var color: Color {
            switch self {
            case .section: return .blue
            case .restroom: return .purple
            case .concession: return .orange
            case .gate: return .green
            }
        }
    }
}

// MARK: - Search View

struct NavigationSearchView: View {
    let destinations: [NavigationDestination]
    let currentDestination: NavigationDestination?
    let onSelect: (NavigationDestination) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: NavigationDestination.DestinationCategory?

    private var filteredDestinations: [NavigationDestination] {
        var results = destinations

        // Filter by category
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(query) ||
                ($0.detail?.lowercased().contains(query) ?? false) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }

        return results
    }

    private var groupedDestinations: [(NavigationDestination.DestinationCategory, [NavigationDestination])] {
        let grouped = Dictionary(grouping: filteredDestinations, by: { $0.category })
        return NavigationDestination.DestinationCategory.allCases.compactMap { category in
            if let items = grouped[category], !items.isEmpty {
                return (category, items)
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // "All" chip
                        categoryChip(label: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }

                        ForEach(NavigationDestination.DestinationCategory.allCases, id: \.self) { category in
                            categoryChip(
                                label: category.rawValue,
                                icon: category.icon,
                                color: category.color,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(UIColor.systemGroupedBackground))

                // Results list
                if groupedDestinations.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if !searchText.isEmpty {
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(groupedDestinations, id: \.0) { category, items in
                            Section {
                                ForEach(items) { destination in
                                    destinationRow(destination)
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                    Text(category.rawValue)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Navigate To")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search sections, restrooms, food...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func categoryChip(label: String, icon: String, color: Color = .blue, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? color : Color(UIColor.tertiarySystemFill))
            .cornerRadius(20)
        }
    }

    @ViewBuilder
    private func destinationRow(_ destination: NavigationDestination) -> some View {
        Button {
            onSelect(destination)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(destination.category.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: destination.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(destination.category.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(destination.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    if let detail = destination.detail {
                        Text(detail)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Currently navigating indicator
                if currentDestination?.id == destination.id {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text("Active")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
                } else {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
