import SwiftUI

/// "Tahun Tanam" sheet: month and year wheels.
struct PlantingDatePickerView: View {
    @State private var month: Int
    @State private var year: Int
    let onConfirm: (Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let currentYear = Calendar.current.component(.year, from: .now)

    init(month: Int = Calendar.current.component(.month, from: .now),
         year: Int = Calendar.current.component(.year, from: .now), onConfirm: @escaping (Int, Int) -> Void) {
        _month = State(initialValue: min(max(month, 1), 12))
        _year = State(initialValue: min(max(year, 1900), Calendar.current.component(.year, from: .now)))
        self.onConfirm = onConfirm
    }

    var body: some View {
        DynamicSheet(animation: .bouncy, size: .medium) {
            sheetContent
        }
        .presentationBackgroundInteraction(.disabled)
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
    }

    @ViewBuilder
    private var sheetContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                if dynamicTypeSize.isAccessibilitySize {
                    Text("Tahun Tanam").font(.headline)
                    VStack(spacing: 12) {
                        cancelButton
                        confirmButton
                    }
                } else {
                    HStack(spacing: 12) {
                        cancelButton
                        Spacer(minLength: 0)
                        Text("Tahun Tanam").font(.headline)
                        Spacer(minLength: 0)
                        confirmButton
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            ScrollView {
                VStack(spacing: 0) {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 16) {
                            monthPicker.pickerStyle(.menu)
                            yearPicker.pickerStyle(.menu)
                        }
                        .font(.title3)
                        .padding(24)
                    } else {
                        HStack(spacing: 0) {
                            monthPicker
                            yearPicker
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 217)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        Text("Jika lupa bulan tanam, pilih perkiraan saja.")
                            .font(.footnote).foregroundStyle(.secondary)
                            .padding(.bottom, 24)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var cancelButton: some View {
        RegistrationIconButton(symbol: "xmark", label: "Batal") {
            dismiss()
        }
    }

    private var confirmButton: some View {
        RegistrationIconButton(symbol: "checkmark", label: "Selesai", isProminent: true) {
            onConfirm(month, year)
            dismiss()
        }
    }

    private var monthPicker: some View {
        Picker("Bulan tanam", selection: $month) {
            ForEach(1...12, id: \.self) { value in
                Text(Self.monthNames[value - 1]).tag(value)
            }
        }
    }

    private var yearPicker: some View {
        Picker("Tahun tanam", selection: $year) {
            ForEach(1900...currentYear, id: \.self) { value in
                Text(String(value)).tag(value)
            }
        }
    }

    static let monthNames = ["Januari", "Februari", "Maret", "April", "Mei", "Juni",
                             "Juli", "Agustus", "September", "Oktober", "November", "Desember"]
}

#if DEBUG
#Preview("Sheet Tahun Tanam") {
    SheetPreview {
        PlantingDatePickerView(month: 10, year: 2016, onConfirm: { _, _ in })
    }
}

#Preview("Sheet Tahun Tanam · Teks besar") {
    SheetPreview {
        PlantingDatePickerView(month: 10, year: 2016, onConfirm: { _, _ in })
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}

#Preview("Isi Tahun Tanam (tanpa sheet)", traits: .sizeThatFitsLayout) {
    PlantingDatePickerView(onConfirm: { _, _ in }).frame(width: 402)
}
#endif
