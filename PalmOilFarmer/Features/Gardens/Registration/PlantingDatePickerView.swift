import SwiftUI

struct PlantingDatePickerView: View {
    @State private var month: Int
    @State private var year: Int
    let onConfirm: (Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    private let currentYear = Calendar.current.component(.year, from: .now)

    init(month: Int = 10, year: Int = 2016, onConfirm: @escaping (Int, Int) -> Void) {
        _month = State(initialValue: min(max(month, 1), 12))
        _year = State(initialValue: min(max(year, 1900), Calendar.current.component(.year, from: .now)))
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Tahun Tanam", confirmationAction: {
                onConfirm(month, year)
                dismiss()
            }, onClose: { dismiss() })
            HStack(spacing: 0) {
                Picker("Bulan tanam", selection: $month) {
                    ForEach(1...12, id: \.self) { value in
                        Text(Self.monthNames[value - 1]).tag(value)
                    }
                }
                Picker("Tahun tanam", selection: $year) {
                    ForEach(1900...currentYear, id: \.self) { value in
                        Text(String(value)).tag(value)
                    }
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 217)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .fittedSheetHeight()
        .presentationDragIndicator(.visible)
    }

    static let monthNames = ["Januari", "Februari", "Maret", "April", "Mei", "Juni",
                             "Juli", "Agustus", "September", "Oktober", "November", "Desember"]
}

#Preview("Tahun Tanam · Oktober 2016", traits: .sizeThatFitsLayout) {
    PlantingDatePickerView(onConfirm: { _, _ in }).frame(width: 402, height: 351)
}
