import SwiftUI

struct NutrientReference: Identifiable {
    let symbol: String
    let name: String
    let role: String
    let fertilizers: [(name: String, content: String)]
    var id: String { symbol }

    static func reference(for symbol: String) -> NutrientReference? {
        all.first { $0.symbol == symbol }
    }

    static let all = [
        NutrientReference(symbol: "N", name: "Nitrogen", role: "Nitrogen membantu daun tetap hijau dan pelepah baru tumbuh.", fertilizers: [
            ("Urea", "Kandungan nitrogen ±46%."),
            ("ZA", "Kandungan nitrogen ±21%, juga mengandung belerang."),
            ("NPK 15-15-15", "Kandungan nitrogen ±15%, juga mengandung fosfor dan kalium.")
        ]),
        NutrientReference(symbol: "P", name: "Fosfor", role: "Fosfor membantu akar tumbuh kuat serta pembentukan bunga dan buah.", fertilizers: [
            ("TSP", "Kandungan fosfat ±46%."),
            ("SP-36", "Kandungan fosfat ±36%."),
            ("NPK 15-15-15", "Kandungan fosfat ±15%, juga mengandung nitrogen dan kalium.")
        ]),
        NutrientReference(symbol: "K", name: "Kalium", role: "Kalium membantu buah terisi penuh dan tanaman lebih tahan kekeringan.", fertilizers: [
            ("KCl", "Kandungan kalium ±60%."),
            ("NPK 15-15-15", "Kandungan kalium ±15%, juga mengandung nitrogen dan fosfor.")
        ]),
        NutrientReference(symbol: "Mg", name: "Magnesium", role: "Magnesium membantu daun tetap hijau dan mencegah daun tua menguning.", fertilizers: [
            ("Kieserit", "Kandungan magnesium ±27%, juga mengandung belerang."),
            ("Dolomit", "Kandungan magnesium ±18%, juga mengandung kalsium.")
        ])
    ]
}

struct NutrientReferenceView: View {
    let reference: NutrientReference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(reference.name) (\(reference.symbol))").font(.title2.bold())
                    Text(reference.role).font(.body)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Pupuk yang mengandung \(reference.name.lowercased())")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                    ForEach(reference.fertilizers.indices, id: \.self) { index in
                        let fertilizer = reference.fertilizers[index]
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fertilizer.name).font(.headline)
                            Text(fertilizer.content).font(.footnote).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        if index < reference.fertilizers.count - 1 { Divider() }
                    }
                }
                Text("Kadar \(reference.name.lowercased()) bisa berbeda per merek. Lihat keterangan pada karung pupuk.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 16)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Referensi Pupuk · Nitrogen") {
    Color.clear.sheet(isPresented: .constant(true)) {
        NutrientReferenceView(reference: NutrientReference.all[0])
    }
}

/// Text where every nutrient name is a link that opens its fertilizer reference.
struct NutrientLinkedText: View {
    let text: String
    let onSelect: (String) -> Void

    static let scheme = "kebun-hara"

    var body: some View {
        Text(Self.linked(text))
            .tint(.primary)
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == Self.scheme, let symbol = url.host() else { return .systemAction }
                onSelect(symbol)
                return .handled
            })
    }

    static func linked(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        for reference in NutrientReference.all {
            var searchStart = attributed.startIndex
            while let range = attributed[searchStart...].range(of: reference.name, options: .caseInsensitive) {
                attributed[range].link = URL(string: "\(scheme)://\(reference.symbol)")
                attributed[range].underlineStyle = .single
                attributed[range].inlinePresentationIntent = .stronglyEmphasized
                searchStart = range.upperBound
            }
        }
        return attributed
    }
}
