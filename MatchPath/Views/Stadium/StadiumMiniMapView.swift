import SwiftUI

/// Compact stadium floor map showing user position and target section.
/// Renders at 800x800 (half the size of IndoorStadiumMapView's 1600x1600 canvas).
struct StadiumMiniMapView: View {
    var userDisplayX: CGFloat = 650
    var userDisplayY: CGFloat = 610
    var targetSectionId: String? = nil

    private let scale: CGFloat = 0.5 // Half size of the full 1600x1600 map
    private let stadiumData = MockStadiumData()

    var body: some View {
        ZStack {
            // Field (center)
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.7, blue: 0.3),
                            Color(red: 0.15, green: 0.6, blue: 0.25)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 360, height: 210)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
                .overlay(
                    Text("FIELD")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white.opacity(0.6))
                )

            // Level 100 sections only (mini map)
            ForEach(stadiumData.level100Sections, id: \.id) { section in
                MiniSectionView(
                    name: section.name,
                    isTarget: section.id == targetSectionId
                )
                .position(x: section.x * scale, y: section.y * scale)
            }

            // Gate markers
            ForEach(stadiumData.amenities.filter { $0.type == .gate && $0.level == 1 }, id: \.id) { gate in
                VStack(spacing: 2) {
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text(gate.shortName)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.green)
                }
                .position(x: gate.x * scale, y: gate.y * scale)
            }

            // User position marker
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 30, height: 30)

                Circle()
                    .fill(Color.blue)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.blue.opacity(0.5), radius: 4)
            }
            .position(x: userDisplayX * scale, y: userDisplayY * scale)

            // Line from user to target section
            if let targetId = targetSectionId,
               let targetSection = stadiumData.level100Sections.first(where: { $0.id == targetId }) {
                Path { path in
                    path.move(to: CGPoint(x: userDisplayX * scale, y: userDisplayY * scale))
                    path.addLine(to: CGPoint(x: targetSection.x * scale, y: targetSection.y * scale))
                }
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .foregroundColor(.green.opacity(0.6))
            }
        }
        .frame(width: 800, height: 800)
    }
}

/// Small section marker for the mini map
struct MiniSectionView: View {
    let name: String
    let isTarget: Bool

    var body: some View {
        Text(name)
            .font(.system(size: 9, weight: isTarget ? .black : .semibold))
            .foregroundColor(.white)
            .frame(width: 36, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isTarget ? Color.green : Color.gray.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isTarget ? Color.green : Color.white.opacity(0.3), lineWidth: isTarget ? 2 : 0.5)
            )
            .shadow(color: isTarget ? Color.green.opacity(0.5) : Color.clear, radius: 4)
    }
}

#Preview {
    StadiumMiniMapView(
        userDisplayX: 700,
        userDisplayY: 150,
        targetSectionId: "101"
    )
    .background(Color(red: 0.92, green: 0.92, blue: 0.95))
}
