import SwiftUI

/// Primary call-to-action button allowing the farmer to save their customized fertilizer composition.
/// Sliced from Sketch: "Hasil Peninjauan / Perkiraan Biaya Pupuk / Fertilizer Changed"
public struct SaveCompositionButton: View {
    public let title: String
    public let action: () -> Void

    public init(
        title: String = "Simpan Komposisi Ini",
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(red: 0.08, green: 0.08, blue: 0.09))
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SaveCompositionButton(title: "Simpan Komposisi Ini")
        .padding()
}

