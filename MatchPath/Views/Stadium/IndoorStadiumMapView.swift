import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Indoor stadium map view showing sections, amenities, and user location
struct IndoorStadiumMapView: View {
    let schedule: GameSchedule
    let onIndoorCompass: () -> Void
    var userDisplayX: CGFloat = 900
    var userDisplayY: CGFloat = 900
    var targetSectionId: String? = nil
    @State private var selectedLevel: Int = 1
    @State private var showingAmenities = true
    @State private var showingSections = true
    @State private var selectedAmenityType: AmenityType? = nil
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    // Mock stadium data - would load from JSON in production
    @State private var stadiumData: MockStadiumData = MockStadiumData()

    /// Convert local stadium coordinates to display coordinates
    static func localToDisplay(x: Double, y: Double) -> (CGFloat, CGFloat) {
        let displayX = CGFloat(x * 4.0 + 650)
        let displayY = CGFloat(y * -3.83 + 610)
        return (displayX, displayY)
    }

    var body: some View {
        ZStack {
            // Background
            #if os(iOS)
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            #else
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            #endif

            VStack(spacing: 0) {
                // Stadium info header
                headerCard
                    .padding()

                // Level selector
                levelSelector
                    .padding(.horizontal)

                // Main map area with zoom
                ZStack(alignment: .bottomTrailing) {
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        stadiumLayoutView
                            .frame(width: 1600, height: 1600)
                            .scaleEffect(zoomScale) // Apply zoom to entire layout
                            .frame(width: 1600 * zoomScale, height: 1600 * zoomScale) // Adjust scroll area
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.95, green: 0.95, blue: 0.97),
                                Color(red: 0.92, green: 0.92, blue: 0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                let newScale = zoomScale * delta
                                zoomScale = min(max(newScale, 0.5), 4.0) // Limit between 0.5x and 4x
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )

                    // Zoom controls overlay
                    zoomControls
                        .padding()
                }

                // Legend and controls
                controlPanel
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 8) {
            Text(schedule.game.stadium.name)
                .font(.title2)
                .fontWeight(.bold)

            Text("Indoor Stadium Map")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
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
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }

    private var levelSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([1, 2, 3], id: \.self) { level in
                    Button {
                        selectedLevel = level
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(level)00 Level")
                                .font(.subheadline)
                                .fontWeight(selectedLevel == level ? .bold : .regular)
                            if level == 1 {
                                Text("Lower Bowl")
                                    .font(.caption2)
                            } else if level == 2 {
                                Text("Club Level")
                                    .font(.caption2)
                            } else if level == 3 {
                                Text("Upper Bowl")
                                    .font(.caption2)
                            }
                        }
                        .frame(minWidth: 90)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Group {
                                if selectedLevel == level {
                                    Color.orange
                                } else {
                                    #if os(iOS)
                                    Color(.systemGray6)
                                    #else
                                    Color(nsColor: .controlBackgroundColor)
                                    #endif
                                }
                            }
                        )
                        .foregroundColor(selectedLevel == level ? .white : .primary)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var stadiumLayoutView: some View {
        ZStack {
            // Field (center)
            RoundedRectangle(cornerRadius: 35)
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
                .frame(width: 720, height: 420)
                .overlay(
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(Color.white.opacity(0.4), lineWidth: 4)
                )
                .overlay(
                    VStack(spacing: 12) {
                        Text("⚽️")
                            .font(.system(size: 90))
                            .shadow(color: .black.opacity(0.4), radius: 4)
                        Text("FIELD")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
                    }
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

            // Sections around the field
            if showingSections {
                sectionsView
            }

            // Amenities
            if showingAmenities {
                amenitiesView
            }

            // User location indicator
            userLocationMarker
        }
    }

    private var sectionsView: some View {
        ZStack {
            // Filter sections by selected level
            ForEach(stadiumData.allSections.filter { $0.level == selectedLevel }, id: \.id) { section in
                SectionView(section: section, isSelected: section.id == targetSectionId)
                    .position(x: section.x, y: section.y)
            }
        }
    }

    private var amenitiesView: some View {
        ZStack {
            ForEach(stadiumData.amenities.filter { $0.level == selectedLevel }, id: \.id) { amenity in
                AmenityMarker(amenity: amenity)
                    .position(x: amenity.x, y: amenity.y)
            }
        }
    }

    private var userLocationMarker: some View {
        VStack(spacing: 5) {
            ZStack {
                // Pulse effect circles
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 50, height: 50)

                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                    .frame(width: 65, height: 65)

                // Main location marker
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 18
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 3)
            }

            Text("YOU ARE HERE")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.blue)
                        .shadow(color: Color.black.opacity(0.3), radius: 4)
                )
        }
        .position(x: userDisplayX, y: userDisplayY)
    }

    private var zoomControls: some View {
        VStack(spacing: 8) {
            // Zoom in button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    zoomScale = min(zoomScale * 1.3, 4.0)
                }
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 5)
            }

            // Current zoom level indicator
            Text("\(Int(zoomScale * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)

            // Zoom out button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    zoomScale = max(zoomScale / 1.3, 0.5)
                }
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 5)
            }

            // Reset zoom button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    zoomScale = 1.0
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 5)
            }
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
            // Filter toggles
            HStack(spacing: 12) {
                Toggle(isOn: $showingSections) {
                    Label("Sections", systemImage: "square.grid.3x3")
                        .font(.subheadline)
                }
                .toggleStyle(.button)
                .tint(.orange)

                Toggle(isOn: $showingAmenities) {
                    Label("Amenities", systemImage: "mappin.circle")
                        .font(.subheadline)
                }
                .toggleStyle(.button)
                .tint(.orange)
            }

            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    LegendItem(icon: "🍔", label: "Food", color: .red)
                    LegendItem(icon: "🚻", label: "Restroom", color: .blue)
                    LegendItem(icon: "🚪", label: "Gate", color: .green)
                    LegendItem(icon: "🏪", label: "Store", color: .purple)
                    LegendItem(icon: "ℹ️", label: "Info", color: .orange)
                }
            }

            // Action button
            Button {
                onIndoorCompass()
            } label: {
                HStack {
                    Image(systemName: "safari")
                    Text("AR Compass Navigation")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
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
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
    }
}

// MARK: - Section View

struct SectionView: View {
    let section: MockSection
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(section.name)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)

            Text(section.rows)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
        }
        .frame(width: 90, height: 75)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [sectionColor, sectionColor.opacity(0.85)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2.5
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 5, x: 0, y: 3)
    }

    var sectionColor: Color {
        if isSelected { return Color.green }
        switch section.category {
        case "premium":
            return Color(red: 0.65, green: 0.2, blue: 0.8)
        case "club":
            return Color(red: 0.15, green: 0.4, blue: 0.95)
        case "general", "standard":
            return Color(red: 0.5, green: 0.52, blue: 0.56)
        default:
            return Color.gray
        }
    }
}

// MARK: - Amenity Marker

struct AmenityMarker: View {
    let amenity: MockAmenity

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 2)

                Circle()
                    .stroke(iconColor, lineWidth: 3)
                    .frame(width: 50, height: 50)

                Text(amenity.icon)
                    .font(.system(size: 30))
            }

            Text(amenity.shortName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(iconColor)
                        .shadow(color: Color.black.opacity(0.3), radius: 3)
                )
        }
    }

    var iconColor: Color {
        switch amenity.type {
        case .food:
            return Color.orange
        case .restroom:
            return Color.blue
        case .gate:
            return Color.green
        case .store:
            return Color.purple
        case .info:
            return Color.red
        }
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.caption)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Group {
                #if os(iOS)
                Color(.systemGray6)
                #else
                Color(nsColor: .controlBackgroundColor)
                #endif
            }
        )
        .cornerRadius(8)
    }
}

// MARK: - Mock Data Models

enum AmenityType: String, CaseIterable {
    case food = "food"
    case restroom = "restroom"
    case gate = "gate"
    case store = "store"
    case info = "info"
}

struct MockSection {
    let id: String
    let name: String
    let category: String
    let rows: String
    let level: Int
    let x: Double
    let y: Double
}

struct MockAmenity {
    let id: String
    let type: AmenityType
    let name: String
    let shortName: String
    let icon: String
    let level: Int
    let x: Double
    let y: Double
}

// MARK: - Hard Rock Stadium Data (Based on Actual Seating Map)

struct MockStadiumData {
    // All sections combined for easier filtering
    var allSections: [MockSection] {
        return level100Sections + level200Sections + level300Sections
    }

    // LEVEL 100 - Lower Bowl (Gray sections on map) - MAXIMUM SPACING
    let level100Sections: [MockSection] = [
        // North Side - Sections 101-123 (maximum spacing)
        MockSection(id: "101", name: "101", category: "standard", rows: "1-30", level: 1, x: 200, y: 300),
        MockSection(id: "102", name: "102", category: "standard", rows: "1-30", level: 1, x: 280, y: 275),
        MockSection(id: "103", name: "103", category: "standard", rows: "1-30", level: 1, x: 360, y: 255),
        MockSection(id: "104", name: "104", category: "standard", rows: "1-30", level: 1, x: 440, y: 242),
        MockSection(id: "105", name: "105", category: "standard", rows: "1-30", level: 1, x: 520, y: 232),
        MockSection(id: "106", name: "106", category: "standard", rows: "1-30", level: 1, x: 600, y: 227),
        MockSection(id: "107", name: "107", category: "standard", rows: "1-30", level: 1, x: 680, y: 224),
        MockSection(id: "108", name: "108", category: "standard", rows: "1-30", level: 1, x: 760, y: 224),
        MockSection(id: "114", name: "114", category: "standard", rows: "1-30", level: 1, x: 840, y: 227),
        MockSection(id: "115", name: "115", category: "standard", rows: "1-30", level: 1, x: 920, y: 232),
        MockSection(id: "116", name: "116", category: "standard", rows: "1-30", level: 1, x: 1000, y: 238),
        MockSection(id: "117", name: "117", category: "standard", rows: "1-30", level: 1, x: 1080, y: 232),
        MockSection(id: "118", name: "118", category: "standard", rows: "1-30", level: 1, x: 1160, y: 227),
        MockSection(id: "119", name: "119", category: "standard", rows: "1-30", level: 1, x: 1240, y: 224),
        MockSection(id: "120", name: "120", category: "standard", rows: "1-30", level: 1, x: 1320, y: 224),
        MockSection(id: "121", name: "121", category: "standard", rows: "1-30", level: 1, x: 1400, y: 227),
        MockSection(id: "122", name: "122", category: "standard", rows: "1-30", level: 1, x: 1480, y: 232),
        MockSection(id: "123", name: "123", category: "standard", rows: "1-30", level: 1, x: 1560, y: 242),

        // East Side - Sections 129-135 (maximum spacing)
        MockSection(id: "129", name: "129", category: "standard", rows: "1-30", level: 1, x: 1610, y: 420),
        MockSection(id: "130", name: "130", category: "standard", rows: "1-30", level: 1, x: 1640, y: 560),
        MockSection(id: "131", name: "131", category: "standard", rows: "1-30", level: 1, x: 1655, y: 700),
        MockSection(id: "132", name: "132", category: "standard", rows: "1-30", level: 1, x: 1665, y: 800),
        MockSection(id: "133", name: "133", category: "standard", rows: "1-30", level: 1, x: 1665, y: 900),
        MockSection(id: "134", name: "134", category: "standard", rows: "1-30", level: 1, x: 1665, y: 1000),
        MockSection(id: "135", name: "135", category: "standard", rows: "1-30", level: 1, x: 1655, y: 1100),

        // South Side - Sections 142-150 (maximum spacing)
        MockSection(id: "142", name: "142", category: "standard", rows: "1-30", level: 1, x: 1550, y: 1380),
        MockSection(id: "143", name: "143", category: "standard", rows: "1-30", level: 1, x: 1460, y: 1395),
        MockSection(id: "144", name: "144", category: "standard", rows: "1-30", level: 1, x: 1370, y: 1405),
        MockSection(id: "145", name: "145", category: "standard", rows: "1-30", level: 1, x: 1280, y: 1412),
        MockSection(id: "146", name: "146", category: "standard", rows: "1-30", level: 1, x: 1190, y: 1417),
        MockSection(id: "147", name: "147", category: "standard", rows: "1-30", level: 1, x: 1100, y: 1417),
        MockSection(id: "148", name: "148", category: "standard", rows: "1-30", level: 1, x: 1010, y: 1417),
        MockSection(id: "149", name: "149", category: "standard", rows: "1-30", level: 1, x: 920, y: 1417),
        MockSection(id: "150", name: "150", category: "standard", rows: "1-30", level: 1, x: 830, y: 1412),

        // West Side (includes corners) - maximum spacing
        MockSection(id: "156", name: "156", category: "standard", rows: "1-30", level: 1, x: 190, y: 1130),
        MockSection(id: "196", name: "196", category: "standard", rows: "1-30", level: 1, x: 200, y: 1240),
        MockSection(id: "197", name: "197", category: "standard", rows: "1-30", level: 1, x: 220, y: 1340),
    ]

    // LEVEL 200 - Club Level (Blue sections on map) - MAXIMUM SPACING
    let level200Sections: [MockSection] = [
        // North Side - Club sections 201-223 (maximum spacing)
        MockSection(id: "201", name: "201", category: "club", rows: "1-20", level: 2, x: 280, y: 350),
        MockSection(id: "202", name: "202", category: "club", rows: "1-20", level: 2, x: 370, y: 335),
        MockSection(id: "203", name: "203", category: "club", rows: "1-20", level: 2, x: 460, y: 323),
        MockSection(id: "204", name: "204", category: "club", rows: "1-20", level: 2, x: 550, y: 316),
        MockSection(id: "205", name: "205", category: "club", rows: "1-20", level: 2, x: 640, y: 311),
        MockSection(id: "206", name: "206", category: "club", rows: "1-20", level: 2, x: 730, y: 309),
        MockSection(id: "207", name: "207", category: "club", rows: "1-20", level: 2, x: 820, y: 309),
        MockSection(id: "208", name: "208", category: "club", rows: "1-20", level: 2, x: 910, y: 311),
        MockSection(id: "214", name: "214", category: "club", rows: "1-20", level: 2, x: 910, y: 316),
        MockSection(id: "215", name: "215", category: "club", rows: "1-20", level: 2, x: 1000, y: 323),
        MockSection(id: "216", name: "216", category: "club", rows: "1-20", level: 2, x: 1090, y: 330),
        MockSection(id: "217", name: "217", category: "club", rows: "1-20", level: 2, x: 1180, y: 323),
        MockSection(id: "218", name: "218", category: "club", rows: "1-20", level: 2, x: 1270, y: 316),
        MockSection(id: "219", name: "219", category: "club", rows: "1-20", level: 2, x: 1360, y: 311),
        MockSection(id: "220", name: "220", category: "club", rows: "1-20", level: 2, x: 1450, y: 309),
        MockSection(id: "221", name: "221", category: "club", rows: "1-20", level: 2, x: 1540, y: 311),
        MockSection(id: "222", name: "222", category: "club", rows: "1-20", level: 2, x: 1630, y: 323),
        MockSection(id: "223", name: "223", category: "club", rows: "1-20", level: 2, x: 1720, y: 335),

        // East Side - Club sections 228-236 (maximum spacing)
        MockSection(id: "228", name: "228", category: "club", rows: "1-20", level: 2, x: 1550, y: 510),
        MockSection(id: "229", name: "229", category: "club", rows: "1-20", level: 2, x: 1570, y: 630),
        MockSection(id: "230", name: "230", category: "club", rows: "1-20", level: 2, x: 1580, y: 750),
        MockSection(id: "231", name: "231", category: "club", rows: "1-20", level: 2, x: 1587, y: 870),
        MockSection(id: "232", name: "232", category: "club", rows: "1-20", level: 2, x: 1587, y: 990),
        MockSection(id: "233", name: "233", category: "club", rows: "1-20", level: 2, x: 1580, y: 1110),
        MockSection(id: "234", name: "234", category: "club", rows: "1-20", level: 2, x: 1570, y: 1230),
        MockSection(id: "235", name: "235", category: "club", rows: "1-20", level: 2, x: 1550, y: 1350),
        MockSection(id: "236", name: "236", category: "club", rows: "1-20", level: 2, x: 1525, y: 1445),

        // South Side - "NINE" sections 242-251 (maximum spacing)
        MockSection(id: "242", name: "242", category: "club", rows: "1-20", level: 2, x: 1440, y: 1480),
        MockSection(id: "243", name: "243", category: "club", rows: "1-20", level: 2, x: 1350, y: 1495),
        MockSection(id: "244", name: "244", category: "club", rows: "1-20", level: 2, x: 1260, y: 1504),
        MockSection(id: "245", name: "245", category: "club", rows: "1-20", level: 2, x: 1170, y: 1510),
        MockSection(id: "246", name: "246", category: "club", rows: "1-20", level: 2, x: 1080, y: 1513),
        MockSection(id: "247", name: "247", category: "club", rows: "1-20", level: 2, x: 990, y: 1513),
        MockSection(id: "248", name: "248", category: "club", rows: "1-20", level: 2, x: 900, y: 1513),
        MockSection(id: "249", name: "249", category: "club", rows: "1-20", level: 2, x: 810, y: 1513),
        MockSection(id: "250", name: "250", category: "club", rows: "1-20", level: 2, x: 720, y: 1510),
        MockSection(id: "251", name: "251", category: "club", rows: "1-20", level: 2, x: 630, y: 1504),
    ]

    // LEVEL 300 - Upper Bowl (Gray sections on map) - MAXIMUM SPACING
    let level300Sections: [MockSection] = [
        // North Side - Sections 313-323 (maximum spacing)
        MockSection(id: "313", name: "313", category: "standard", rows: "1-40", level: 3, x: 400, y: 180),
        MockSection(id: "314", name: "314", category: "standard", rows: "1-40", level: 3, x: 500, y: 167),
        MockSection(id: "315", name: "315", category: "standard", rows: "1-40", level: 3, x: 600, y: 159),
        MockSection(id: "316", name: "316", category: "standard", rows: "1-40", level: 3, x: 700, y: 154),
        MockSection(id: "317", name: "317", category: "standard", rows: "1-40", level: 3, x: 800, y: 151),
        MockSection(id: "318", name: "318", category: "standard", rows: "1-40", level: 3, x: 900, y: 151),
        MockSection(id: "319", name: "319", category: "standard", rows: "1-40", level: 3, x: 1000, y: 151),
        MockSection(id: "320", name: "320", category: "standard", rows: "1-40", level: 3, x: 1100, y: 154),
        MockSection(id: "321", name: "321", category: "standard", rows: "1-40", level: 3, x: 1200, y: 159),
        MockSection(id: "322", name: "322", category: "standard", rows: "1-40", level: 3, x: 1300, y: 167),
        MockSection(id: "323", name: "323", category: "standard", rows: "1-40", level: 3, x: 1400, y: 180),

        // East Side - Sections 328-336 (maximum spacing)
        MockSection(id: "328", name: "328", category: "standard", rows: "1-40", level: 3, x: 1690, y: 340),
        MockSection(id: "329", name: "329", category: "standard", rows: "1-40", level: 3, x: 1720, y: 480),
        MockSection(id: "330", name: "330", category: "standard", rows: "1-40", level: 3, x: 1738, y: 620),
        MockSection(id: "331", name: "331", category: "standard", rows: "1-40", level: 3, x: 1747, y: 760),
        MockSection(id: "332", name: "332", category: "standard", rows: "1-40", level: 3, x: 1747, y: 900),
        MockSection(id: "333", name: "333", category: "standard", rows: "1-40", level: 3, x: 1738, y: 1040),
        MockSection(id: "334", name: "334", category: "standard", rows: "1-40", level: 3, x: 1720, y: 1180),
        MockSection(id: "335", name: "335", category: "standard", rows: "1-40", level: 3, x: 1690, y: 1320),
        MockSection(id: "336", name: "336", category: "standard", rows: "1-40", level: 3, x: 1650, y: 1445),

        // South Side - Sections 341-351 (maximum spacing)
        MockSection(id: "341", name: "341", category: "standard", rows: "1-40", level: 3, x: 1540, y: 1540),
        MockSection(id: "342", name: "342", category: "standard", rows: "1-40", level: 3, x: 1435, y: 1560),
        MockSection(id: "343", name: "343", category: "standard", rows: "1-40", level: 3, x: 1330, y: 1572),
        MockSection(id: "344", name: "344", category: "standard", rows: "1-40", level: 3, x: 1225, y: 1580),
        MockSection(id: "345", name: "345", category: "standard", rows: "1-40", level: 3, x: 1120, y: 1584),
        MockSection(id: "346", name: "346", category: "standard", rows: "1-40", level: 3, x: 1015, y: 1584),
        MockSection(id: "347", name: "347", category: "standard", rows: "1-40", level: 3, x: 910, y: 1580),
        MockSection(id: "348", name: "348", category: "standard", rows: "1-40", level: 3, x: 805, y: 1572),
        MockSection(id: "349", name: "349", category: "standard", rows: "1-40", level: 3, x: 700, y: 1560),
        MockSection(id: "350", name: "350", category: "standard", rows: "1-40", level: 3, x: 595, y: 1540),
        MockSection(id: "351", name: "351", category: "standard", rows: "1-40", level: 3, x: 495, y: 1515),

        // West Side - Sections 301-308, 356 (maximum spacing)
        MockSection(id: "301", name: "301", category: "standard", rows: "1-40", level: 3, x: 145, y: 430),
        MockSection(id: "302", name: "302", category: "standard", rows: "1-40", level: 3, x: 125, y: 570),
        MockSection(id: "303", name: "303", category: "standard", rows: "1-40", level: 3, x: 113, y: 710),
        MockSection(id: "304", name: "304", category: "standard", rows: "1-40", level: 3, x: 107, y: 850),
        MockSection(id: "305", name: "305", category: "standard", rows: "1-40", level: 3, x: 107, y: 990),
        MockSection(id: "306", name: "306", category: "standard", rows: "1-40", level: 3, x: 113, y: 1130),
        MockSection(id: "307", name: "307", category: "standard", rows: "1-40", level: 3, x: 125, y: 1270),
        MockSection(id: "308", name: "308", category: "standard", rows: "1-40", level: 3, x: 145, y: 1410),
        MockSection(id: "356", name: "356", category: "standard", rows: "1-40", level: 3, x: 185, y: 1500),
    ]

    // Amenities
    let amenities: [MockAmenity] = [
        // Level 1 - Gates and basic amenities
        MockAmenity(id: "north-gate", type: .gate, name: "North Gate", shortName: "North", icon: "🚪", level: 1, x: 700, y: 150),
        MockAmenity(id: "south-gate", type: .gate, name: "South Gate", shortName: "South", icon: "🚪", level: 1, x: 700, y: 1070),
        MockAmenity(id: "east-gate", type: .gate, name: "East Gate", shortName: "East", icon: "🚪", level: 1, x: 1130, y: 700),
        MockAmenity(id: "west-gate", type: .gate, name: "West Gate", shortName: "West", icon: "🚪", level: 1, x: 170, y: 700),

        MockAmenity(id: "food1", type: .food, name: "North Concessions", shortName: "Food", icon: "🍔", level: 1, x: 425, y: 280),
        MockAmenity(id: "food2", type: .food, name: "East Concessions", shortName: "Food", icon: "🍔", level: 1, x: 1000, y: 500),
        MockAmenity(id: "food3", type: .food, name: "South Concessions", shortName: "Food", icon: "🍔", level: 1, x: 750, y: 950),
        MockAmenity(id: "food4", type: .food, name: "West Concessions", shortName: "Food", icon: "🍔", level: 1, x: 280, y: 800),

        MockAmenity(id: "rest1", type: .restroom, name: "North Restrooms", shortName: "WC", icon: "🚻", level: 1, x: 700, y: 260),
        MockAmenity(id: "rest2", type: .restroom, name: "South Restrooms", shortName: "WC", icon: "🚻", level: 1, x: 700, y: 980),
        MockAmenity(id: "rest3", type: .restroom, name: "East Restrooms", shortName: "WC", icon: "🚻", level: 1, x: 1000, y: 700),
        MockAmenity(id: "rest4", type: .restroom, name: "West Restrooms", shortName: "WC", icon: "🚻", level: 1, x: 280, y: 700),

        MockAmenity(id: "store1", type: .store, name: "Team Store", shortName: "Store", icon: "🏪", level: 1, x: 500, y: 950),
        MockAmenity(id: "info1", type: .info, name: "Information", shortName: "Info", icon: "ℹ️", level: 1, x: 850, y: 950),

        // Level 2 - Club Level amenities
        MockAmenity(id: "club-lounge", type: .food, name: "Sideline Club Lounge", shortName: "Club", icon: "🍷", level: 2, x: 700, y: 280),
        MockAmenity(id: "club-food1", type: .food, name: "Club Concessions", shortName: "Food", icon: "🍷", level: 2, x: 500, y: 330),
        MockAmenity(id: "club-food2", type: .food, name: "Premium Bar", shortName: "Bar", icon: "🍷", level: 2, x: 900, y: 330),
        MockAmenity(id: "club-rest1", type: .restroom, name: "Club Restrooms", shortName: "WC", icon: "🚻", level: 2, x: 500, y: 700),
        MockAmenity(id: "club-rest2", type: .restroom, name: "VIP Restrooms", shortName: "VIP", icon: "🚻", level: 2, x: 900, y: 700),
        MockAmenity(id: "club-info", type: .info, name: "Club Services", shortName: "Info", icon: "ℹ️", level: 2, x: 700, y: 350),

        // Level 3 - Upper bowl amenities
        MockAmenity(id: "upper-food1", type: .food, name: "Upper Concessions N", shortName: "Food", icon: "🍔", level: 3, x: 600, y: 200),
        MockAmenity(id: "upper-food2", type: .food, name: "Upper Concessions S", shortName: "Food", icon: "🍔", level: 3, x: 750, y: 1050),
        MockAmenity(id: "upper-rest1", type: .restroom, name: "Upper Restrooms N", shortName: "WC", icon: "🚻", level: 3, x: 700, y: 170),
        MockAmenity(id: "upper-rest2", type: .restroom, name: "Upper Restrooms S", shortName: "WC", icon: "🚻", level: 3, x: 700, y: 1080),
    ]
}
