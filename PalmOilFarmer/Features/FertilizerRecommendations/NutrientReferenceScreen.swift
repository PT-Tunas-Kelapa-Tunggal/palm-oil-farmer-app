import SwiftUI

struct NutrientReferenceScreen: View {
    let reference: NutrientReference?
    let projection: NutrientProjection
    let currentLabel: String
    let targetLabel: String
    var insight: String? = nil

    private var nutrientTitle: String {
        reference?.title ?? projection.name
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    private func kilograms(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...3)))) kg / pohon / tahun"
    }

    private func chartValue(_ ratio: Double, amountKg: Double?) -> String {
        if let amountKg {
            return kilograms(amountKg)
        }
        return percent(ratio)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(nutrientTitle).font(.title2.bold())
                if let reference {
                    Text(reference.explanation).font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(projection.currentAmountKg == nil ? "Nilai pada grafik" : "Pasokan hara per pohon")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    valueRow(currentLabel, value: projection.currentAvailable
                             ? chartValue(projection.current, amountKg: projection.currentAmountKg)
                             : "Belum tersedia")
                    valueRow(targetLabel, value: chartValue(projection.target, amountKg: projection.targetAmountKg))
                    if projection.currentAmountKg != nil, let status = projection.status {
                        valueRow("Status pasokan", value: status.components(separatedBy: " · ").last ?? status)
                    }
                }
                .padding(16)
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))

                if let insight, let formatted = try? AttributedString(markdown: insight) {
                    Text(formatted)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let reference {
                    Text("Pupuk yang mengandung " + reference.title.components(separatedBy: " (")[0].lowercased())
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(reference.fertilizers) { fertilizer in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fertilizer.name).font(.headline)
                            Text(fertilizer.detail).font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        if fertilizer.id != reference.fertilizers.last?.id { Divider() }
                    }
                    Text(reference.note).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func valueRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
