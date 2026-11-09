import SwiftUI

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
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
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
                Text("Kalau lupa bulannya, pilih perkiraan saja.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
        }
        .fittedSheetHeight()
        .presentationDragIndicator(.visible)
    }

    private var cancelButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark").font(.title2).accessibilityLabel("Batal")
        }
    }

    private var confirmButton: some View {
        Button {
            onConfirm(month, year)
            dismiss()
        } label: {
            Image(systemName: "checkmark").font(.title2).accessibilityLabel("Selesai")
        }
        .buttonStyle(.glassProminent)
        .tint(RegistrationStyle.actionTint)
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

#Preview("COdedUI5 · Tahun Tanam", traits: .sizeThatFitsLayout) {
    PlantingDatePickerView(onConfirm: { _, _ in }).frame(width: 402)
}
