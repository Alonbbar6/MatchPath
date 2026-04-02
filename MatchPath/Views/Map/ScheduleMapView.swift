import SwiftUI
import MapKit

/// Main map view for tracking schedule progress
struct ScheduleMapView: View {
    let schedule: GameSchedule
    @StateObject private var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss

    init(schedule: GameSchedule) {
        self.schedule = schedule
        _viewModel = StateObject(wrappedValue: MapViewModel(schedule: schedule))
    }

    var body: some View {
        ZStack {
            // Map
            MapViewRepresentable(
                region: $viewModel.region,
                annotations: viewModel.annotations
            )
            .edgesIgnoringSafeArea(.all)
            .background(
                Group {
                    #if os(iOS)
                    Color(.systemBackground)
                    #else
                    Color(nsColor: .windowBackgroundColor)
                    #endif
                }
            )

            // Top overlay - Progress card
            VStack {
                progressCard
                    .padding()

                Spacer()

                // Bottom controls
                bottomControls
                    .padding()
            }
        }
        .background(
            Group {
                #if os(iOS)
                Color(.systemBackground)
                #else
                Color(nsColor: .windowBackgroundColor)
                #endif
            }
        )
        .navigationTitle("Track Schedule")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    viewModel.stopNavigation()
                    dismiss()
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    viewModel.stopNavigation()
                    dismiss()
                }
            }
            #endif
        }
        .onAppear {
            print("📍 ScheduleMapView appeared")
            viewModel.startNavigation()
        }
        .onDisappear {
            print("📍 ScheduleMapView disappeared")
            viewModel.stopNavigation()
        }
    }

    private var progressCard: some View {
        VStack(spacing: 12) {
            // Progress bar
            HStack {
                Text(viewModel.progressText)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(String(format: "%.0f%%", viewModel.progressPercentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)

                    // Progress
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * viewModel.progressPercentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)

            Divider()

            // Current step info
            if let currentStep = viewModel.currentStep {
                HStack(spacing: 12) {
                    Image(systemName: currentStep.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentStep.title)
                            .font(.headline)

                        Text(currentStep.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
            }

            // Distance and ETA to next step
            if let nextStep = viewModel.nextStep {
                Divider()

                HStack {
                    Label("Next:", systemImage: "arrow.forward.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(nextStep.title)
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    if let distance = viewModel.formatDistance() {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(distance)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    if let eta = viewModel.formatETA() {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(eta)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
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
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var bottomControls: some View {
        HStack(spacing: 12) {
            // Previous step button
            Button(action: {
                viewModel.goToPreviousStep()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                    Text("Back")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .disabled(viewModel.currentStepIndex == 0)
            .opacity(viewModel.currentStepIndex == 0 ? 0.5 : 1.0)

            Spacer()

            // Center on location button
            Button(action: {
                viewModel.centerOnCurrentLocation()
            }) {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .padding(12)
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
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }

            // Fit all button
            Button(action: {
                viewModel.fitAllAnnotations()
            }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.title3)
                    .padding(12)
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
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }

            Spacer()

            // Next step button
            Button(action: {
                viewModel.advanceToNextStep()
            }) {
                HStack(spacing: 6) {
                    Text("Next")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .disabled(viewModel.currentStepIndex >= schedule.scheduleSteps.count - 1)
            .opacity(viewModel.currentStepIndex >= schedule.scheduleSteps.count - 1 ? 0.5 : 1.0)
        }
    }
}

// MARK: - MapView Representable

#if os(iOS)
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [MKAnnotation]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: true)

        // Update annotations
        let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(currentAnnotations)
        mapView.addAnnotations(annotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }

            // Custom annotation for schedule locations
            if let scheduleAnnotation = annotation as? ScheduleAnnotation {
                let identifier = "ScheduleAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                // Customize appearance
                annotationView?.markerTintColor = scheduleAnnotation.color
                #if os(iOS)
                annotationView?.glyphImage = UIImage(systemName: scheduleAnnotation.iconName)
                #else
                annotationView?.glyphImage = NSImage(systemSymbolName: scheduleAnnotation.iconName, accessibilityDescription: nil)
                #endif

                // Make primary locations larger
                if scheduleAnnotation.isPrimary {
                    annotationView?.displayPriority = .required
                }

                return annotationView
            }

            // Custom annotation for current location
            if annotation is CurrentLocationAnnotation {
                let identifier = "CurrentLocationAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                annotationView?.markerTintColor = .systemBlue
                #if os(iOS)
                annotationView?.glyphImage = UIImage(systemName: "person.fill")
                #else
                annotationView?.glyphImage = NSImage(systemSymbolName: "person.fill", accessibilityDescription: nil)
                #endif
                annotationView?.displayPriority = .required

                return annotationView
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}

#else
// MARK: - MapView Representable (macOS)

struct MapViewRepresentable: NSViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [MKAnnotation]

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: true)

        // Update annotations
        let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(currentAnnotations)
        mapView.addAnnotations(annotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }

            // Custom annotation for schedule locations
            if let scheduleAnnotation = annotation as? ScheduleAnnotation {
                let identifier = "ScheduleAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                // Customize appearance
                annotationView?.markerTintColor = scheduleAnnotation.color
                annotationView?.glyphImage = NSImage(systemSymbolName: scheduleAnnotation.iconName, accessibilityDescription: nil)

                // Make primary locations larger
                if scheduleAnnotation.isPrimary {
                    annotationView?.displayPriority = .required
                }

                return annotationView
            }

            // Custom annotation for current location
            if annotation is CurrentLocationAnnotation {
                let identifier = "CurrentLocationAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                annotationView?.markerTintColor = .systemBlue
                annotationView?.glyphImage = NSImage(systemSymbolName: "person.fill", accessibilityDescription: nil)
                annotationView?.displayPriority = .required

                return annotationView
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}
#endif
