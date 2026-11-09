enum BoundaryDrawingGuideStep: Int, Hashable, CaseIterable {
    case zoom
    case tap

    var title: String {
        switch self {
        case .zoom: "Perbesar Peta Dulu"
        case .tap: "Tandai Sudut Kebun"
        }
    }

    var message: String {
        switch self {
        case .zoom: "Rentangkan dua jari agar sudut kebun terlihat jelas dan mudah ditandai."
        case .tap: "Ketuk peta di setiap sudut kebun. Titik akan tersambung menjadi batas kebun."
        }
    }

    var buttonTitle: String {
        switch self {
        case .zoom: "Lanjut"
        case .tap: "Mulai Tandai Kebun"
        }
    }
}

struct BoundaryDrawingGuideState {
    private(set) var step: BoundaryDrawingGuideStep = .zoom

    /// Returns false when the primary action should leave the guide and start mapping.
    mutating func advance() -> Bool {
        guard step == .zoom else { return false }
        step = .tap
        return true
    }

    /// Returns false when back should leave the guide and return to location confirmation.
    mutating func goBack() -> Bool {
        guard step == .tap else { return false }
        step = .zoom
        return true
    }
}
