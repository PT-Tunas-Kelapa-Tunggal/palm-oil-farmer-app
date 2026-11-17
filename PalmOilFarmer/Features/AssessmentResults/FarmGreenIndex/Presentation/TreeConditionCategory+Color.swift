import SwiftUI

extension TreeConditionCategory {
    /// Tree condition colour from Sketch `Status/*` (Normal uses `Accent/Success`).
    /// Always shown together with the condition's text label.
    var color: Color {
        switch self {
        case .normal: KropsTheme.accentSuccess
        case .terindikasi: KropsTheme.statusCaution
        case .defisiensi: KropsTheme.statusWarning
        case .tidakWajar: KropsTheme.statusNeutral
        case .unknown: KropsTheme.fillBlack45
        }
    }
}
