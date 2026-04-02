import SwiftUI
import ARKit
import RealityKit

// MARK: - Calibration State

enum CalibrationStep {
    case notStarted
    case placingPointA
    case placingPointB
    case calibrated

    var instruction: String {
        switch self {
        case .notStarted: return ""
        case .placingPointA: return "Walk to the NORTH boundary\nof your demo area"
        case .placingPointB: return "Now walk to the SOUTH boundary\nof your demo area"
        case .calibrated: return ""
        }
    }
}

// MARK: - AR Compass View

struct ARCompassView: View {
    @ObservedObject var viewModel: IndoorCompassViewModel
    @State private var arView: ARView?
    @State private var showMiniMap = true
    @State private var calibrationStep: CalibrationStep = .notStarted
    @State private var calibrationPointA: simd_float3?
    @State private var calibrationPointB: simd_float3?
    @State private var calibrationDistance: Float = 0
    @State private var showingSearch = false

    var body: some View {
        ZStack {
            ARViewContainer(
                arView: $arView,
                bearing: viewModel.isDemoMode ? viewModel.dynamicBearing : (viewModel.directions?.compassBearing ?? 0),
                distance: viewModel.isDemoMode ? viewModel.dynamicDistance : (viewModel.directions?.totalDistance ?? 0),
                userLocalX: viewModel.userLocalX,
                userLocalY: viewModel.userLocalY,
                targetLocalX: viewModel.targetLocalX,
                targetLocalY: viewModel.targetLocalY,
                calibrationPointA: calibrationPointA,
                calibrationPointB: calibrationPointB,
                isCalibrated: calibrationStep == .calibrated
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                // Top bar: calibrate button (left) + mini-map (right)
                HStack(alignment: .top) {
                    // Controls (top-left): Search + Calibrate
                    VStack(alignment: .leading, spacing: 6) {
                        // Search destination button
                        Button {
                            showingSearch = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14))
                                Text(viewModel.targetName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(8)
                        }

                        // Calibrate button
                        Button {
                            if calibrationStep == .calibrated {
                                calibrationStep = .notStarted
                                calibrationPointA = nil
                                calibrationPointB = nil
                                calibrationDistance = 0
                            }
                            calibrationStep = .placingPointA
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: calibrationStep == .calibrated ? "checkmark.circle.fill" : "ruler")
                                    .font(.system(size: 14))
                                Text(calibrationStep == .calibrated ? "Recalibrate" : "Calibrate")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(calibrationStep == .calibrated ? Color.green.opacity(0.7) : Color.black.opacity(0.5))
                            .cornerRadius(8)
                        }

                        // Calibration info
                        if calibrationStep == .calibrated, calibrationDistance > 0 {
                            Text("\(Int(calibrationDistance))m area → 240m stadium")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.leading, 12)

                    Spacer()

                    // Mini-map toggle + map (top-right)
                    VStack(alignment: .trailing, spacing: 8) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showMiniMap.toggle()
                            }
                        } label: {
                            Image(systemName: showMiniMap ? "map.fill" : "map")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 60)

                        if showMiniMap, let directions = viewModel.directions {
                            StadiumMiniMapView(
                                userDisplayX: viewModel.userDisplayX,
                                userDisplayY: viewModel.userDisplayY,
                                targetSectionId: directions.section.sectionId
                            )
                            .background(Color.black.opacity(0.8))
                            .scaleEffect(0.25)
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                            .opacity(0.85)
                            .shadow(color: .black.opacity(0.4), radius: 8)
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(.trailing, 12)
                }

                Spacer()

                // Calibration panel (shown during calibration)
                if calibrationStep == .placingPointA || calibrationStep == .placingPointB {
                    calibrationPanel
                }

                // Distance and info overlay
                VStack(spacing: 12) {
                    if let directions = viewModel.directions {
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("\(viewModel.isDemoMode ? viewModel.dynamicDistance : directions.totalDistance)m")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            Divider()
                                .frame(height: 50)
                                .background(Color.white.opacity(0.5))

                            VStack(spacing: 4) {
                                Text(viewModel.targetName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(directions.stadiumName)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.6))
                                .blur(radius: 10)
                        )

                        if viewModel.isDemoMode {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                Text("DEMO MODE")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingSearch) {
            NavigationSearchView(
                destinations: viewModel.allDestinations,
                currentDestination: viewModel.selectedDestination,
                onSelect: { destination in
                    viewModel.selectDestination(destination)
                }
            )
        }
    }

    // MARK: - Calibration Panel

    private var calibrationPanel: some View {
        VStack(spacing: 16) {
            // Step indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(calibrationPointA != nil ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 30, height: 2)
                Circle()
                    .fill(calibrationPointB != nil ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)
            }

            Text(calibrationStep.instruction)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                if calibrationStep == .placingPointA {
                    Button {
                        calibrationPointA = captureCurrentPosition()
                        if calibrationPointA != nil {
                            calibrationStep = .placingPointB
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                            Text("Set North Point")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                } else if calibrationStep == .placingPointB {
                    Button {
                        calibrationPointB = captureCurrentPosition()
                        if let a = calibrationPointA, let b = calibrationPointB {
                            calibrationDistance = length(b - a)
                            calibrationStep = .calibrated
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                            Text("Set South Point")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }

                Button {
                    calibrationStep = .notStarted
                    calibrationPointA = nil
                    calibrationPointB = nil
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.75))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

    private func captureCurrentPosition() -> simd_float3? {
        guard let frame = arView?.session.currentFrame else { return nil }
        let col = frame.camera.transform.columns.3
        return simd_float3(col.x, col.y, col.z)
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {
    @Binding var arView: ARView?
    let bearing: Double
    let distance: Int
    let userLocalX: Double
    let userLocalY: Double
    let targetLocalX: Double
    let targetLocalY: Double
    let calibrationPointA: simd_float3?
    let calibrationPointB: simd_float3?
    let isCalibrated: Bool

    /// Default floor plan size before calibration (5m x 5m)
    private let defaultFloorSize: Float = 5.0
    /// Stadium local coordinate range: -120 to 120 = 240 units
    private let stadiumCoordRange: Float = 240.0

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)

        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = [.horizontal]
        view.session.run(configuration)

        // Direction arrow (floating at eye level)
        let arrowEntity = createArrowEntity()
        let arrowAnchor = AnchorEntity(world: .zero)
        arrowAnchor.addChild(arrowEntity)
        view.scene.addAnchor(arrowAnchor)

        // Default floor plan (small preview until calibrated)
        let floorAnchor = AnchorEntity(world: [0, -1.5, -0.5])

        if let floorPlanEntity = createFloorPlanEntity(size: defaultFloorSize) {
            floorAnchor.addChild(floorPlanEntity)
            context.coordinator.floorPlanEntity = floorPlanEntity
        }

        let userDotEntity = createUserDotEntity()
        floorAnchor.addChild(userDotEntity)

        let targetPinEntity = createTargetPinEntity()
        floorAnchor.addChild(targetPinEntity)

        view.scene.addAnchor(floorAnchor)

        context.coordinator.arrowEntity = arrowEntity
        context.coordinator.userDotEntity = userDotEntity
        context.coordinator.targetPinEntity = targetPinEntity
        context.coordinator.arrowAnchor = arrowAnchor
        context.coordinator.floorAnchor = floorAnchor

        DispatchQueue.main.async {
            self.arView = view
        }

        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Update direction arrow
        if let arrowEntity = context.coordinator.arrowEntity {
            let bearingRadians = Float(bearing * .pi / 180.0)
            arrowEntity.transform.rotation = simd_quatf(angle: -bearingRadians, axis: [0, 1, 0])
            let distanceScale = min(Float(distance) / 100.0, 5.0)
            arrowEntity.position = [0, 0, -2.0 - distanceScale]
        }

        // Apply calibration when newly completed
        if isCalibrated && !context.coordinator.hasAppliedCalibration {
            applyCalibration(uiView: uiView, context: context)
            context.coordinator.hasAppliedCalibration = true
        }

        // Reset if calibration was cleared
        if !isCalibrated && context.coordinator.hasAppliedCalibration {
            resetToDefaultFloorPlan(uiView: uiView, context: context)
            context.coordinator.hasAppliedCalibration = false
        }

        // Calculate coordinate scale based on calibration state
        let coordScale: Float
        if isCalibrated, let a = calibrationPointA, let b = calibrationPointB {
            let walkDistance = length(b - a)
            coordScale = walkDistance / stadiumCoordRange
        } else {
            coordScale = defaultFloorSize / stadiumCoordRange
        }

        // Update user position dot
        if let userDot = context.coordinator.userDotEntity {
            let arX = Float(userLocalX) * coordScale
            let arZ = -Float(userLocalY) * coordScale
            userDot.position = [arX, 0.03, arZ]
        }

        // Update target pin position
        if let targetPin = context.coordinator.targetPinEntity {
            let arX = Float(targetLocalX) * coordScale
            let arZ = -Float(targetLocalY) * coordScale
            targetPin.position = [arX, 0.0, arZ]
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Calibration

    private func applyCalibration(uiView: ARView, context: Context) {
        guard let a = calibrationPointA, let b = calibrationPointB else { return }

        // Remove old floor plan and calibration markers
        if let oldAnchor = context.coordinator.floorAnchor {
            uiView.scene.removeAnchor(oldAnchor)
        }
        removeCalibrationMarkers(from: uiView, context: context)

        // Calculate calibration geometry
        let midpoint = (a + b) / 2.0
        let northDir = a - midpoint // Direction toward north point
        let walkDistance = length(b - a)

        // Rotation: align floor plan's -Z axis (north) with the direction to point A
        let angle = atan2(northDir.x, northDir.z)

        // Place floor plan on the ground at the midpoint
        // Use the average Y minus ~1.5m for floor level
        let floorY = midpoint.y - 1.5
        let floorAnchor = AnchorEntity(world: [midpoint.x, floorY, midpoint.z])
        floorAnchor.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])

        // Create floor plan at the walked distance (maps to 240m stadium)
        if let floorPlan = createFloorPlanEntity(size: walkDistance) {
            floorAnchor.addChild(floorPlan)
            context.coordinator.floorPlanEntity = floorPlan
        }

        let userDot = createUserDotEntity()
        floorAnchor.addChild(userDot)
        context.coordinator.userDotEntity = userDot

        let targetPin = createTargetPinEntity()
        floorAnchor.addChild(targetPin)
        context.coordinator.targetPinEntity = targetPin

        uiView.scene.addAnchor(floorAnchor)
        context.coordinator.floorAnchor = floorAnchor

        // Add visual markers at the calibration boundary points
        addCalibrationMarker(
            to: uiView,
            at: [a.x, floorY, a.z],
            color: .systemGreen,
            label: "N",
            context: context
        )
        addCalibrationMarker(
            to: uiView,
            at: [b.x, floorY, b.z],
            color: .systemRed,
            label: "S",
            context: context
        )

        print("✅ AR Calibration applied: \(Int(walkDistance))m walk → 240m stadium")
    }

    private func resetToDefaultFloorPlan(uiView: ARView, context: Context) {
        // Remove calibrated floor plan and markers
        if let oldAnchor = context.coordinator.floorAnchor {
            uiView.scene.removeAnchor(oldAnchor)
        }
        removeCalibrationMarkers(from: uiView, context: context)

        // Recreate default small floor plan
        let floorAnchor = AnchorEntity(world: [0, -1.5, -0.5])

        if let floorPlan = createFloorPlanEntity(size: defaultFloorSize) {
            floorAnchor.addChild(floorPlan)
            context.coordinator.floorPlanEntity = floorPlan
        }

        let userDot = createUserDotEntity()
        floorAnchor.addChild(userDot)
        context.coordinator.userDotEntity = userDot

        let targetPin = createTargetPinEntity()
        floorAnchor.addChild(targetPin)
        context.coordinator.targetPinEntity = targetPin

        uiView.scene.addAnchor(floorAnchor)
        context.coordinator.floorAnchor = floorAnchor
    }

    private func addCalibrationMarker(to arView: ARView, at position: simd_float3, color: UIColor, label: String, context: Context) {
        let container = ModelEntity()

        // Tall pole
        let poleMesh = MeshResource.generateBox(size: [0.04, 2.0, 0.04])
        var poleMaterial = UnlitMaterial()
        poleMaterial.color = .init(tint: color.withAlphaComponent(0.6))
        let pole = ModelEntity(mesh: poleMesh, materials: [poleMaterial])
        pole.position = [0, 1.0, 0]
        container.addChild(pole)

        // Sphere on top
        let sphereMesh = MeshResource.generateSphere(radius: 0.12)
        var sphereMaterial = SimpleMaterial()
        sphereMaterial.color = .init(tint: color)
        sphereMaterial.metallic = .float(0.5)
        let sphere = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
        sphere.position = [0, 2.1, 0]
        container.addChild(sphere)

        // Ground ring
        let ringMesh = MeshResource.generatePlane(width: 0.6, depth: 0.6, cornerRadius: 0.3)
        var ringMaterial = UnlitMaterial()
        ringMaterial.color = .init(tint: color.withAlphaComponent(0.4))
        let ring = ModelEntity(mesh: ringMesh, materials: [ringMaterial])
        ring.position = [0, 0.01, 0]
        container.addChild(ring)

        let anchor = AnchorEntity(world: position)
        anchor.addChild(container)
        arView.scene.addAnchor(anchor)

        if label == "N" {
            context.coordinator.calibrationMarkerA = anchor
        } else {
            context.coordinator.calibrationMarkerB = anchor
        }
    }

    private func removeCalibrationMarkers(from arView: ARView, context: Context) {
        if let marker = context.coordinator.calibrationMarkerA {
            arView.scene.removeAnchor(marker)
            context.coordinator.calibrationMarkerA = nil
        }
        if let marker = context.coordinator.calibrationMarkerB {
            arView.scene.removeAnchor(marker)
            context.coordinator.calibrationMarkerB = nil
        }
    }

    // MARK: - Entity Creation

    private func createFloorPlanEntity(size: Float) -> ModelEntity? {
        let mapView = StadiumMiniMapView(
            userDisplayX: -999,
            userDisplayY: -999,
            targetSectionId: nil
        )
        .frame(width: 800, height: 800)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))

        let renderer = ImageRenderer(content: mapView)
        renderer.scale = 1.0

        guard let uiImage = renderer.uiImage,
              let cgImage = uiImage.cgImage else {
            print("❌ ARCompassView: Failed to render floor plan image")
            return nil
        }

        guard let texture = try? TextureResource.generate(
            from: cgImage,
            options: .init(semantic: .color)
        ) else {
            print("❌ ARCompassView: Failed to create texture resource")
            return nil
        }

        var material = UnlitMaterial()
        material.color = .init(
            tint: .white.withAlphaComponent(0.9),
            texture: .init(texture)
        )

        let mesh = MeshResource.generatePlane(width: size, depth: size)
        let entity = ModelEntity(mesh: mesh, materials: [material])

        // Border frame
        let borderMesh = MeshResource.generatePlane(
            width: size + 0.06,
            depth: size + 0.06
        )
        var borderMaterial = UnlitMaterial()
        borderMaterial.color = .init(tint: UIColor.systemGreen.withAlphaComponent(0.3))
        let borderEntity = ModelEntity(mesh: borderMesh, materials: [borderMaterial])
        borderEntity.position = [0, -0.002, 0]
        entity.addChild(borderEntity)

        return entity
    }

    private func createUserDotEntity() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.06)
        var material = SimpleMaterial()
        material.color = .init(tint: .systemBlue)
        material.metallic = .float(0.8)
        material.roughness = .float(0.2)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = [0, 0.03, 0]
        return entity
    }

    private func createTargetPinEntity() -> ModelEntity {
        let container = ModelEntity()

        let pinMesh = MeshResource.generateBox(size: [0.02, 0.2, 0.02])
        var pinMaterial = SimpleMaterial()
        pinMaterial.color = .init(tint: .systemGreen)
        let pinEntity = ModelEntity(mesh: pinMesh, materials: [pinMaterial])
        pinEntity.position = [0, 0.1, 0]
        container.addChild(pinEntity)

        let headMesh = MeshResource.generateSphere(radius: 0.05)
        var headMaterial = SimpleMaterial()
        headMaterial.color = .init(tint: .systemGreen)
        headMaterial.metallic = .float(0.6)
        headMaterial.roughness = .float(0.2)
        let headEntity = ModelEntity(mesh: headMesh, materials: [headMaterial])
        headEntity.position = [0, 0.22, 0]
        container.addChild(headEntity)

        return container
    }

    private func createArrowEntity() -> ModelEntity {
        let arrowMesh = MeshResource.generateBox(size: [0.1, 0.1, 0.5])
        let arrowMaterial = SimpleMaterial(color: .green, isMetallic: false)
        let arrowEntity = ModelEntity(mesh: arrowMesh, materials: [arrowMaterial])

        let tipMesh = MeshResource.generateBox(size: [0.2, 0.2, 0.3])
        let tipEntity = ModelEntity(mesh: tipMesh, materials: [arrowMaterial])
        tipEntity.position = [0, 0, -0.4]
        tipEntity.scale = [1.0, 1.0, 0.5]

        arrowEntity.addChild(tipEntity)
        arrowEntity.position = [0, 0, -2.0]

        return arrowEntity
    }

    // MARK: - Coordinator

    class Coordinator {
        var arrowEntity: ModelEntity?
        var floorPlanEntity: ModelEntity?
        var userDotEntity: ModelEntity?
        var targetPinEntity: ModelEntity?
        var arrowAnchor: AnchorEntity?
        var floorAnchor: AnchorEntity?
        var calibrationMarkerA: AnchorEntity?
        var calibrationMarkerB: AnchorEntity?
        var hasAppliedCalibration = false
    }
}

#Preview {
    let mockGame = SportingEvent.sampleEvents[0]
    let mockLocation = UserLocation(
        name: "Marriott Hotel",
        address: "123 Main St, Miami, FL",
        coordinate: Coordinate(latitude: 25.7617, longitude: -80.1918)
    )

    let mockSchedule = GameSchedule(
        id: "preview-schedule",
        game: mockGame,
        userLocation: mockLocation,
        sectionNumber: "118",
        scheduleSteps: [],
        recommendedGate: mockGame.stadium.entryGates[0],
        purchaseDate: Date(),
        arrivalPreference: .balanced,
        transportationMode: .publicTransit,
        parkingReservation: nil,
        foodOrder: nil,
        confidenceScore: 92
    )

    let viewModel = IndoorCompassViewModel(schedule: mockSchedule)

    return ARCompassView(viewModel: viewModel)
}
