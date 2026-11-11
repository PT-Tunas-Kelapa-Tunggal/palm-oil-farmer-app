import SwiftUI

struct AssessmentOverviewView: View {
    let viewModel: AssessmentOverviewViewModel
    let onAddContact: () -> Void
    let onEditContact: (ReviewContactDetails) -> Void
    let onSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize = 34.0
    @ScaledMetric(relativeTo: .body) private var buttonHeight = 52.0
    @ScaledMetric(relativeTo: .subheadline) private var descriptionHeight = 40.0
    @ScaledMetric(relativeTo: .title3) private var checkSize = 22.0

    private var dark: Bool { colorScheme == .dark }
    private var palette: AssessmentPalette { .init(isDark: dark) }

    var body: some View {
        @Bindable var model = viewModel
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 28) {
                    contactSection
                    budgetSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 28)
                .disabled(model.isSubmitting || model.hasSubmitted)
            }
        }
        .foregroundStyle(palette.primary)
        .background(palette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actions
        }
        .alert("Pengajuan belum dikirim", isPresented: Binding(
            get: { model.submissionError != nil },
            set: { if !$0 { model.submissionError = nil } }
        )) {
            Button("Mengerti", role: .cancel) { model.submissionError = nil }
        } message: {
            Text(model.submissionError ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")

            Text("Ajukan Peninjauan")
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityAddTraits(.isHeader)

            Color.clear.frame(width: 44, height: 1)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
    }

    private var contactSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Narahubung", description: "Petugas menghubungi orang ini untuk menjadwalkan kunjungan.")
            if !viewModel.contacts.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.contacts.indices, id: \.self) { index in
                        contactRow(viewModel.contacts[index], index: index)
                    }
                }
                .padding(.horizontal, 16)
                .background(dark ? palette.card : AssessmentPalette.ink, in: RoundedRectangle(cornerRadius: 20))
            }

            Button(action: onAddContact) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .foregroundStyle(palette.accent)
                        .accessibilityHidden(true)
                    Text("Tambah narahubung lain")
                        .foregroundStyle(dark ? palette.primary : palette.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: buttonHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func contactRow(_ contact: ReviewContactDetails, index: Int) -> some View {
        let selected = viewModel.selectedContactIndex == index
        let contactSecondary = dark ? palette.secondary : .white.opacity(0.8)
        return HStack(alignment: .top, spacing: 8) {
            Button {
                viewModel.selectContact(at: index)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    checkmark(selected, onInverseCard: !dark)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name).font(.headline)
                        Text(contact.phone).font(.subheadline).foregroundStyle(contactSecondary)
                        Text(contact.address).font(.subheadline).foregroundStyle(contactSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(selected ? .isSelected : [])

            Button {
                onEditContact(contact)
            } label: {
                Image(systemName: "pencil")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 5)
            .accessibilityLabel("Ubah narahubung \(contact.name)")
        }
        .foregroundStyle(dark ? palette.primary : .white)
    }

    private var budgetSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Anggaran Pupuk", description: "Batas dana pupuk yang bisa Anda siapkan per hektar per tahun.")
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text(viewModel.budgetText)
                        .font(.system(size: amountSize, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("per hektar per tahun")
                        .font(.footnote)
                        .foregroundStyle(palette.secondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 4)

                budgetSlider

                HStack {
                    Text("Rp1 jt")
                    Spacer()
                    Text("Rp10 jt")
                }
                .font(.footnote)
                .foregroundStyle(palette.secondary)
                .accessibilityHidden(true)

                Rectangle()
                    .fill(dark ? Color.white.opacity(31 / 255) : Color(uiColor: .separator))
                    .frame(height: 0.1)
                    .accessibilityHidden(true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 0) {
                        totalLabel.fixedSize()
                        Spacer(minLength: 8)
                        totalValue.fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        totalLabel
                        totalValue
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 14)
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, 16)
            .background(palette.card, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var totalLabel: some View {
        Text("Total untuk kebun \(viewModel.areaText)")
    }

    private var totalValue: some View {
        Text(viewModel.totalText)
            .font(.headline)
            .contentTransition(.numericText())
    }

    private var budgetSlider: some View {
        GeometryReader { proxy in
            let inset = 16.0
            let width = max(1, proxy.size.width - inset * 2)
            let thumb = min(37, width)
            let travel = width - thumb
            let x = inset + thumb / 2 + travel * viewModel.budgetProgress

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(dark ? Color(red: 120 / 255, green: 120 / 255, blue: 128 / 255).opacity(92 / 255) : Color(white: 120 / 255).opacity(51 / 255))
                    .frame(width: width, height: 6)
                    .position(x: inset + width / 2, y: 20)
                Capsule()
                    .fill(AssessmentPalette.graphite)
                    .frame(width: x - inset, height: 6)
                    .position(x: inset + (x - inset) / 2, y: dark ? 26 : 20)
                ForEach(0..<5) { tick in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(dark ? Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255).opacity(41 / 255) : Color(red: 60 / 255, green: 60 / 255, blue: 67 / 255).opacity(46 / 255))
                        .frame(width: 4, height: 4)
                        .position(x: inset + thumb / 2 + travel * Double(tick) / 4, y: 29)
                }
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(dark ? 0 : 0.16), radius: 6, y: 3)
                    .frame(width: thumb, height: 24)
                    .position(x: x, y: 26)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                guard travel > 0 else { return }
                viewModel.setBudgetProgress((gesture.location.x - inset - thumb / 2) / travel)
            })
        }
        .frame(height: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Anggaran pupuk per hektar per tahun")
        .accessibilityValue(viewModel.budgetText)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: viewModel.adjustBudget(by: 1)
            case .decrement: viewModel.adjustBudget(by: -1)
            @unknown default: break
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.isConfirmed.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    checkmark(viewModel.isConfirmed)
                    Text("Saya memastikan data narahubung dan anggaran pupuk sudah benar.")
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(minHeight: 58, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(viewModel.isConfirmed ? .isSelected : [])
            .disabled(viewModel.isSubmitting || viewModel.hasSubmitted)

            Button {
                Task {
                    await viewModel.submit()
                    if viewModel.hasSubmitted { onSubmitted() }
                }
            } label: {
                Text(viewModel.isSubmitting ? "Mengirim…" : "Kirim Pengajuan")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: buttonHeight)
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.buttonLabel)
            .glassEffect(.regular.tint(palette.buttonTint), in: Capsule())
            .opacity(viewModel.canSubmit ? 1 : 0.45)
            .disabled(!viewModel.canSubmit)
        }
        .padding(.horizontal, 16)
        .background(palette.background)
    }

    private func sectionHeader(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: descriptionHeight, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func checkmark(_ selected: Bool, onInverseCard: Bool = false) -> some View {
        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: checkSize))
            .foregroundStyle(selected ? palette.accent : onInverseCard ? .white.opacity(0.8) : palette.secondary)
            .frame(minWidth: 26, minHeight: 28)
            .accessibilityHidden(true)
    }
}

/// Presents the assessment screens within the host navigation stack.
struct AssessmentRequestFlow: View {
    private enum Entry {
        case loading, contactForm, overview, loadFailed
    }

    @State private var entry: Entry = .loading
    @State private var overview: AssessmentOverviewViewModel
    @State private var showsOverview = false
    private enum ContactEditor: Identifiable {
        case add
        case edit(ReviewContactDetails)

        var id: Int {
            switch self {
            case .add: 0
            case .edit: 1
            }
        }

        var contact: ReviewContactDetails? {
            if case .edit(let contact) = self { return contact }
            return nil
        }
    }

    @State private var contactEditor: ContactEditor?
    @State private var showsConfirmation = false
    private let gardenName: String
    private let onSubmitted: () -> Void
    private let onClose: (() -> Void)?

    init(
        gardenID: UUID,
        gardenName: String,
        areaHectares: Double,
        contactRepository: any AssessmentContactRepository,
        submissionRepository: any AssessmentSubmissionRepository,
        onSubmitted: @escaping () -> Void = {},
        onClose: (() -> Void)? = nil
    ) {
        self.gardenName = gardenName
        self.onSubmitted = onSubmitted
        self.onClose = onClose
        _overview = State(initialValue: AssessmentOverviewViewModel(
            gardenID: gardenID,
            areaHectares: areaHectares,
            contactRepository: contactRepository,
            submissionRepository: submissionRepository
        ))
    }

    var body: some View {
        Group {
            switch entry {
            case .loading:
                ProgressView()
            case .contactForm:
                AssessmentContactEditor(overview: overview) { showsOverview = true }
                    .navigationDestination(isPresented: $showsOverview) {
                        overviewScreen
                    }
            case .overview:
                overviewScreen
            case .loadFailed:
                ContentUnavailableView {
                    Label("Narahubung belum dapat dimuat", systemImage: "exclamationmark.circle")
                } actions: {
                    Button("Coba lagi", action: loadContacts)
                }
            }
        }
        .task {
            if entry == .loading { loadContacts() }
        }
    }

    private var overviewScreen: some View {
        AssessmentOverviewView(
            viewModel: overview,
            onAddContact: { contactEditor = .add },
            onEditContact: { contactEditor = .edit($0) },
            onSubmitted: {
                onSubmitted()
                showsConfirmation = true
            }
        )
        .navigationDestination(isPresented: $showsConfirmation) {
            SubmissionSuccessView(
                viewModel: SubmissionSuccessViewModel(gardenName: gardenName, isPreview: true),
                onClose: onClose
            )
        }
        .sheet(item: $contactEditor) { editor in
            NavigationStack {
                AssessmentContactEditor(overview: overview, contact: editor.contact) { contactEditor = nil }
            }
        }
    }

    private func loadContacts() {
        do {
            try overview.loadContacts()
            entry = overview.contacts.isEmpty ? .contactForm : .overview
        } catch {
            entry = .loadFailed
        }
    }
}

private struct AssessmentContactEditor: View {
    let overview: AssessmentOverviewViewModel
    let onSaved: () -> Void
    private let contact: ReviewContactDetails?
    @State private var form: AssessmentFormViewModel
    @State private var saveError: String?

    init(overview: AssessmentOverviewViewModel, contact: ReviewContactDetails? = nil, onSaved: @escaping () -> Void) {
        self.overview = overview
        self.contact = contact
        self.onSaved = onSaved
        _form = State(initialValue: AssessmentFormViewModel(contact: contact))
    }

    var body: some View {
        AssessmentFormView(viewModel: form) { name, phone, address in
            do {
                if let contact {
                    try overview.updateContact(contact, name: name, phone: phone, address: address)
                } else {
                    try overview.saveContact(name: name, phone: phone, address: address)
                }
                onSaved()
            } catch {
                saveError = (error as? LocalizedError)?.errorDescription ?? "Coba simpan kembali."
            }
        }
        .alert("Narahubung belum disimpan", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }
}

#Preview("Assessment Contact and Overview") {
    NavigationStack {
        AssessmentRequestFlow(
            gardenID: UUID(),
            gardenName: "Kebun Contoh",
            areaHectares: 1.7,
            contactRepository: DeviceAssessmentContactRepository(
                fileURL: URL.temporaryDirectory.appending(path: UUID().uuidString)
            ),
            submissionRepository: PlaceholderAssessmentSubmissionRepository(
                directory: URL.temporaryDirectory.appending(path: UUID().uuidString)
            )
        )
    }
    .preferredColorScheme(.dark)
}
