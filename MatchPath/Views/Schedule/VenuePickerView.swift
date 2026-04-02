import SwiftUI

struct VenuePickerView: View {
    let onSelect: (Stadium) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var venues: [Stadium] {
        VenueDataLoader.shared.searchVenues(query: searchText)
    }

    var body: some View {
        NavigationView {
            List(venues, id: \.id) { venue in
                Button {
                    onSelect(venue)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(venue.city)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Capacity: \(venue.capacity.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .searchable(text: $searchText, prompt: "Search venues")
            .navigationTitle("Select Venue")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
