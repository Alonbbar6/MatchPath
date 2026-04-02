import Foundation
import Combine

/// Service to manage user's preferred layout style
class LayoutPreferenceService: ObservableObject {
    static let shared = LayoutPreferenceService()

    @Published var layoutStyle: LayoutStyle {
        didSet {
            UserDefaults.standard.set(layoutStyle.rawValue, forKey: "layoutStyle")
        }
    }

    enum LayoutStyle: String, CaseIterable {
        case unified = "unified"        // Layout A: Build→Preview→Buy (single flow)
        case modular = "modular"        // Layout B: Feature-separated modules

        var displayName: String {
            switch self {
            case .unified: return "Unified Flow"
            case .modular: return "Feature Modules"
            }
        }

        var description: String {
            switch self {
            case .unified:
                return "All-in-one experience with guided schedule building"
            case .modular:
                return "Separate modules for Schedule, Tickets, Wayfinding, and Travel"
            }
        }

        var icon: String {
            switch self {
            case .unified: return "rectangle.stack.fill"
            case .modular: return "square.grid.2x2.fill"
            }
        }
    }

    private init() {
        // Load saved preference or default to unified
        if let savedStyle = UserDefaults.standard.string(forKey: "layoutStyle"),
           let style = LayoutStyle(rawValue: savedStyle) {
            self.layoutStyle = style
        } else {
            self.layoutStyle = .unified
        }
    }

    func switchLayout(to style: LayoutStyle) {
        layoutStyle = style
    }
}
