import SwiftUI

/// View for selecting transportation mode in the schedule builder
struct TransportationModeSelectionView: View {
    @Binding var selectedMode: TransportationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How will you get to the stadium?")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(TransportationMode.allCases, id: \.self) { mode in
                    TransportationModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode
                    ) {
                        selectedMode = mode
                    }
                }
            }
        }
    }
}

// MARK: - Transportation Mode Card

struct TransportationModeCard: View {
    let mode: TransportationMode
    let isSelected: Bool
    let action: () -> Void

    // Cross-platform background colors
    private var cardBackground: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    private var iconBackground: Color {
        // Approximate systemGray6 without UIKit/AppKit dependency
        return Color.gray.opacity(0.15)
    }

    var body: some View {
        Button(action: action, label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : iconBackground)
                        .frame(width: 50, height: 50)

                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .secondary)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBackground)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        })
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TransportationModeSelectionView(selectedMode: .constant(.driving))
        .padding()
}
