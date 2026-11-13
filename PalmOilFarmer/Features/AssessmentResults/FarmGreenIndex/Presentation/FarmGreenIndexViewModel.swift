import Foundation
import Observation

/// Visual sheet state for Farm Green Index (Peta Kondisi Kebun).
public enum FarmGreenIndexSheetState: Equatable, Sendable {
    /// Collapsed capsule handle at the bottom. Sliced from: "Peta Kondisi Kebun / Collapsed"
    case collapsed

    /// Expanded sheet displaying condition legend rows. Sliced from: "Peta Kondisi Kebun / Legend"
    case legend

    /// Detailed inspection sheet for a selected category. Sliced from: "Detail Kondisi / [Normal|Terindikasi|Defisiensi|Tidak Wajar]"
    case detail(TreeConditionCategory)

    /// Area division picker bottom sheet (Per Pohon vs Per Zona). Sliced from: "Pemupukan / Peta Dosis Pupuk / Pembagian Area"
    case areaPicker
}

/// ViewModel managing presentation state for Farm Green Index screen.
@Observable
@MainActor
public final class FarmGreenIndexViewModel {
    public private(set) var item: FarmGreenIndexItem?
    public private(set) var isLoading: Bool = false
    public private(set) var errorMessage: String? = nil

    /// Current state of the bottom sheet / card
    public var sheetState: FarmGreenIndexSheetState = .collapsed

    /// Currently selected area division mode
    public var selectedAreaDivision: FarmAreaDivisionMode = .perPohon

    /// Previous sheet state before opening the area picker
    private var previousSheetState: FarmGreenIndexSheetState = .legend

    /// Currently highlighted tree marker pin on the map
    public var selectedPin: TreePinItem? = nil

    private let gardenId: String
    private let repository: any FarmGreenIndexRepositoryProtocol

    public init(
        gardenId: String = "default-garden",
        repository: (any FarmGreenIndexRepositoryProtocol)? = nil
    ) {
        self.gardenId = gardenId
        self.repository = repository ?? DummyFarmGreenIndexRepository()
    }

    public func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.fetchFarmGreenIndex(for: gardenId)
            self.item = result
            self.isLoading = false
        } catch {
            self.errorMessage = "Gagal memuat peta kondisi kebun: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    public func selectCategory(_ category: TreeConditionCategory) {
        sheetState = .detail(category)
    }

    public func showLegend() {
        sheetState = .legend
        selectedPin = nil
    }

    public func collapseSheet() {
        sheetState = .collapsed
    }

    public func toggleSheet() {
        switch sheetState {
        case .collapsed:
            sheetState = .legend
        case .legend:
            sheetState = .collapsed
        case .detail:
            sheetState = .legend
        case .areaPicker:
            sheetState = previousSheetState
        }
    }

    public func openAreaPicker() {
        if sheetState == .areaPicker {
            sheetState = previousSheetState
        } else {
            previousSheetState = sheetState
            sheetState = .areaPicker
        }
    }

    public func closeAreaPicker() {
        sheetState = previousSheetState == .areaPicker ? .legend : previousSheetState
    }

    public func selectAreaDivision(_ mode: FarmAreaDivisionMode) {
        selectedAreaDivision = mode
        if mode == .perZona {
            selectedPin = nil
        }
    }

    public func selectPin(_ pin: TreePinItem) {
        selectedPin = pin
        sheetState = .detail(pin.category)
    }

    public func deselectPin() {
        selectedPin = nil
    }
}

