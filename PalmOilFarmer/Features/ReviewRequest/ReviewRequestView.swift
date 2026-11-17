import SwiftUI

struct ConsentCheckbox: View {
    @Binding var isChecked: Bool
    var showError = false
    let text: String

    var body: some View {
        Button { isChecked.toggle() } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? KropsTheme.accentHero : (showError ? KropsTheme.statusCritical : KropsTheme.labelSecondary))
                    .accessibilityHidden(true)
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(showError ? KropsTheme.statusCritical : KropsTheme.labelPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}

struct ReviewRequestView: View {
    @State private var flow: ReviewRequestFlow
    @State private var contactFlow: ReviewContactFlow

    init(flow: ReviewRequestFlow) {
        if flow.coordinator.currentContactID == nil {
            flow.viewModel.hasConsent = true
            flow.viewModel.continueToContact()
        }
        let contactID = flow.coordinator.currentContactID ?? UUID()
        _flow = State(initialValue: flow)
        _contactFlow = State(initialValue: flow.makeContactFlow(contactID))
    }

    var body: some View {
        ReviewContactFormView(flow: contactFlow)
    }
}

#if DEBUG
#Preview("Ajukan Peninjauan · Form Narahubung") {
    ReviewRequestView(onSubmit: { _ in })
        .environment(\.locale, Locale(identifier: "id_ID"))
}

#Preview("Ajukan Peninjauan · Anggaran Pupuk") {
    ReviewRequestView(
        gardenName: "Belakang Rumah",
        areaHectares: 1.7,
        savedContacts: [
            ReviewContactDetails(
                name: "Hendrawan Nugroho",
                phone: "0812 7745 3021",
                address: "Jl. Raya Gunung Kijang Km 25, Malang Rapat, Gunung Kijang, Bintan"
            )
        ],
        onSubmit: { _ in }
    )
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
