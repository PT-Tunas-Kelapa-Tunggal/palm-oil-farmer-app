import SwiftUI

struct HarvestHistoryScreen: View {
    let onSave: (HarvestRecord) -> Bool
    @State private var frequency: Int
    @State private var weight: Double
    @State private var showsError = false
    @Environment(\.dismiss) private var dismiss

    init(record: HarvestRecord?, onSave: @escaping (HarvestRecord) -> Bool) {
        self.onSave = onSave
        _frequency = State(initialValue: min(max(record?.frequencyPerMonth ?? 2, 1), 31))
        _weight = State(initialValue: record?.latestWeightKg ?? 450)
    }

    private var weightOptions: [Double] {
        Array(Set(stride(from: 50.0, through: 5000.0, by: 50) + [weight])).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Riwayat Panen", confirmationAction: save, onClose: { dismiss() })
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Text("Frekuensi Panen").font(.title2.weight(.bold))
                        Text("Jumlah panen yang biasanya dilakukan\ndi kebun ini")
                            .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Stepper(value: $frequency, in: 1...31) {
                            Text("\(frequency) kali")
                                .font(.title.weight(.semibold))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        Text("dalam satu bulan").font(.body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .frame(minHeight: 254)
                    .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 48))

                    VStack(spacing: 0) {
                        Text("Rata-rata berat panen").font(.title2.weight(.bold))
                        Text("Perkiraan berat TBS yang didapat setiap\nkali panen")
                            .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Picker("Berat panen dalam kg", selection: $weight) {
                            ForEach(weightOptions, id: \.self) { value in
                                Text("\(value.formatted()) kg").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 217)
                        Text("setiap kali panen").font(.body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .frame(minHeight: 363)
                    .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 48))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.height(721), .large])
        .alert("Riwayat belum tersimpan", isPresented: $showsError) {
            Button("Mengerti", role: .cancel) {}
        }
    }

    private func save() {
        guard (1...31).contains(frequency), weight.isFinite, weight > 0 else { showsError = true; return }
        if onSave(HarvestRecord(frequencyPerMonth: frequency, latestWeightKg: weight)) {
            dismiss()
        } else { showsError = true }
    }
}
